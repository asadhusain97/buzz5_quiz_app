import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

/// The [AppTheme] defines light and dark themes for the app.
abstract final class AppTheme {
  // The defined light theme.
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: ColorConstants.primaryColor,
      onPrimary: ColorConstants.lightTextColor,
      primaryContainer: ColorConstants.primaryContainerColor,
      onPrimaryContainer: ColorConstants.lightTextColor,
      secondary: ColorConstants.secondaryColor,
      onSecondary: ColorConstants.darkTextColor,
      secondaryContainer: ColorConstants.secondaryContainerColor,
      onSecondaryContainer: ColorConstants.lightTextColor,
      tertiary: ColorConstants.tertiaryColor,
      onTertiary: ColorConstants.darkTextColor,
      tertiaryContainer: ColorConstants.tertiaryContainerColor,
      onTertiaryContainer: ColorConstants.lightTextColor,
      error: ColorConstants.errorColor,
      errorContainer: ColorConstants.errorContainerColor,
      background: ColorConstants.backgroundColor,
      surface: ColorConstants.surfaceColor,
    ),
    scaffoldBackgroundColor: ColorConstants.backgroundColor,
    cardColor: ColorConstants.cardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: ColorConstants.primaryContainerColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: ColorConstants.lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: ColorConstants.lightTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: ColorConstants.lightTextColor,
        elevation: 2,
        minimumSize: Size(200, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ColorConstants.primaryColor),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primaryColor.withOpacity(0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The defined dark theme.
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: ColorConstants.primaryColor,
      onPrimary: ColorConstants.lightTextColor,
      primaryContainer: ColorConstants.primaryContainerColor,
      onPrimaryContainer: ColorConstants.lightTextColor,
      secondary: ColorConstants.secondaryColor,
      onSecondary: ColorConstants.darkTextColor,
      secondaryContainer: ColorConstants.secondaryContainerColor,
      onSecondaryContainer: ColorConstants.lightTextColor,
      tertiary: ColorConstants.tertiaryColor,
      onTertiary: ColorConstants.darkTextColor,
      tertiaryContainer: ColorConstants.tertiaryContainerColor,
      onTertiaryContainer: ColorConstants.lightTextColor,
      error: ColorConstants.errorColor,
      background: hexToColor('#121212'),
      surface: hexToColor('#1E1E1E'),
    ),
    scaffoldBackgroundColor: hexToColor('#121212'),
    cardColor: hexToColor('#252525'),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorConstants.primaryContainerColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: ColorConstants.lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: ColorConstants.lightTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: ColorConstants.lightTextColor,
        elevation: 2,
        minimumSize: Size(200, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ColorConstants.primaryColor),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ColorConstants.primaryColor.withOpacity(0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
