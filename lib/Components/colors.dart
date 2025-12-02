// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//
// ────────────────────────────────────────────────
//  COLOR PALETTE
// ────────────────────────────────────────────────
//

// ------------------ LIGHT THEME ------------------
const Color kLightGradientTop = Color(0xFFE9F0FF);     // Soft bluish white
const Color kLightGradientBottom = Color(0xFFF6EBFF);  // Soft lavender white

const Color kLightBackground = Color(0xFFF8FAFF); // Softer background
const Color kLightSurface = Colors.white;

const Color kLightPrimary = Color(0xFF2F80ED);
const Color kLightSecondary = Color(0xFF8A3FFC);

const Color kLightTextPrimary = Color(0xFF1A1A1A);
const Color kLightTextSecondary = Color(0xFF55596F);

const Color kLightBorder = Color(0xFFE3E6EC);
const Color kLightDivider = Color(0xFFD5D9E0);

const Color kLightError = Color(0xFFE53935);
const Color kLightSuccess = Color(0xFF0FA958);
const Color kLightWarning = Color(0xFFFFC107);

// ------------------ DARK THEME ------------------
const Color kDarkGradientTop = Color(0xFF1F263F);
const Color kDarkGradientBottom = Color(0xFF4A2A66);

const Color kDarkBackground = Color(0xFF121725);
const Color kDarkSurface = Color(0xFF1C2033);

const Color kDarkPrimary = Color(0xFF90AFFF);
const Color kDarkSecondary = Color(0xFFC6B2E8);

const Color kDarkTextPrimary = Colors.white;
const Color kDarkTextSecondary = Color(0xFFA8ADC5);

const Color kDarkBorder = Color(0xFF2D3248);
const Color kDarkDivider = Color(0xFF353A50);

const Color kDarkError = Color(0xFFFF7A7A);
const Color kDarkSuccess = Color(0xFF34D39F);
const Color kDarkWarning = Color(0xFFFFC76F);

//
// ────────────────────────────────────────────────
//  COMPLETE COLOR SCHEMES
// ────────────────────────────────────────────────
//

// ------------------ LIGHT SCHEME ------------------
final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: kLightPrimary,
  onPrimary: Colors.white,
  secondary: kLightSecondary,
  onSecondary: Colors.white,
  error: kLightError,
  onError: Colors.white,
  background: kLightBackground,
  onBackground: kLightTextPrimary,
  surface: kLightSurface,
  onSurface: kLightTextPrimary,
);

// ------------------ DARK SCHEME ------------------
final ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: kDarkPrimary,
  onPrimary: Colors.black,
  secondary: kDarkSecondary,
  onSecondary: Colors.black,
  error: kDarkError,
  onError: Colors.white,
  background: kDarkBackground,
  onBackground: kDarkTextPrimary,
  surface: kDarkSurface,
  onSurface: kDarkTextPrimary,
);

//
// ────────────────────────────────────────────────
//  LIGHT THEME
// ────────────────────────────────────────────────
//

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: kLightBackground,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: kLightTextPrimary,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: kLightTextPrimary),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLightPrimary,
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    // Text
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: kLightTextSecondary, fontSize: 14.sp),
      bodyLarge: TextStyle(color: kLightTextPrimary, fontSize: 16.sp),
      titleLarge: TextStyle(
        color: kLightTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20.sp,
      ),
    ),

    // Inputs
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

    dividerColor: kLightDivider,

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kLightPrimary,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

//
// ────────────────────────────────────────────────
//  DARK THEME
// ────────────────────────────────────────────────
//

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: kDarkBackground,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: kDarkTextPrimary,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: kDarkTextPrimary),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDarkPrimary,
        foregroundColor: Colors.black,
        textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    // Text
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: kDarkTextSecondary, fontSize: 14.sp),
      bodyLarge: TextStyle(color: kDarkTextPrimary, fontSize: 16.sp),
      titleLarge: TextStyle(
        color: kDarkTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20.sp,
      ),
    ),

    // Inputs
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

    snackBarTheme: SnackBarThemeData(
      backgroundColor: kDarkPrimary,
      contentTextStyle: TextStyle(color: Colors.black, fontSize: 14.sp),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
