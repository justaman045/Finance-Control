import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ----- LIGHT THEME -----
const Color kLightGradientTop = Color(0xFF8EB2FF);     // blue gradient top
const Color kLightGradientBottom = Color(0xFFDC81FF);  // purple gradient bottom
const Color kLightBackground = Color(0xFFF6F8FD);      // major bg (scaffold)
const Color kLightSurface = Colors.white;              // cards, nav, sheets
const Color kLightPrimary = Color(0xFF2F80ED);         // accent blue
const Color kLightSecondary = Color(0xFF8A3FFC);       // accent purple
const Color kLightTextPrimary = Colors.black;          // title/headline text
const Color kLightTextSecondary = Color(0xFF55596F);   // body/subtext
const Color kLightBorder = Color(0xFFEBEBEB);          // borders, dividers
const Color kLightError = Color(0xFFE53935);           // error, destructive
const Color kLightSuccess = Color(0xFF0FA958);         // received/positive
const Color kLightWarning = Color(0xFFFFC107);         // warning, optional

// ----- DARK THEME -----
const Color kDarkGradientTop = Color(0xFF232D53);         // dark blue gradient top
const Color kDarkGradientBottom = Color(0xFF59377C);      // dark purple gradient bottom
const Color kDarkBackground = Color(0xFF1B2339);          // scaffold bg
const Color kDarkSurface = Color(0xFF23253C);             // cards, nav, sheets
const Color kDarkPrimary = Color(0xFF90AFFF);             // accent blue (lighter for dark)
const Color kDarkSecondary = Color(0xFFB39DDB);           // accent purple (lighter)
const Color kDarkTextPrimary = Colors.white;              // title/headline text
const Color kDarkTextSecondary = Color(0xFFA8ADC5);       // subtext, descriptions
const Color kDarkBorder = Color(0xFF31304F);              // borders, dividers
const Color kDarkError = Color(0xFFFF8686);               // error, destructive
const Color kDarkSuccess = Color(0xFF3AD29F);             // received/positive
const Color kDarkWarning = Color(0xFFFFC76F);             // warning, optional
const Color kDarkDivider = Color(0xFF31304F); // dark divider line/border

// ----- ColorScheme for ThemeData -----
const ColorScheme lightColorScheme = ColorScheme(
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

const ColorScheme darkColorScheme = ColorScheme(
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

// LIGHT THEME CONFIGURATION
ThemeData buildLightTheme() {
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
ThemeData buildDarkTheme() {
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
