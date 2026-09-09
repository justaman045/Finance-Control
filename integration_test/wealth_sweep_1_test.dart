import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Controllers/profile_controller.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Wealth sweep 1/3 — free-account, add-verify-delete round trips through the
  // generic AssetDetailScreen for the Liquid/Fixed-Income + Equity cards.
  testWidgetsWithScreenshots('Wealth sweep 1: PPF, Post Office, Bonds, Chit Fund, Stocks, SIP, ETFs', (
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
      cardTitle: 'PPF',
      addLabel: 'Add PPF Account',
      fieldValues: {'Bank / Post Office': uniqueName('SBI'), 'Current balance': '60000'},
      emptyMessage: 'No PPF accounts added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Post Office Schemes',
      addLabel: 'Add Scheme',
      fieldValues: {'Investment amount': '70000'},
      emptyMessage: 'No post office schemes added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Bonds (Govt/Corp)',
      addLabel: 'Add Bond',
      fieldValues: {'Bond name / issuer': uniqueName('GOI'), 'Face / investment value': '80000'},
      emptyMessage: 'No bonds added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Chit Fund',
      addLabel: 'Add Chit Fund',
      fieldValues: {'Organizer / company': uniqueName('Chit'), 'Total chit value': '90000'},
      emptyMessage: 'No chit funds added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Stocks',
      addLabel: 'Add Stock',
      fieldValues: {'Company name': uniqueName('TCS'), 'Current value': '50000'},
      emptyMessage: 'No stocks added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Mutual Funds (SIP)',
      addLabel: 'Add Fund',
      fieldValues: {'Fund name': uniqueName('Nifty50'), 'Current value': '60000'},
      emptyMessage: 'No mutual funds added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'ETFs',
      addLabel: 'Add ETF',
      fieldValues: {'ETF name': uniqueName('NiftyBEES'), 'Current value': '40000'},
      emptyMessage: 'No ETFs added',
    );

    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    await waitForHome(tester);
  });
}
