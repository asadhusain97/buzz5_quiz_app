import 'package:flutter/material.dart';

/// Utility class for consistent navigation patterns throughout the application.
///
/// This class provides standardized navigation methods with smooth transitions
/// and consistent behavior across different parts of the app.
class NavigationUtils {
  // Prevent instantiation
  NavigationUtils._();

  /// Standard animation duration for page transitions
  static const Duration standardTransitionDuration = Duration(milliseconds: 300);

  /// Creates a smooth slide transition from bottom to top.
  ///
  /// This is commonly used for modal-style navigation where new content
  /// slides up from the bottom of the screen.
  ///
  /// Example:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   NavigationUtils.createSlideUpRoute(MyPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> createSlideUpRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration ?? standardTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Creates a smooth fade transition between pages.
  ///
  /// This provides a gentle transition effect suitable for related content.
  ///
  /// Example:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   NavigationUtils.createFadeRoute(NextPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> createFadeRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration ?? standardTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Creates a scale transition that grows from the center.
  ///
  /// This creates a "zoom in" effect suitable for highlighting important content.
  ///
  /// Example:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   NavigationUtils.createScaleRoute(ImportantPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> createScaleRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration ?? standardTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        final tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Navigates to a page with question-specific arguments and slide-up animation.
  ///
  /// This is specifically designed for navigating to question pages with
  /// consistent animation and data passing.
  ///
  /// Parameters:
  /// - [context]: Build context for navigation
  /// - [page]: The destination page widget
  /// - [questionData]: Map containing question information
  ///
  /// Example:
  /// ```dart
  /// NavigationUtils.navigateToQuestion(
  ///   context,
  ///   QuestionPage(),
  ///   {
  ///     'qid': '123',
  ///     'question': 'What is Flutter?',
  ///     'answer': 'A UI framework',
  ///     'score': 10,
  ///     // ... other question data
  ///   },
  /// );
  /// ```
  static Future<T?> navigateToQuestion<T extends Object?>(
    BuildContext context,
    Widget page,
    Map<String, dynamic> questionData,
  ) {
    return Navigator.push<T>(
      context,
      createSlideUpRoute<T>(
        page,
        settings: RouteSettings(arguments: questionData),
      ),
    );
  }

  /// Safely navigates back if possible, otherwise replaces with home route.
  ///
  /// This prevents navigation stack issues by ensuring there's always a
  /// valid route to return to.
  ///
  /// Parameters:
  /// - [context]: Build context for navigation
  /// - [homeRoute]: Route name to navigate to if no back route exists
  ///
  /// Example:
  /// ```dart
  /// NavigationUtils.safeNavigateBack(context, '/home');
  /// ```
  static void safeNavigateBack(BuildContext context, [String? homeRoute]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (homeRoute != null) {
      Navigator.pushReplacementNamed(context, homeRoute);
    }
  }

  /// Navigates to a route and clears the entire navigation stack.
  ///
  /// This is useful for authentication flows or major state changes
  /// where you want to prevent users from navigating back.
  ///
  /// Example:
  /// ```dart
  /// NavigationUtils.navigateAndClearStack(context, '/login');
  /// ```
  static Future<T?> navigateAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Shows a modal bottom sheet with consistent styling.
  ///
  /// Provides a standardized way to display bottom sheets with
  /// proper theming and animation.
  ///
  /// Example:
  /// ```dart
  /// NavigationUtils.showModalBottomSheet(
  ///   context,
  ///   MyBottomSheetContent(),
  /// );
  /// ```
  static Future<T?> showCustomModalBottomSheet<T>(
    BuildContext context,
    Widget content, {
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => content,
    );
  }
}