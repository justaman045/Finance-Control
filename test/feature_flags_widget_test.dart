import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Config/feature_flags.dart';
import 'package:money_control/Screens/Admin/feature_flags_screen.dart';
import 'package:money_control/Services/feature_flag_service.dart';
import 'package:money_control/Services/performance_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFeatureFlagService extends FeatureFlagService {
  _FakeFeatureFlagService({required this.isAdmin});
  final bool isAdmin;
  final Map<String, String> saved = {};

  @override
  void onInit() {
    super.onInit();
    adminOverride = isAdmin;
  }

  @override
  void startRealtime() {}

  @override
  Future<void> setStatus(String key, String status) async {
    saved[key] = status;
    applyRaw({...rawStatuses, key: status});
  }
}

Widget _app(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, __) => GetMaterialApp(home: child),
);

// The app's design ref is 390x844. flutter_screenutil reads the raw view (not
// MediaQuery), and the test view defaults to a 800x600 logical surface, which
// would scale every `.w/.h/.sp` to ~2x and overflow every row. Overriding the
// view to a 390x844 logical phone (@3x) makes scaling exactly 1:1.
Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(child));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    // GlassContainer reads PerformanceController inside its own Obx; mirror
    // the app's Phase-1 registration so it resolves.
    Get.put<PerformanceController>(PerformanceController());
  });

  group('FeatureFlagsScreen', () {
    testWidgets('non-admin sees access denied', (tester) async {
      Get.put<FeatureFlagService>(_FakeFeatureFlagService(isAdmin: false));
      await _pumpScreen(tester, const FeatureFlagsScreen());

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text(AppStrings.featureFlags), findsNothing);
    });

    testWidgets('admin sees every feature row with a status chip', (
      tester,
    ) async {
      Get.put<FeatureFlagService>(_FakeFeatureFlagService(isAdmin: true));
      await _pumpScreen(tester, const FeatureFlagsScreen());

      expect(find.text(AppStrings.featureFlags), findsWidgets);
      expect(find.text('Budgeting'), findsOneWidget);
      expect(find.text('Lent Money Tracker'), findsOneWidget);
      expect(find.text('AI Insights'), findsOneWidget);
      expect(
        find.text(AppStrings.statusEnabled),
        findsNWidgets(FeatureFlag.all.length),
      );
    });

    testWidgets('admin sees section headers for every group', (tester) async {
      Get.put<FeatureFlagService>(_FakeFeatureFlagService(isAdmin: true));
      await _pumpScreen(tester, const FeatureFlagsScreen());

      for (final group in FeatureFlag.groups) {
        expect(find.text(group.title.toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('changing a status saves and updates the chip', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      await _pumpScreen(tester, const FeatureFlagsScreen());

      await tester.ensureVisible(
        find.byKey(const ValueKey('flag-budget-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('flag-budget-toggle')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.statusComingSoon), findsWidgets);
      expect(find.text(AppStrings.statusHiddenHint), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('status-budget-hidden')));
      await tester.pumpAndSettle();

      expect(service.saved['budget'], FeatureStatus.hidden);
      expect(find.text(AppStrings.statusHidden), findsOneWidget);
    });

    testWidgets('critical features warn before leaving enabled', (
      tester,
    ) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      await _pumpScreen(tester, const FeatureFlagsScreen());

      // Cancel first — nothing should be saved.
      await tester.tap(find.byKey(const ValueKey('flag-transactions-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('status-transactions-comingSoon')),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.disableCriticalConfirm), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.saved.containsKey('transactions'), isFalse);

      // Retry and confirm — saved.
      await tester.tap(find.byKey(const ValueKey('flag-transactions-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('status-transactions-comingSoon')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.disableCriticalConfirm));
      await tester.pumpAndSettle();

      expect(service.saved['transactions'], FeatureStatus.comingSoon);
    });
  });
}
