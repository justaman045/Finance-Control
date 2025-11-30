import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/splashscreen.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/firebase_options.dart';
import 'package:money_control/Services/background_worker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings =
  const Settings(persistenceEnabled: true);

  // Background worker + local notifications
  await BackgroundWorker.init();

  await FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

  runApp(const MoneyControlApp());
}

class MoneyControlApp extends StatelessWidget {
  const MoneyControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Money Control',
        themeMode: ThemeMode.system,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        home: const AuthChecker(),
        // Handle notification click
        // builder: (context, child) {
        //   FlutterLocalNotificationsPlugin().initialize(
        //     const InitializationSettings(
        //       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        //     ),
        //     onDidReceiveNotificationResponse: (response) {
        //       if (response.payload == "home") {
        //         navigatorKey.currentState?.push(
        //           MaterialPageRoute(builder: (_) => const BankingHomeScreen()),
        //         );
        //       }
        //     },
        //   );
        //   return child!;
        // },
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.emailVerified) {
            return const BankingHomeScreen();
          } else {
            FirebaseAuth.instance.signOut();
            return const AnimatedSplashScreen();
          }
        }
        return const AnimatedSplashScreen();
      },
    );
  }
}
// LIGHT THEME CONFIGURATION
ThemeData _buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: kLightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kLightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLightPrimary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: kLightTextSecondary, fontSize: 14.sp),
      bodyLarge: TextStyle(color: kLightTextPrimary, fontSize: 16.sp),
      titleLarge: TextStyle(
        color: kLightTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18.sp,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLightSurface,
      hintStyle: const TextStyle(color: kLightTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kLightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kLightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kLightPrimary, width: 2),
      ),
    ),
    dividerColor: kLightBorder,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kLightPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}

// DARK THEME CONFIGURATION
ThemeData _buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: kDarkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDarkPrimary,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkSurface,
      hintStyle: const TextStyle(color: kDarkTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDarkDivider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDarkDivider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDarkPrimary, width: 2),
      ),
    ),
    dividerColor: kDarkDivider,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kDarkPrimary,
      contentTextStyle: TextStyle(color: Colors.black),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}
