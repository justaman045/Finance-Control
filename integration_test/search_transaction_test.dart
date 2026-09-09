import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('E2E: Search Transaction Flow', (WidgetTester tester) async {
    // 1-3. App Launch + Splash/Onboarding + Login
    await launchAndSignIn(tester);

    // 3.5. Seed a known transaction so the search assertions are deterministic.
    await createReceiveTransaction(
      tester,
      name: 'Freelance Client',
      amount: '500',
      category: 'Salary',
    );

    // 4. Verify Home Screen & Tap Search Icon
    await pumpAndSettleSafe(tester);
    expect(find.text(AppStrings.totalBalance), findsOneWidget);

    final searchIcon = find.byIcon(Icons.search);
    await tester.tap(searchIcon);
    await pumpAndSettleSafe(tester);

    // 5. Verify Search Screen
    expect(find.text('Search Transactions'), findsOneWidget);
    expect(
      find.textContaining('Search by name, amount'),
      findsOneWidget,
    );

    final searchField = find.byType(TextField);

    // 6. Test Case A: Search by Name "Freelance"
    debugPrint("Testing Search by Name...");
    await tester.enterText(searchField, 'Freelance');
    await pumpAndSettleSafe(tester);

    expect(
      find.text('Freelance Client'),
      findsWidgets,
    );

    // Clear Search
    await tester.enterText(searchField, '');
    await pumpAndSettleSafe(tester);

    // 7. Test Case B: Search by Amount "500"
    debugPrint("Testing Search by Amount...");
    await tester.enterText(searchField, '500');
    await pumpAndSettleSafe(tester);

    expect(find.textContaining('500'), findsWidgets);

    // Clear Search
    await tester.enterText(searchField, '');
    await pumpAndSettleSafe(tester);

    // 8. Test Case C: Search by Category "Salary"
    debugPrint("Testing Search by Category...");
    await tester.enterText(searchField, 'Salary');
    await pumpAndSettleSafe(tester);

    expect(find.text('Salary'), findsWidgets);

    // 9. Open Details
    debugPrint("Navigating to Details...");
    await tester.tap(find.text('Freelance Client').first);
    await pumpAndSettleSafe(tester);

    // 10. Verify Transaction Result Screen
    expect(find.text('Transaction Details'), findsWidgets);
    expect(find.text('Money Received!'), findsOneWidget);
    expect(find.textContaining('500.00'), findsWidgets);
    expect(find.text('Freelance Client'), findsOneWidget);
  });
}
