import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Controllers/profile_controller.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Wealth sweep 3/3 — Jewelry, Crypto, REITs, P2P, Agricultural Land,
  // Business Capital, BNPL (generic detail screens).
  testWidgetsWithScreenshots('Wealth sweep 3: Jewelry, Crypto, REITs, P2P, Agri Land, Business, BNPL', (
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
      cardTitle: 'Jewelry / Diamonds',
      addLabel: 'Add Item',
      fieldValues: {'Description (e.g. Gold necklace)': uniqueName('Necklace'), 'Estimated value': '60000'},
      emptyMessage: 'No jewelry items added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Crypto',
      addLabel: 'Add Crypto',
      fieldValues: {'Coin name (e.g. Bitcoin)': uniqueName('BTC'), 'Current value': '70000'},
      emptyMessage: 'No crypto holdings added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'REITs',
      addLabel: 'Add REIT',
      fieldValues: {'Current value': '80000'},
      emptyMessage: 'No REITs added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'P2P Lending',
      addLabel: 'Add P2P Lending',
      fieldValues: {'Amount lent': '90000'},
      emptyMessage: 'No P2P lending entries added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Agricultural Land',
      addLabel: 'Add Land',
      fieldValues: {'Location / village': uniqueName('Village'), 'Current market value': '100000'},
      emptyMessage: 'No agricultural land added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'Business Capital',
      addLabel: 'Add Business',
      fieldValues: {'Business name': uniqueName('Biz'), 'Capital invested': '200000'},
      emptyMessage: 'No business assets added',
    );

    await sweepAssetEntry(
      tester,
      cardTitle: 'BNPL / Pay Later',
      addLabel: 'Add BNPL Entry',
      fieldValues: {'Outstanding amount': '30000'},
      emptyMessage: 'No BNPL entries added',
    );

    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    await waitForHome(tester);
  });
}
