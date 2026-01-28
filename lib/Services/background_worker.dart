import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background worker to check inactivity and show reminder notifications
class BackgroundWorker {
  static bool _initialized = false;

  /// Task name used by WorkManager
  /// Initialize WorkManager only once
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize WorkManager with our callback dispatcher
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register periodic task (Android min is 15 minutes)
    await Workmanager().registerPeriodicTask(
      'check_inactivity_unique', // unique name
      taskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// Show inactivity notification
  static Future<void> _showNotification() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'Inactivity reminders to add your expenses',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await plugin.show(
      42,
      "Money reminder 💸",
      "You haven’t added your expenses in a while — track them now!",
      details,
      payload: "home", // Used in main.dart to navigate to home
    );
  }
}

/// Task name used by WorkManager
const String taskName = "check_inactivity_task";

/// This function is called in the background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      final prefs = await SharedPreferences.getInstance();
      final lastOpened = prefs.getInt('lastOpened') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 6 hours in milliseconds
      final sixHoursMs = const Duration(hours: 6).inMilliseconds;

      if (lastOpened != 0 && (now - lastOpened) > sixHoursMs) {
        await BackgroundWorker._showNotification();
      }
    }

    // Must return true when the task is completed
    return Future.value(true);
  });
}
