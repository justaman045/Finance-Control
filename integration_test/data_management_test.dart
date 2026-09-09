import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Config/app_strings.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Data & Support: Backup Data + Restore Data (both local-cache/Firestore
  // round trips). CSV/GDPR exports are skipped: FilePicker.saveFile opens the
  // Android system file picker, which integration tests cannot drive.
  testWidgetsWithScreenshots('Data management: backup and restore', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);
    await tapNavTab(tester, Icons.tune_rounded, 'Settings');
    await tapUntilMarker(tester, find.text('Data & Support'), find.text('Backup Data'));

    // ── 1. Backup ───────────────────────────────────────────────────────────
    await tapWhenVisible(tester, find.text('Backup Data'));
    await waitFor(tester, find.text('Data backed up securely'));
    expect(find.text('Data backed up securely'), findsWidgets);
    await pumpReal(tester, const Duration(seconds: 2)); // let the snackbar go

    // ── 2. Restore ──────────────────────────────────────────────────────────
    await tapWhenVisible(tester, find.text('Restore Data'));
    await waitFor(tester, find.text('Restore Data')); // confirm dialog title
    await tapWhenVisible(tester, find.widgetWithText(TextButton, 'Restore'));
    await waitFor(tester, find.text('Data restored from backup'));
    expect(find.text('Data restored from backup'), findsWidgets);
    await pumpReal(tester, const Duration(seconds: 2));

    // ── 3. Back to settings and home ────────────────────────────────────────
    await popScreen(tester); // Data & Support → Settings
    await waitFor(tester, find.text('General'));
    await tapNavTab(tester, Icons.grid_view_rounded, AppStrings.totalBalance);
    await waitForHome(tester);
  });
}
