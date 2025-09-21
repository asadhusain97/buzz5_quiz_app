/// UI-related constants used throughout the application.
///
/// This file centralizes common UI values like spacing, dimensions,
/// durations, and other design tokens to ensure consistency.
class UIConstants {
  // Prevent instantiation
  UIConstants._();

  /// Standard spacing values following 8dp grid system
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  /// Border radius values
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 90.0;

  /// Shadow and elevation values
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Component sizes
  static const double buttonMinWidth = 200.0;
  static const double buttonMinHeight = 60.0;
  static const double avatarSize = 32.0;
  static const double questionButtonSize = 90.0;
  static const double leaderboardWidth = 250.0;
  static const double leaderboardItemWidth = 180.0;
  static const double questionSetWidth = 150.0;
  static const double questionSetHeaderHeight = 80.0;

  /// Text truncation
  static const int maxTextLength = 500;
  static const int maxTitleLines = 3;

  /// Connection indicator
  static const double connectionIndicatorSize = 8.0;

  /// Question board dimensions
  static const double questionBoardWidth = 950.0;
  static const double questionBoardHeight = 900.0;

  /// Room code styling
  static const double roomCodeFontSize = 24.0;
  static const double roomCodeLetterSpacing = 2.0;
}