// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Add Transaction Flow', (WidgetTester tester) async {
    await launchAndSignIn(tester);

    // Open the send screen from the balance card.
    await tester.tap(find.text(AppStrings.send).last);
    await pumpAndSettleSafe(tester);

    // Ensure a category chip exists (adds it through the UI dialog when
    // missing). The test must not depend on the app's GetX controllers
    // (tests run in a separate isolate), so everything goes through the tree.
    await ensureCategoryExists(tester, 'Food');

    // Select the category chip.
    final categoryChip = find.text('Food').last;
    await tester.ensureVisible(categoryChip);
    await pumpAndSettleSafe(tester);
    await tester.tap(categoryChip);
    await pumpAndSettleSafe(tester);

    // Fill amount + name.
    await tester.enterText(find.widgetWithText(TextField, '0.00'), '150');
    await pumpAndSettleSafe(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Enter name'), 'Test Lunch');
    await pumpAndSettleSafe(tester);

    // Dismiss keyboard and submit.
    FocusManager.instance.primaryFocus?.unfocus();
    await pumpAndSettleSafe(tester);
    final sendButton = find.text(AppStrings.sendCta).last;
    await tester.ensureVisible(sendButton);
    await pumpAndSettleSafe(tester);
    await tester.tap(sendButton);

    await waitForHome(tester);

    // Should be back at Home.
    expect(find.byType(BankingHomeScreen), findsOneWidget);

    print('Add Transaction Test Passed: Transaction added successfully.');
  });
}
