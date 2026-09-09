import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Controllers/profile_controller.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Loans / Liabilities is free (no Pro gate on LoanTrackerScreen). Full
  // round trip: add a loan (creates its linked recurring EMI payment), verify
  // the card + amortization schedule, then remove it.
  testWidgetsWithScreenshots('Loan tracker: add, amortization, remove', (
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

    final loanName = uniqueName('Loan');
    await scrollUntilVisible(tester, find.text('Loans / Liabilities'));
    await tapUntilMarker(tester, find.text('Loans / Liabilities'), find.text('Loan Tracker'));

    // ── 1. Add a loan through the sheet ─────────────────────────────────────
    await tapWhenVisible(tester, find.text('Add Loan'));
    await waitFor(tester, find.text('Loan Name'));
    await tester.enterText(find.widgetWithText(TextField, 'Loan Name'), loanName);
    await pumpReal(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Principal (₹)'), '200000');
    await pumpReal(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Rate (% p.a.)'), '8.5');
    await pumpReal(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Tenure (months)'), '60');
    await pumpReal(tester);

    FocusManager.instance.primaryFocus?.unfocus();
    await pumpAndSettleSafe(tester);
    await tapWhenVisible(tester, find.widgetWithText(ElevatedButton, 'Add Loan'));
    await pumpReal(tester, const Duration(seconds: 3));

    // ── 2. Verify the loan card ─────────────────────────────────────────────
    await waitFor(tester, find.text(loanName));
    expect(find.text(loanName), findsWidgets);
    expect(find.textContaining('/mo'), findsWidgets);
    expect(find.textContaining('mo paid'), findsWidgets);
    expect(find.textContaining('Outstanding:'), findsWidgets);

    // ── 3. Amortization schedule sheet ──────────────────────────────────────
    await tester.tap(find.text(loanName), warnIfMissed: false);
    await waitFor(tester, find.textContaining('Schedule'));
    expect(find.textContaining('Total interest:'), findsWidgets);
    await dismissDialogs(tester); // closes the schedule sheet
    await pumpReal(tester);

    // ── 4. Remove the loan (also deletes its recurring payment) ─────────────
    await scrollUntilVisible(tester, find.text('Remove'));
    await tapWhenVisible(tester, find.text('Remove'));
    await waitFor(tester, find.text('Remove Loan'));
    await tapWhenVisible(tester, find.widgetWithText(TextButton, 'Remove'));
    await waitForGone(tester, find.text(loanName));
    await waitFor(tester, find.text('No loans tracked yet'));
    expect(find.text('No loans tracked yet'), findsWidgets);

    await popScreen(tester); // back to the Wealth tab
    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    await waitForHome(tester);
  });
}
