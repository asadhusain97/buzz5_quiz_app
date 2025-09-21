import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/app_dimensions.dart';

/// Custom theme extensions for game-specific styling patterns.
///
/// These extensions provide consistent styling for components that are
/// unique to the quiz game and don't have standard Material Design equivalents.
@immutable
class GameThemeExtension extends ThemeExtension<GameThemeExtension> {
  const GameThemeExtension({
    required this.scoreCardStyle,
    required this.leaderboardContainerDecoration,
    required this.questionButtonDecoration,
    required this.roomCodeStyle,
    required this.gameStatTitleStyle,
    required this.hintTextStyle,
    required this.connectionIndicatorColor,
    required this.answeredQuestionColor,
    required this.unansweredQuestionColor,
  });

  /// Text style for score cards in the leaderboard
  final TextStyle scoreCardStyle;

  /// Container decoration for leaderboard items
  final BoxDecoration leaderboardContainerDecoration;

  /// Decoration for question buttons
  final BoxDecoration questionButtonDecoration;

  /// Text style for room codes
  final TextStyle roomCodeStyle;

  /// Text style for game statistics titles
  final TextStyle gameStatTitleStyle;

  /// Text style for hint text
  final TextStyle hintTextStyle;

  /// Color for connection status indicators
  final Color connectionIndicatorColor;

  /// Color for answered questions
  final Color answeredQuestionColor;

  /// Color for unanswered questions
  final Color unansweredQuestionColor;

  @override
  GameThemeExtension copyWith({
    TextStyle? scoreCardStyle,
    BoxDecoration? leaderboardContainerDecoration,
    BoxDecoration? questionButtonDecoration,
    TextStyle? roomCodeStyle,
    TextStyle? gameStatTitleStyle,
    TextStyle? hintTextStyle,
    Color? connectionIndicatorColor,
    Color? answeredQuestionColor,
    Color? unansweredQuestionColor,
  }) {
    return GameThemeExtension(
      scoreCardStyle: scoreCardStyle ?? this.scoreCardStyle,
      leaderboardContainerDecoration: leaderboardContainerDecoration ?? this.leaderboardContainerDecoration,
      questionButtonDecoration: questionButtonDecoration ?? this.questionButtonDecoration,
      roomCodeStyle: roomCodeStyle ?? this.roomCodeStyle,
      gameStatTitleStyle: gameStatTitleStyle ?? this.gameStatTitleStyle,
      hintTextStyle: hintTextStyle ?? this.hintTextStyle,
      connectionIndicatorColor: connectionIndicatorColor ?? this.connectionIndicatorColor,
      answeredQuestionColor: answeredQuestionColor ?? this.answeredQuestionColor,
      unansweredQuestionColor: unansweredQuestionColor ?? this.unansweredQuestionColor,
    );
  }

  @override
  GameThemeExtension lerp(GameThemeExtension? other, double t) {
    if (other is! GameThemeExtension) {
      return this;
    }
    return GameThemeExtension(
      scoreCardStyle: TextStyle.lerp(scoreCardStyle, other.scoreCardStyle, t)!,
      leaderboardContainerDecoration: BoxDecoration.lerp(
        leaderboardContainerDecoration,
        other.leaderboardContainerDecoration,
        t,
      )!,
      questionButtonDecoration: BoxDecoration.lerp(
        questionButtonDecoration,
        other.questionButtonDecoration,
        t,
      )!,
      roomCodeStyle: TextStyle.lerp(roomCodeStyle, other.roomCodeStyle, t)!,
      gameStatTitleStyle: TextStyle.lerp(gameStatTitleStyle, other.gameStatTitleStyle, t)!,
      hintTextStyle: TextStyle.lerp(hintTextStyle, other.hintTextStyle, t)!,
      connectionIndicatorColor: Color.lerp(connectionIndicatorColor, other.connectionIndicatorColor, t)!,
      answeredQuestionColor: Color.lerp(answeredQuestionColor, other.answeredQuestionColor, t)!,
      unansweredQuestionColor: Color.lerp(unansweredQuestionColor, other.unansweredQuestionColor, t)!,
    );
  }

  /// Light theme game extension
  static const GameThemeExtension light = GameThemeExtension(
    scoreCardStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    leaderboardContainerDecoration: BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, 0.1),
      borderRadius: AppDimensions.defaultBorderRadius,
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.1),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    ),
    questionButtonDecoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.transparent,
    ),
    roomCodeStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
    ),
    gameStatTitleStyle: TextStyle(
      fontSize: 20,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
    ),
    hintTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w200,
      fontStyle: FontStyle.italic,
    ),
    connectionIndicatorColor: Colors.green,
    answeredQuestionColor: Colors.green,
    unansweredQuestionColor: Colors.transparent,
  );

  /// Dark theme game extension
  static const GameThemeExtension dark = GameThemeExtension(
    scoreCardStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    leaderboardContainerDecoration: BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, 0.05),
      borderRadius: AppDimensions.defaultBorderRadius,
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.2),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    ),
    questionButtonDecoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.transparent,
    ),
    roomCodeStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
    ),
    gameStatTitleStyle: TextStyle(
      fontSize: 20,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
    ),
    hintTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w200,
      fontStyle: FontStyle.italic,
    ),
    connectionIndicatorColor: Colors.green,
    answeredQuestionColor: Colors.green,
    unansweredQuestionColor: Colors.transparent,
  );
}

/// Extension method to easily access game theme extensions
extension GameThemeContext on BuildContext {
  /// Get the current game theme extension
  GameThemeExtension get gameTheme =>
      Theme.of(this).extension<GameThemeExtension>() ??
      GameThemeExtension.light;
}