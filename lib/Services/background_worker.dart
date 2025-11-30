import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String taskName = "check_inactivity";

final FlutterLocalNotificationsPlugin _notifications =
FlutterLocalNotificationsPlugin();

/// 🔥 THIS MUST BE TOP-LEVEL (NOT INSIDE ANY CLASS)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      final prefs = await SharedPreferences.getInstance();

      final lastOpened = prefs.getInt('lastOpened') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 6 hours = 6 * 60 * 60 * 1000
      // For testing:
      const sixHoursMs = 5 * 1000; // 5 seconds

      if (lastOpened != 0 && now - lastOpened > sixHoursMs) {
        await _showReminder();
      }
    }

    return Future.value(true);
  });
}

/// 🔔 Show notification
Future<void> _showReminder() async {
  const androidDetails = AndroidNotificationDetails(
    'reminder_channel',
    'App Reminders',
    importance: Importance.max,
    priority: Priority.high,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await _notifications.show(
    1,
    "Money Reminder 💸",
    "You haven’t added your expenses in a while — track them now!",
    notificationDetails,
  );
}

/// 🚀 Call this from main.dart during app start
class BackgroundWorker {
  static Future<void> init() async {
    // Notification initialization
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // WorkManager init
    await Workmanager().initialize(
      callbackDispatcher, // MUST MATCH the top-level function
      isInDebugMode: true, // set true for testing
    );

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      "inactivity_task_id",
      taskName,
      frequency: const Duration(minutes: 15), // minimum allowed
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }
}
