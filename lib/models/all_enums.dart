import 'package:flutter/material.dart';

/// Enums for consistent data
enum SetStatus { draft, complete }

enum BoardStatus { draft, complete }

enum QuestionStatus { draft, complete }

enum RoomStatus { waiting, active, questionActive, ended }

enum DifficultyLevel { easy, medium, hard }

/// Extension for DifficultyLevel to provide consistent UI helpers
extension DifficultyLevelExtension on DifficultyLevel {
  /// Get the display label for this difficulty level
  String get label {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  /// Get the short label for this difficulty level
  String get shortLabel {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Med';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  /// Get the color associated with this difficulty level
  Color get color {
    switch (this) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }
}

enum PredefinedTags {
  architecture,
  arts,
  astronomy,
  biology,
  business,
  civics,
  words,
  entertainment,
  fashion,
  foodAndDrinks,
  general,
  geography,
  history,
  india,
  literature,
  logos,
  maths,
  movies,
  mythology,
  other,
  personal,
  politics,
  popCulture,
  science,
  songs,
  sports,
  technology,
  us,
  videoGames,
  wordplay,
  world,
}

/// Extension for PredefinedTags to provide consistent UI helpers
extension PredefinedTagsExtension on PredefinedTags {
  /// Get the display name for this tag (formatted for UI display)
  String get displayName {
    // Handle special cases
    const specialCases = {
      'foodAndDrinks': 'Food & Drinks',
      'popCulture': 'Pop Culture',
      'videoGames': 'Video Games',
      'us': 'US',
    };

    final name = toString().split('.').last;
    if (specialCases.containsKey(name)) {
      return specialCases[name]!;
    }
    // Capitalize first letter
    return name[0].toUpperCase() + name.substring(1);
  }
}
