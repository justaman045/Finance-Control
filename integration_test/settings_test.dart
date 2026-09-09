import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Settings sections and Sign Out', (WidgetTester tester) async {
    await launchAndSignIn(tester);
    final isPro = await probePro(tester);

    await tapNavTab(tester, Icons.tune_rounded, 'Settings');

    // ── 1. Menu sections ────────────────────────────────────────────────────
    // SingleChildScrollView builds everything, so off-screen cards are found.
    if (isPro) {
      expect(find.text('Managing Subscription'), findsWidgets);
    } else {
      expect(find.text(AppStrings.upgradeToPro), findsWidgets);
    }
    expect(find.text('General'), findsWidgets);
    expect(find.text('Security & Privacy'), findsWidgets);
    expect(find.text('Data & Support'), findsWidgets);
    expect(find.text('Automation'), findsWidgets);
    expect(find.text('Future Money Tracker'), findsWidgets);
    expect(find.text('Invite Friends'), findsWidgets);
    expect(find.text(AppStrings.signOut), findsWidgets);

    // ── 2. Security & Privacy ───────────────────────────────────────────────
    await tapUntilMarker(tester, find.text('Security & Privacy'), find.text('Biometric App Lock'));
    expect(find.text('Privacy Mode (Blur)'), findsWidgets);
    expect(find.text('Change Password'), findsWidgets);
    expect(find.text('Delete Account'), findsWidgets);
    await popScreen(tester);
    await waitFor(tester, find.text('General'));

    // ── 3. Data & Support ───────────────────────────────────────────────────
    await tapUntilMarker(tester, find.text('Data & Support'), find.text('Backup Data'));
    expect(find.text('Restore Data'), findsWidgets);
    expect(find.text('Export Transactions (CSV)'), findsWidgets);
    expect(find.text('About App'), findsWidgets);
    await popScreen(tester);
    await waitFor(tester, find.text('General'));

    // ── 4. Sign Out (LAST — leaves the account) ─────────────────────────────
    await scrollUntilVisible(tester, find.text(AppStrings.signOut));
    await tapWhenVisible(tester, find.text(AppStrings.signOut));
    // Logout lands back on the splash walkthrough; tap through to the login
    // screen to confirm the session ended.
    await handleSplashAndOnboarding(tester);
    await waitFor(tester, find.text(AppStrings.signIn), seconds: 60);
    expect(find.text(AppStrings.signIn), findsWidgets);
    expect(find.text(AppStrings.totalBalance), findsNothing);
    // Let the splash→login transition finish so the test binding has no
    // pending frames when the test ends.
    await pumpAndSettleSafe(tester, timeout: const Duration(seconds: 5));
  });
}
