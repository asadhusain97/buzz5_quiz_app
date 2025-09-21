import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

class AppTextStyles {
  // Standard Material Design text styles
  static const TextStyle headlineLarge = TextStyle(fontSize: 42, fontWeight: FontWeight.bold);
  static const TextStyle headlineMedium = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static const TextStyle headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

  static const TextStyle titleLarge = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle titleMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle titleSmall = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  static const TextStyle bodyLarge = TextStyle(fontSize: 18, fontWeight: FontWeight.normal);
  static const TextStyle bodyMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const TextStyle bodySmall = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);

  static const TextStyle labelLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle labelMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle labelSmall = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  // Button text styles
  static const TextStyle buttonLarge = TextStyle(fontSize: 24);
  static const TextStyle buttonSmall = TextStyle(fontSize: 16);
  static const TextStyle buttonTextSmall = TextStyle(fontSize: 16);

  // Legacy style mappings for backward compatibility
  static const TextStyle titleBig = headlineSmall;
  static const TextStyle body = bodyMedium;
  static const TextStyle bodyBig = bodyLarge;
  static const TextStyle headingSmall = headlineMedium;

  // Game-specific text styles (migrated from GameThemeExtension)
  static const TextStyle scoreCard = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle roomCode = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
  );

  static TextStyle gameStatTitles = TextStyle(
    fontSize: 20,
    color: ColorConstants.primaryColor,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w700,
  );

  static TextStyle hintText = TextStyle(
    fontSize: 14,
    color: ColorConstants.hintGrey,
    fontWeight: FontWeight.w200,
    fontStyle: FontStyle.italic,
  );

  static TextStyle scoreSubtitle = TextStyle(
    fontSize: 12,
    color: ColorConstants.surfaceColor,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  // Semantic text styles for common patterns
  static const TextStyle profileHeading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle profileSubheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static TextStyle profileMeta = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ColorConstants.primaryColor,
  );

  static const TextStyle homeWelcome = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle homeSubtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle homeButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle homeFooter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle smallCaption = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle dangerText = TextStyle(
    color: ColorConstants.danger,
  );
}
