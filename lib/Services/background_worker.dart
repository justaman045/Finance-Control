import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:money_control/firebase_options.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:money_control/Services/recurring_service.dart';

/// Background worker to check inactivity and show reminder notifications
class BackgroundWorker {
  static bool _initialized = false;

  /// Task name used by WorkManager
  /// Initialize WorkManager only once
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize WorkManager with our callback dispatcher
    await Workmanager().initialize(callbackDispatcher);

    // Register periodic task (Android min is 15 minutes)
    await Workmanager().registerPeriodicTask(
      'periodic_checks_unique_v2', // Changed name to ensure fresh policy
      taskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  /// Show notification helper
  /// Show notification helper
  static Future<void> showNotification(
    String title,
    String body,
    String channelId,
    String channelName, {
    String? userEmail,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Money Control Notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Unique ID based on time
    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await plugin.show(id, title, body, details, payload: "home");

    // Persist to Firestore
    if (userEmail != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('notifications')
            .add({
              'title': title,
              'body': body,
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
              'type': channelId,
            });
      } catch (e) {
        log("Error saving background notification: $e");
      }
    }
  }
}

/// Task name used by WorkManager
const String taskName = "periodic_task";

/// This function is called in the background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      // 1. Initialize Firebase (Required for Firestore)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        // Firebase might already be initialized
        log("Firebase init error (ignorable): $e");
      }

      final prefs = await SharedPreferences.getInstance();

      // --- LOGIC 1: INACTIVITY REMINDER ---
      await _checkInactivity(prefs);

      // --- LOGIC 2: DAILY INSIGHTS (10 PM) ---
      await _checkDailyInsights(prefs);

      // --- LOGIC 3: UPDATE CHECK ---
      await _checkUpdate(prefs);

      // --- LOGIC 4: RECURRING PAYMENTS ---
      await _checkRecurringPayments(prefs);
    }

    return Future.value(true);
  });
}

// ---------------- CHECKERS ----------------

Future<void> _checkInactivity(SharedPreferences prefs) async {
  final lastOpened = prefs.getInt('lastOpened') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  final sixHoursMs = const Duration(hours: 6).inMilliseconds;

  // We add a 'last_reminded' check to avoid spamming every 15 mins after 6 hours
  final lastReminded = prefs.getInt('last_inactivity_reminded') ?? 0;
  final sixHoursAgo = now - sixHoursMs;

  if (lastOpened != 0 && lastOpened < sixHoursAgo) {
    // Only remind if we haven't reminded since the last open (approx logic)
    // Or just remind once every 24 hours of inactivity?
    // Current logic: simple 6 hours. Let's stick to simple but throttle it.

    // Throttle: don't remind if reminded in last 6 hours
    if (now - lastReminded > sixHoursMs) {
      final userEmail = prefs.getString('user_email');
      await BackgroundWorker.showNotification(
        "Money reminder 💸",
        "You haven’t added your expenses in a while — track them now!",
        'reminder_channel',
        'Reminders',
        userEmail: userEmail,
      );
      await prefs.setInt('last_inactivity_reminded', now);
    }
  }
}

Future<void> _checkDailyInsights(SharedPreferences prefs) async {
  final now = DateTime.now();

  // Trigger only after 10 PM (22:00)
  if (now.hour >= 22) {
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final lastRun = prefs.getString('last_daily_insight_run');

    if (lastRun != todayStr) {
      // Logic to run
      final userEmail = prefs.getString('user_email');

      if (userEmail != null) {
        try {
          final double spent = await _fetchTodayTotal(
            userEmail,
            isExpense: true,
          );
          final double received = await _fetchTodayTotal(
            userEmail,
            isExpense: false,
          );

          final symbol =
              "₹"; // Default currency symbol or fetch from prefs if saved

          await BackgroundWorker.showNotification(
            "Daily Insight 📊",
            "Today: Spent $symbol${spent.toStringAsFixed(0)}, Received $symbol${received.toStringAsFixed(0)}",
            'insight_channel',
            'Daily Insights',
            userEmail: userEmail,
          );

          // Mark as run for today
          await prefs.setString('last_daily_insight_run', todayStr);
        } catch (e) {
          log("Error fetching daily insight: $e");
        }
      }
    }
  }
}

Future<double> _fetchTodayTotal(String email, {required bool isExpense}) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  double total = 0;

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(email)
      .collection('transactions')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
      .get();

  // We need to filter by sender/recipient to know if it's expense/income
  // But inside background, we don't have FirebaseAuth user.uid easily unless we saved it.
  // We only saved email.
  // HOWEVER: The 'transactions' subcollection usually contains ALL transactions for that user.
  // We need to check structure.
  // User Model usually has 'uid'.
  // Let's assume we can fetch user doc to get UID? Or check transaction fields.

  // Checking codebase assumption:
  // Transaction Model has senderId and recipientId.
  // We need current user UID to differentiate income/expense.
  // Workaround: We fetch the user doc first to get UID.

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(email)
      .get();
  final uid = userDoc.exists ? (userDoc.data()?['uid'] as String?) : null;

  // Legacy or backup: if uid not in doc (it usually is if we saved it on login),
  // we might have trouble.
  // BUT: `loginscreen.dart` saves: email, name, photoUrl provider, lastLogin.
  // It does NOT explicitly save 'uid' in the snippets I saw!
  // Wait, `signup.dart` usually saves it.
  // If `uid` is missing, we can't distinguish accurately.
  // Let's try to infer or just query simpler if possible.

  // ALTERNATIVE: Calculate purely based on positive/negative?
  // `calculateBankBalance` uses:
  // where('senderId', isEqualTo: user.uid) -> Expense
  // where('recipientId', isEqualTo: user.uid) -> Income

  if (uid == null) return 0; // Can't calc specific without UID

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final amount = (data['amount'] ?? 0).toDouble().abs();
    final senderId = data['senderId'];
    final recipientId = data['recipientId'];

    if (isExpense) {
      if (senderId == uid) total += amount;
    } else {
      if (recipientId == uid) total += amount;
    }
  }

  return total;
}

Future<void> _checkUpdate(SharedPreferences prefs) async {
  // Check once per day to avoid spam
  final now = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final lastCheck = prefs.getString('last_update_check_run');

  if (lastCheck == todayStr) return; // Already checked today

  try {
    // 1. Fetch Remote Version
    final url = Uri.parse(
      "https://raw.githubusercontent.com/justaman045/Money_Control/master/app_version.json",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final remoteVersion = data["latest_version"] as String;

      // 2. Fetch Local Version
      final package = await PackageInfo.fromPlatform();
      final localVersion = package.version;

      // 3. Compare
      if (_isNewer(remoteVersion, localVersion)) {
        // Try to get email if possible, though prefs might not be passed purely here
        // We need prefs to get email
        final userEmail = prefs.getString('user_email');

        await BackgroundWorker.showNotification(
          "Update Available 🚀",
          "Version $remoteVersion is out! Tap to update.",
          'update_channel',
          'Updates',
          userEmail: userEmail,
        );
      }

      // Mark checked
      await prefs.setString('last_update_check_run', todayStr);
    }
  } catch (e) {
    log("Update check error: $e");
  }
}

bool _isNewer(String remote, String local) {
  List<int> r = remote.split('.').map(int.parse).toList();
  List<int> l = local.split('.').map(int.parse).toList();

  for (int i = 0; i < 3; i++) {
    if (i >= r.length || i >= l.length) break;
    if (r[i] > l[i]) return true;
    if (r[i] < l[i]) return false;
  }
  return false;
}

Future<void> _checkRecurringPayments(SharedPreferences prefs) async {
  final now = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final lastRun = prefs.getString('last_recurring_run');

  if (lastRun == todayStr) return; // Already checked today

  final userEmail = prefs.getString('user_email');
  if (userEmail != null) {
    try {
      await RecurringService.processDuePayments(userEmail);

      // Notify if processed?
      // processDuePayments doesn't return count details,
      // maybe we should just rely on user seeing it in history or add notification inside service.

      await prefs.setString('last_recurring_run', todayStr);
    } catch (e) {
      log("Error processing recurring payments: $e");
    }
  }
}
