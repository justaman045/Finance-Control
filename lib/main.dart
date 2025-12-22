// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'package:money_control/Components/methods.dart';
import 'package:money_control/Services/update_checker.dart.dart';
import 'package:money_control/firebase_options.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/splashscreen.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Services/background_worker.dart';
import 'package:money_control/Services/local_backup_service.dart';

// -------------------------------------------------------
// GLOBALS
// -------------------------------------------------------

final navigatorKey = GlobalKey<NavigatorState>();

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver analyticsObserver =
FirebaseAnalyticsObserver(analytics: analytics);

// THEME CONTROLLER
class ThemeController extends GetxController {
  RxBool isDark = false.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  void setTheme(bool dark) {
    isDark.value = dark;

    // Log theme change event
    analytics.logEvent(
      name: "theme_changed",
      parameters: {"is_dark": dark.toString()},
    );
  }
}

final ThemeController themeController = Get.put(ThemeController());

// -------------------------------------------------------
// MAIN
// -------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings =
  const Settings(persistenceEnabled: true);

  await _loadThemeFromFirebase();

  await BackgroundWorker.init();

  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  FirebaseFirestore.instance.enableNetwork().then((_) {
    syncPendingTransactions();
  });

  analytics.logAppOpen();
  analytics.logEvent(name: "app_started");

  runApp(const RootApp());
}

// -------------------------------------------------------
// LOAD THEME FROM FIREBASE
// -------------------------------------------------------
Future<void> _loadThemeFromFirebase() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .get();

    final isDark = doc.data()?["darkMode"] ?? false;
    themeController.setTheme(isDark);
  } catch (_) {}
}

// -------------------------------------------------------
// ROOT APP
// -------------------------------------------------------
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: "Finance Control",

          themeMode: themeController.themeMode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),

          home: const AuthChecker(),

          navigatorObservers: [analyticsObserver],

          builder: (context, child) {
            FlutterLocalNotificationsPlugin().initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings("@mipmap/ic_launcher"),
              ),
              onDidReceiveNotificationResponse: (response) {
                analytics.logEvent(
                  name: "notification_clicked",
                  parameters: {"payload": ?response.payload},
                );

                if (response.payload == "home") {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (_) => const BankingHomeScreen(),
                    ),
                  );
                }
              },
            );

            return child!;
          },
        );
      },
    );
  }
}

// -------------------------------------------------------
// AUTH CHECKER
// -------------------------------------------------------
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _didInitialBackup = false;

  @override
  void initState() {
    super.initState();

    UpdateChecker.checkForUpdate(context);

    analytics.logEvent(name: "auth_checker_opened");

    // Safe check to avoid null error
    if (FirebaseAuth.instance.currentUser != null) {
      analytics.setUserId(id: FirebaseAuth.instance.currentUser!.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          if (user.emailVerified) {
            if (!_didInitialBackup && user.email != null) {
              _didInitialBackup = true;
              LocalBackupService.backupUserTransactions(user.email!);

              analytics.logEvent(
                name: "backup_completed",
                parameters: {"email": ?user.email},
              );
            }

            analytics.setUserId(id: user.email);
            analytics.setUserProperty(
                name: "user_email", value: user.email);

            analytics.logLogin(
              loginMethod: "email_password",
            );

            analytics.logEvent(
              name: "login_success",
              parameters: {"email": ?user.email},
            );

            return const BankingHomeScreen();
          }

          FirebaseAuth.instance.signOut();
        }

        analytics.logEvent(name: "redirect_to_splash");

        return const AnimatedSplashScreen();
      },
    );
  }
}
