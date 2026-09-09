import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/nav_item.dart';
import 'package:money_control/Config/tab_destinations.dart';
import 'package:money_control/Services/performance_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => GetMaterialApp(home: Scaffold(body: child)),
  ));
  await tester.pumpAndSettle();
}

List<TabDestination> _tabs(int count) {
  const labels = ['Home', 'Stats', 'Money', 'Wealth', 'Settings'];
  return List.generate(
    count,
    (i) => TabDestination(
      name: 'tab$i',
      featureKey: 't$i',
      label: labels[i % labels.length],
      icon: Icons.circle,
    ),
  );
}

/// Asserts the nav row distributes [count] items with EQUAL gaps at the left
/// edge, between items, and at the right edge (MainAxisAlignment.spaceEvenly).
Future<void> _expectEvenGaps(WidgetTester tester, int count) async {
  expect(find.byType(NavItem), findsNWidgets(count));
  final row = find.byType(Row).first;
  final rowRect = tester.getRect(row);
  final items = <Rect>[];
  for (var i = 0; i < count; i++) {
    items.add(tester.getRect(find.byType(NavItem).at(i)));
  }
  final gaps = <double>[
    items.first.left - rowRect.left,
    for (var i = 0; i < count - 1; i++) items[i + 1].left - items[i].right,
    rowRect.right - items.last.right,
  ];
  for (final gap in gaps) {
    expect(gap, closeTo(gaps.first, 1.0),
        reason: 'gaps must be even (got $gaps)');
  }
}

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    Get.put<PerformanceController>(PerformanceController());
  });

  testWidgets('5 visible tabs spread evenly with no overflow', (tester) async {
    await _pump(tester, const SizedBox.shrink());
    await _pump(
      tester,
      BottomNavBar(currentTab: 'tab0', destinations: _tabs(5)),
    );
    expect(tester.takeException(), isNull);
    await _expectEvenGaps(tester, 5);
  });

  testWidgets('hidden tabs redistribute the remainder evenly', (tester) async {
    await _pump(tester, const SizedBox.shrink());
    // 2 remaining tabs after 3 were hidden: they must be evenly spread, not
    // clinging to the edges with a single wide gap in the middle.
    await _pump(
      tester,
      BottomNavBar(currentTab: 'home', destinations: _tabs(2)),
    );
    expect(tester.takeException(), isNull);
    await _expectEvenGaps(tester, 2);
  });
}