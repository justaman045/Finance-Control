import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:money_control/Services/update_checker.dart.dart';

import 'package:money_control/firebase_options.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/splashscreen.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Services/background_worker.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// ---- THEME CONTROLLER ----
class ThemeController extends GetxController {
  RxBool isDark = false.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  void setTheme(bool dark) {
    isDark.value = dark;
  }
}

final ThemeController themeController = Get.put(ThemeController());

// ---- MAIN ----
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

  runApp(const RootApp());
}

// Load theme BEFORE app builds
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

// ---- ROOT APP ----
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
          title: "Money Control",

          // Only this part reacts 🔥
          themeMode: themeController.themeMode,

          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),

          home: const AuthChecker(),

          builder: (context, child) {
            FlutterLocalNotificationsPlugin().initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings("@mipmap/ic_launcher"),
              ),
              onDidReceiveNotificationResponse: (response) {
                if (response.payload == "home") {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                        builder: (_) => const BankingHomeScreen()),
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

// ---- AUTH CHECK ----
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    UpdateChecker.checkForUpdate(context);
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

        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.emailVerified) {
            return const BankingHomeScreen();
          }
          FirebaseAuth.instance.signOut();
        }

        return const AnimatedSplashScreen();
      },
    );
  }
}