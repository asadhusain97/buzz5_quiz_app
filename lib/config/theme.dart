import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_dimensions.dart';

/// Centralized theme configuration for the application.
///
/// This class provides the consolidated dark theme configuration
/// that was previously embedded in main.dart. It uses our
/// standardized color constants, text styles, and dimensions.
class AppTheme {
  AppTheme._(); // Prevent instantiation

  /// Builds the dark theme configuration
  static ThemeData buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
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
        onTertiaryContainer: ColorConstants.correctAnsBtn,
        error: ColorConstants.errorColor,
        surface: ColorConstants.darkSurface,
      ),
      scaffoldBackgroundColor: ColorConstants.darkScaffoldBackground,
      cardColor: ColorConstants.darkCard,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorConstants.primaryContainerColor,
        elevation: AppDimensions.appBarElevation,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
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
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          padding: AppDimensions.buttonPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.primaryColor,
        ),
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
    );
  }
}
