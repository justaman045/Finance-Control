import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Subscription screen (adaptive Pro/free)', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester, account: TestAccount.pro);
    final isPro = await probePro(tester);

    await tapNavTab(tester, Icons.tune_rounded, 'Settings');

    if (isPro) {
      // Genuinely-subscribed Pro account (configured in the Firebase console):
      // the management view shows the plan and renewals — NOT the paywall or
      // the trial banner (trial is opt-in now, so a subscribed Pro account is
      // isTrial=false).
      await tapUntilMarker(
        tester,
        find.text('Managing Subscription'),
        find.text(AppStrings.youAreAProMember),
      );
      expect(find.text('Current Plan'), findsWidgets);
      expect(find.textContaining(AppStrings.renewsOn), findsWidgets);

      // NEVER tap "Cancel Plan" — it would end the shared Pro account's
      // subscription and break every other Pro-gated test. Close and continue.
      await tapUntilMarker(tester, find.byIcon(Icons.close), find.text('General'));
    } else {
      await tapUntilMarker(
        tester,
        find.text(AppStrings.upgradeToPro),
        find.text(AppStrings.monthly),
      );
      expect(find.text(AppStrings.yearly), findsWidgets);
      await tapUntilMarker(tester, find.byIcon(Icons.close), find.text('General'));
    }

    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    expect(find.text(AppStrings.totalBalance), findsWidgets);
  });
}
