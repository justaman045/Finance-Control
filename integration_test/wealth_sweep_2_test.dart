import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Controllers/profile_controller.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Wealth sweep 2/3 — Foreign Stocks, Startup, PF, VPF, NPS, Gold, SGB.
  testWidgetsWithScreenshots('Wealth sweep 2: Foreign Stocks, Startup, PF, VPF, NPS, Gold, SGB', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);
    await tapNavTab(tester, Icons.monetization_on_outlined, 'Wealth Builder');

    final pc = Get.find<ProfileController>();
    if (find.textContaining('personalises every target').evaluate().isNotEmpty) {
      await pc.refreshFromFirestore();
      await pumpAndSettleSafe(tester);
    }
    for (var i = 0; i < 30; i++) {
      await pumpReal(tester);
      if (find.text('FD / RD').evaluate().isNotEmpty) break;
    }

    await sweepAssetEntry(
      tester,
      cardTitle: 'Foreign Stocks',
      addLabel: 'Add Foreign Stock',
      fieldValues: {'Company name': uniqueName('AAPL'), 'Current value (local currency equivalent)': '70000'},
      emptyMessage: 'No foreign stocks added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Angel / Startup',
      addLabel: 'Add Investment',
      fieldValues: {'Startup / company': uniqueName('Startup'), 'Investment amount': '80000'},
      emptyMessage: 'No startup investments added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'PF / EPF',
      addLabel: 'Add PF Account',
      fieldValues: {'Employer / organisation': uniqueName('Employer'), 'Current balance': '100000'},
      emptyMessage: 'No PF accounts added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Voluntary PF',
      addLabel: 'Add VPF',
      fieldValues: {'Employer': uniqueName('VPFEmp'), 'Current balance': '20000'},
      emptyMessage: 'No VPF accounts added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'NPS',
      addLabel: 'Add NPS Account',
      fieldValues: {'Current value': '30000'},
      emptyMessage: 'No NPS accounts added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Gold / Silver',
      addLabel: 'Add Holding',
      fieldValues: {'Current market value': '40000'},
      emptyMessage: 'No gold or silver holdings added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Sovereign Gold Bonds',
      addLabel: 'Add SGB',
      fieldValues: {'Series (e.g. SGB 2019-20 III)': uniqueName('SGB'), 'Current value': '50000'},
      emptyMessage: 'No SGBs added',
    );

    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    await waitForHome(tester);
  });
}
