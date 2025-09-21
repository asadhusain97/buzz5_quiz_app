import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/app_dimensions.dart';
import 'package:buzz5_quiz_app/config/app_theme_extensions.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// This theme system provides:
/// - Material Design 3 color schemes
/// - Centralized typography using custom text styles
/// - Consistent component theming
/// - Support for both light and dark modes
abstract final class AppTheme {

  /// Base text theme configuration that works with both light and dark themes
  static const TextTheme _textTheme = TextTheme(
    // Headlines
    headlineLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

    // Titles
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

    // Body text
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),

    // Labels
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  );

  // The defined light theme.
  static ThemeData light = ThemeData(
    useMaterial3: true,
    textTheme: _textTheme,
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
      surface: ColorConstants.surfaceColor,
    ),
    scaffoldBackgroundColor: ColorConstants.backgroundColor,
    cardColor: ColorConstants.cardColor,
    appBarTheme: AppBarTheme(
      backgroundColor: ColorConstants.primaryContainerColor,
      elevation: AppDimensions.appBarElevation,
      centerTitle: true,
      titleTextStyle: _textTheme.titleLarge?.copyWith(
        color: ColorConstants.lightTextColor,
      ),
      iconTheme: IconThemeData(
        color: ColorConstants.lightTextColor,
        size: AppDimensions.mediumIconSize,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: ColorConstants.lightTextColor,
        elevation: AppDimensions.buttonElevation,
        minimumSize: AppDimensions.defaultButtonSize,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.buttonBorderRadius),
        padding: AppDimensions.buttonPadding,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ColorConstants.primaryColor),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorConstants.primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorConstants.primaryColor.withValues(alpha: 0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    extensions: const <ThemeExtension<dynamic>>[
      GameThemeExtension.light,
    ],
  );

  // The defined dark theme.
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    textTheme: _textTheme,
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
      surface: hexToColor('#1E1E1E'),
    ),
    scaffoldBackgroundColor: hexToColor('#121212'),
    cardColor: hexToColor('#252525'),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorConstants.primaryContainerColor,
      elevation: AppDimensions.appBarElevation,
      centerTitle: true,
      titleTextStyle: _textTheme.titleLarge?.copyWith(
        color: ColorConstants.lightTextColor,
      ),
      iconTheme: IconThemeData(
        color: ColorConstants.lightTextColor,
        size: AppDimensions.mediumIconSize,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: ColorConstants.lightTextColor,
        elevation: AppDimensions.buttonElevation,
        minimumSize: AppDimensions.defaultButtonSize,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.buttonBorderRadius),
        padding: AppDimensions.buttonPadding,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ColorConstants.primaryColor),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorConstants.primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorConstants.primaryColor.withValues(alpha: 0.5);
        }
        return Colors.grey.shade300;
      }),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    extensions: const <ThemeExtension<dynamic>>[
      GameThemeExtension.dark,
    ],
  );
}
