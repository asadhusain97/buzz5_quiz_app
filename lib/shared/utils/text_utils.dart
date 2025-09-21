/// Utility functions for text manipulation and formatting.
///
/// This class provides common text operations used throughout the application,
/// including truncation, validation, and formatting functions.
class TextUtils {
  // Prevent instantiation
  TextUtils._();

  /// Default maximum text length for truncation
  static const int defaultMaxLength = 500;

  /// Truncates text to the specified length, adding ellipsis if needed.
  ///
  /// Parameters:
  /// - [text]: The text to truncate
  /// - [maxLength]: Maximum length before truncation (default: 500)
  ///
  /// Returns the original text if it's shorter than [maxLength],
  /// otherwise returns truncated text with '...' appended.
  ///
  /// Example:
  /// ```dart
  /// final result = TextUtils.truncateText('This is a long text', 10);
  /// // Returns: 'This is a ...'
  /// ```
  static String truncateText(String text, [int maxLength = defaultMaxLength]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Checks if a string is null, empty, or contains only whitespace.
  ///
  /// Returns `true` if the string is effectively empty, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// TextUtils.isEmpty('   '); // Returns: true
  /// TextUtils.isEmpty('hello'); // Returns: false
  /// ```
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Checks if a string is not null, not empty, and contains non-whitespace characters.
  ///
  /// This is the opposite of [isEmpty].
  ///
  /// Example:
  /// ```dart
  /// TextUtils.isNotEmpty('hello'); // Returns: true
  /// TextUtils.isNotEmpty('   '); // Returns: false
  /// ```
  static bool isNotEmpty(String? text) {
    return !isEmpty(text);
  }

  /// Capitalizes the first letter of a string.
  ///
  /// Returns the original string if it's empty or null.
  ///
  /// Example:
  /// ```dart
  /// TextUtils.capitalize('hello world'); // Returns: 'Hello world'
  /// ```
  static String capitalize(String? text) {
    if (isEmpty(text)) return text ?? '';
    return text![0].toUpperCase() + text.substring(1);
  }

  /// Converts a string to title case (capitalizes each word).
  ///
  /// Example:
  /// ```dart
  /// TextUtils.toTitleCase('hello world'); // Returns: 'Hello World'
  /// ```
  static String toTitleCase(String? text) {
    if (isEmpty(text)) return text ?? '';

    return text!
        .split(' ')
        .map((word) => capitalize(word))
        .join(' ');
  }

  /// Formats a player name for display, ensuring proper capitalization.
  ///
  /// This method:
  /// - Trims whitespace
  /// - Capitalizes the first letter
  /// - Handles empty/null cases gracefully
  ///
  /// Example:
  /// ```dart
  /// TextUtils.formatPlayerName(' john doe '); // Returns: 'John doe'
  /// ```
  static String formatPlayerName(String? name) {
    if (isEmpty(name)) return 'Unknown Player';
    return capitalize(name!.trim());
  }

  /// Extracts initials from a full name.
  ///
  /// Takes the first letter of each word in the name.
  /// Returns up to 2 characters for better display.
  ///
  /// Example:
  /// ```dart
  /// TextUtils.getInitials('John Doe Smith'); // Returns: 'JD'
  /// TextUtils.getInitials('Alice'); // Returns: 'A'
  /// ```
  static String getInitials(String? fullName) {
    if (isEmpty(fullName)) return '??';

    final words = fullName!.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '??';

    String initials = '';
    for (int i = 0; i < words.length && i < 2; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0].toUpperCase();
      }
    }

    return initials.isEmpty ? '??' : initials;
  }

  /// Formats a score for display with proper sign handling.
  ///
  /// Adds a '+' prefix for positive scores, keeps '-' for negative.
  ///
  /// Example:
  /// ```dart
  /// TextUtils.formatScore(25); // Returns: '+25'
  /// TextUtils.formatScore(-10); // Returns: '-10'
  /// TextUtils.formatScore(0); // Returns: '0'
  /// ```
  static String formatScore(int score) {
    if (score > 0) return '+$score';
    return score.toString();
  }
}