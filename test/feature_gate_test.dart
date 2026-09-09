import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/coming_soon_widget.dart';
import 'package:money_control/Components/feature_gate.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Config/feature_flags.dart';
import 'package:money_control/Services/feature_flag_service.dart';
import 'package:money_control/Services/performance_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFeatureFlagService extends FeatureFlagService {
  _FakeFeatureFlagService({required this.isAdmin});
  final bool isAdmin;

  @override
  void onInit() {
    super.onInit();
    adminOverride = isAdmin;
  }

  @override
  void startRealtime() {}
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => GetMaterialApp(home: child),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    Get.put<PerformanceController>(PerformanceController());
  });

  group('ComingSoonScreen', () {
    testWidgets('renders feature title and copy', (tester) async {
      Get.put<FeatureFlagService>(_FakeFeatureFlagService(isAdmin: false));
      await _pump(
        tester,
        ComingSoonScreen.forFlag('budget'),
      );
      expect(find.text('Budgeting'), findsOneWidget);
      expect(find.text(AppStrings.comingSoonTitle), findsWidgets);
      expect(find.text(AppStrings.comingSoonBody), findsOneWidget);
    });
  });

  group('FeatureGate', () {
    const content = Center(child: Text('real content'));
    const gate = FeatureGate(flagKey: 'budget', child: content);

    testWidgets('enabled feature shows real content', (tester) async {
      Get.put<FeatureFlagService>(_FakeFeatureFlagService(isAdmin: false));
      await _pump(tester, gate);
      expect(find.text('real content'), findsOneWidget);
      expect(find.text(AppStrings.comingSoonBody), findsNothing);
    });

    testWidgets('coming soon hides for customers', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'budget': FeatureStatus.comingSoon});
      await _pump(tester, gate);
      expect(find.text('real content'), findsNothing);
      expect(find.text('Budgeting'), findsOneWidget);
      expect(find.text(AppStrings.comingSoonBody), findsOneWidget);
    });

    testWidgets('coming soon is visible to admins', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'budget': FeatureStatus.comingSoon});
      await _pump(tester, gate);
      expect(find.text('real content'), findsOneWidget);
      expect(find.text(AppStrings.comingSoonBody), findsNothing);
    });

    testWidgets('hidden is gone for admins too', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'budget': FeatureStatus.hidden});
      await _pump(tester, gate);
      expect(find.text('real content'), findsNothing);
      expect(find.text(AppStrings.comingSoonBody), findsOneWidget);
    });

    testWidgets('flips reactively when admin changes status', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      await _pump(tester, gate);
      expect(find.text('real content'), findsOneWidget);

      service.applyRaw({'budget': FeatureStatus.comingSoon});
      await tester.pump();
      expect(find.text('real content'), findsNothing);
      expect(find.text(AppStrings.comingSoonBody), findsOneWidget);

      service.applyRaw({'budget': FeatureStatus.enabled});
      await tester.pump();
      expect(find.text('real content'), findsOneWidget);
    });
  });

  group('FeatureVisible', () {
    const content = Center(child: Text('surface widget'));
    const visible = FeatureVisible(flagKey: 'transaction_search', child: content);

    testWidgets('enabled surface is shown', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      await _pump(tester, visible);
      expect(find.text('surface widget'), findsOneWidget);
    });

    testWidgets('coming soon keeps the surface for customers', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'transaction_search': FeatureStatus.comingSoon});
      await _pump(tester, visible);
      expect(find.text('surface widget'), findsOneWidget);
    });

    testWidgets('hidden removes the surface for everyone including admins',
        (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'transaction_search': FeatureStatus.hidden});
      await _pump(tester, visible);
      expect(find.text('surface widget'), findsNothing);
    });

    testWidgets('flips reactively when admin hides the feature', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      await _pump(tester, visible);
      expect(find.text('surface widget'), findsOneWidget);

      service.applyRaw({'transaction_search': FeatureStatus.hidden});
      await tester.pump();
      expect(find.text('surface widget'), findsNothing);

      service.applyRaw({'transaction_search': FeatureStatus.enabled});
      await tester.pump();
      expect(find.text('surface widget'), findsOneWidget);
    });
  });

  group('FeatureSection', () {
    const content = Center(child: Text('section widget'));
    const section = FeatureSection(
      flagKeys: ['sms_auto_import', 'expense_reminder'],
      child: content,
    );

    testWidgets('all enabled keeps the section', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'sms_auto_import': FeatureStatus.enabled});
      await _pump(tester, section);
      expect(find.text('section widget'), findsOneWidget);
    });

    testWidgets('coming soon keeps the section for customers', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({
        'sms_auto_import': FeatureStatus.comingSoon,
        'expense_reminder': FeatureStatus.comingSoon,
      });
      await _pump(tester, section);
      expect(find.text('section widget'), findsOneWidget);
    });

    testWidgets('one visible flag keeps the section', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({
        'sms_auto_import': FeatureStatus.hidden,
        'expense_reminder': FeatureStatus.enabled,
      });
      await _pump(tester, section);
      expect(find.text('section widget'), findsOneWidget);
    });

    testWidgets('all hidden removes the whole section', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({
        'sms_auto_import': FeatureStatus.hidden,
        'expense_reminder': FeatureStatus.hidden,
      });
      await _pump(tester, section);
      expect(find.text('section widget'), findsNothing);
    });

    testWidgets('flips reactively when an admin hides the last flag',
        (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      await _pump(tester, section);
      expect(find.text('section widget'), findsOneWidget);

      service.applyRaw({
        'sms_auto_import': FeatureStatus.hidden,
        'expense_reminder': FeatureStatus.hidden,
      });
      await tester.pump();
      expect(find.text('section widget'), findsNothing);

      service.applyRaw({'expense_reminder': FeatureStatus.enabled});
      await tester.pump();
      expect(find.text('section widget'), findsOneWidget);
    });
  });

  Widget sliverHost(Widget sliver) {
    return CustomScrollView(
      slivers: [sliver],
    );
  }

  group('SliverFeatureVisible', () {
    const content = SliverToBoxAdapter(child: Center(child: Text('sliver surface')));
    const hidden = SliverFeatureVisible(flagKey: 'smart_suggestions', sliver: content);

    testWidgets('enabled sliver is shown in a CustomScrollView', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      await _pump(tester, sliverHost(hidden));
      expect(find.text('sliver surface'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coming soon keeps the sliver for customers', (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'smart_suggestions': FeatureStatus.comingSoon});
      await _pump(tester, sliverHost(hidden));
      expect(find.text('sliver surface'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hidden removes the sliver for everyone including admins',
        (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: true);
      Get.put<FeatureFlagService>(service);
      service.applyRaw({'smart_suggestions': FeatureStatus.hidden});
      await _pump(tester, sliverHost(hidden));
      expect(find.text('sliver surface'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('flips reactively when an admin hides the feature',
        (tester) async {
      final service = _FakeFeatureFlagService(isAdmin: false);
      Get.put<FeatureFlagService>(service);
      await _pump(tester, sliverHost(hidden));
      expect(find.text('sliver surface'), findsOneWidget);

      service.applyRaw({'smart_suggestions': FeatureStatus.hidden});
      await tester.pump();
      expect(find.text('sliver surface'), findsNothing);

      service.applyRaw({'smart_suggestions': FeatureStatus.enabled});
      await tester.pump();
      expect(find.text('sliver surface'), findsOneWidget);
    });
  });

  group('ensureFeatureUsable', () {
    Future<bool> probe(
      WidgetTester tester, {
      bool admin = false,
      Map<String, String>? raw,
    }) async {
      final service = _FakeFeatureFlagService(isAdmin: admin);
      Get.put<FeatureFlagService>(service);
      if (raw != null) service.applyRaw(raw);
      var usable = false;
      await _pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () {
                usable = ensureFeatureUsable(context, 'profile');
              },
              child: const Text('probe'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('probe'));
      await tester.pumpAndSettle();
      return usable;
    }

    testWidgets('enabled returns true without pushing a placeholder',
        (tester) async {
      expect(await probe(tester), isTrue);
      expect(find.text(AppStrings.comingSoonBody), findsNothing);
    });

    testWidgets('comingSoon is false for customers and pushes placeholder',
        (tester) async {
      expect(
        await probe(tester, raw: {'profile': FeatureStatus.comingSoon}),
        isFalse,
      );
      expect(find.text(AppStrings.comingSoonBody), findsOneWidget);
    });

    testWidgets('comingSoon is true for admins', (tester) async {
      expect(
        await probe(tester, admin: true, raw: {'profile': FeatureStatus.comingSoon}),
        isTrue,
      );
      expect(find.text(AppStrings.comingSoonBody), findsNothing);
    });

    testWidgets('hidden is a hard no-op: false and no placeholder',
        (tester) async {
      expect(
        await probe(tester, raw: {'profile': FeatureStatus.hidden}),
        isFalse,
      );
      expect(find.text(AppStrings.comingSoonBody), findsNothing);
    });
  });
}