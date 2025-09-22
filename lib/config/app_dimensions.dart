import 'package:flutter/material.dart';

/// Centralized dimensions following Material Design 3 spacing guidelines.
///
/// All spacing follows the 8dp grid system for consistency and visual rhythm.
/// These dimensions ensure consistent spacing across all screens and components.
class AppDimensions {
  // Prevent instantiation
  AppDimensions._();

  /// Base unit for spacing calculations (8dp grid system)
  static const double baseUnit = 8.0;

  /// Standard padding and margin values
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets extraSmallPadding = EdgeInsets.all(4.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets mediumPadding = EdgeInsets.all(24.0);
  static const EdgeInsets largePadding = EdgeInsets.all(32.0);
  static const EdgeInsets extraLargePadding = EdgeInsets.all(48.0);

  /// Horizontal padding variants
  static const EdgeInsets smallHorizontalPadding = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets defaultHorizontalPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets mediumHorizontalPadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets largeHorizontalPadding = EdgeInsets.symmetric(horizontal: 32.0);

  /// Vertical padding variants
  static const EdgeInsets smallVerticalPadding = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets defaultVerticalPadding = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets mediumVerticalPadding = EdgeInsets.symmetric(vertical: 24.0);
  static const EdgeInsets largeVerticalPadding = EdgeInsets.symmetric(vertical: 32.0);

  /// Page-level padding
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(horizontal: 16.0);

  /// Card and container padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets containerPadding = EdgeInsets.all(12.0);

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
  static const EdgeInsets smallButtonPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

  /// App bar padding
  static const EdgeInsets appBarPadding = EdgeInsets.only(right: 8.0);

  /// Dialog and modal padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);
  static const EdgeInsets modalPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);

  /// Icon and image padding
  static const EdgeInsets iconPadding = EdgeInsets.all(8.0);
  static const EdgeInsets imagePadding = EdgeInsets.all(2.0);

  /// Specific component padding
  static const EdgeInsets leaderboardItemPadding = EdgeInsets.all(8.0);
  static const EdgeInsets questionSetPadding = EdgeInsets.all(2.0);

  /// Spacing values (for SizedBox, gaps, etc.)
  static const double extraSmallSpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double defaultSpacing = 16.0;
  static const double mediumSpacing = 24.0;
  static const double largeSpacing = 32.0;
  static const double extraLargeSpacing = 48.0;

  /// Component-specific spacing
  static const double buttonSpacing = 16.0;
  static const double cardSpacing = 12.0;
  static const double sectionSpacing = 24.0;
  static const double pageSpacing = 32.0;

  /// Border radius values
  static const double smallRadius = 4.0;
  static const double defaultRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  static const double circularRadius = 90.0;

  /// Border radius for specific components
  static const BorderRadius smallBorderRadius = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius defaultBorderRadius = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius mediumBorderRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius largeBorderRadius = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius modalBorderRadius = BorderRadius.all(Radius.circular(25.0));

  /// Icon sizes
  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 24.0;
  static const double mediumIconSize = 32.0;
  static const double largeIconSize = 48.0;
  static const double extraLargeIconSize = 64.0;

  /// Avatar and profile image sizes
  static const double avatarSize = 32.0;
  static const double largeAvatarSize = 64.0;
  static const double profileImageSize = 80.0;

  /// Question board specific dimensions
  static const double questionBoardWidth = 950.0;
  static const double questionBoardHeight = 900.0;
  static const double questionSetWidth = 150.0;
  static const double questionSetHeaderHeight = 80.0;
  static const double questionButtonSize = 90.0;

  /// Leaderboard dimensions
  static const double leaderboardWidth = 250.0;
  static const double leaderboardItemWidth = 180.0;
  static const double connectionIndicatorSize = 8.0;

  /// Button dimensions
  static const Size defaultButtonSize = Size(200.0, 56.0);
  static const Size smallButtonSize = Size(120.0, 40.0);
  static const Size largeButtonSize = Size(280.0, 64.0);
  static const Size endGameButtonSize = Size(200.0, 60.0);

  /// Dropdown dimensions
  static const double dropdownWidth = 200.0;

  /// Elevation values
  static const double cardElevation = 2.0;
  static const double buttonElevation = 2.0;
  static const double modalElevation = 8.0;
  static const double appBarElevation = 0.0;

  /// Animation durations (in milliseconds)
  static const int fastAnimation = 150;
  static const int defaultAnimation = 300;
  static const int slowAnimation = 500;

  /// Opacity values
  static const double disabledOpacity = 0.38;
  static const double hoverOpacity = 0.08;
  static const double focusOpacity = 0.12;
  static const double pressedOpacity = 0.12;
  static const double shadowOpacity = 0.1;
  static const double backdropOpacity = 0.3;

  /// Shadow properties
  static const double shadowBlur = 5.0;
  static const double shadowSpread = 1.0;

  /// Container constraints
  static const BoxConstraints avatarConstraints = BoxConstraints(
    maxWidth: 32.0,
    maxHeight: 32.0,
  );

  static const BoxConstraints buttonConstraints = BoxConstraints(
    minWidth: 200.0,
    minHeight: 56.0,
  );

  /// Text constraints for truncation
  static const BoxConstraints textConstraints = BoxConstraints(maxWidth: 130.0);

  // Migrated from UIConstants
  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Text truncation
  static const int maxTextLength = 500;
  static const int maxTitleLines = 3;
}