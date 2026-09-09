import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Controllers/profile_controller.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Wealth Assets: FD/RD add+delete, Real Estate, Credit Cards', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);

    // Wealth tab (bottom nav, no back button on the tab itself).
    await tapNavTab(tester, Icons.monetization_on_outlined, 'Wealth Builder');

    // The profile's async Firestore fetch can briefly lag login, leaving the
    // age gate visible. Refresh it so the wealth screen can resolve userAge.
    final pc = Get.find<ProfileController>();
    if (find.textContaining('personalises every target').evaluate().isNotEmpty) {
      await pc.refreshFromFirestore();
      await pumpAndSettleSafe(tester);
    }
    for (var i = 0; i < 30; i++) {
      await pumpReal(tester);
      if (find.text('FD / RD').evaluate().isNotEmpty) break;
    }

    // ── 1. FD / RD (generic AssetDetailScreen) ──────────────────────────────
    await tapUntilMarker(tester, find.text('FD / RD'), find.text('Add FD / RD'));

    final fdBank = uniqueName('HDFC');
    await tapWhenVisible(tester, find.text('Add FD / RD'));
    await createAssetEntry(
      tester,
      sheetTitle: 'Add FD / RD',
      fieldValues: {'Bank / NBFC': fdBank, 'Principal amount': '50000'},
    );

    // Entry card shows the bank name as its title + summary count.
    await waitFor(tester, find.text(fdBank));
    expect(find.text('1 item'), findsWidgets);

    // Delete it and confirm the dialog.
    await deleteCurrentEntry(tester);
    await waitFor(tester, find.text('No FDs or RDs added yet'));
    await popScreen(tester);

    // ── 2. Real Estate (custom detail screen) ───────────────────────────────
    await tapUntilMarker(tester, find.text('Real Estate'), find.text('Add Property'));

    final propName = uniqueName('Flat');
    await tapWhenVisible(tester, find.text('Add Property'));
    await createAssetEntry(
      tester,
      sheetTitle: 'Add Property',
      fieldValues: {
        'Property name / description': propName,
        'Current market value': '100000',
      },
    );

    await waitFor(tester, find.text(propName));
    expect(find.text('1 Property'), findsWidgets);

    await deleteCurrentEntry(tester);
    await waitFor(tester, find.text('No properties added'));
    await popScreen(tester);

    // ── 3. Credit Cards (liability) ─────────────────────────────────────────
    await tapUntilMarker(tester, find.text('Credit Card Outstanding'), find.text('Add Card'));

    final cardName = uniqueName('HDFC Card');
    await tapWhenVisible(tester, find.text('Add Card'));
    await createAssetEntry(
      tester,
      sheetTitle: 'Add Credit Card',
      fieldValues: {
        'Card / Bank name': cardName,
        'Outstanding balance': '25000',
      },
    );

    await waitFor(tester, find.text(cardName));
    await deleteCurrentEntry(tester);
    await waitFor(tester, find.text('No credit cards added'));
    await popScreen(tester);

    // Return to the home tab to finish the test.
    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    await waitForHome(tester);
  });
}
