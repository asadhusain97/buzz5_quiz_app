import 'dart:math';
import 'package:buzz5_quiz_app/models/player.dart';

/// Utility class for generating unique guest names with random adjectives.
///
/// This class ensures that guest names are unique by prepending random
/// adjectives when a duplicate name is detected.
///
/// Example:
/// - First guest enters "John" → "John"
/// - Second guest enters "John" → "Happy John"
/// - Third guest enters "John" → "Clever John"
class GuestNameUtils {
  // List of positive, family-friendly adjectives
  static const List<String> _adjectives = [
    'Happy',
    'Clever',
    'Bright',
    'Swift',
    'Brave',
    'Smart',
    'Cool',
    'Lucky',
    'Epic',
    'Bold',
    'Wise',
    'Quick',
    'Mighty',
    'Noble',
    'Loyal',
    'Stellar',
    'Cosmic',
    'Golden',
    'Silver',
    'Royal',
    'Super',
    'Mega',
    'Ultra',
    'Prime',
    'Elite',
    'Alpha',
    'Omega',
    'Dynamic',
    'Turbo',
    'Lightning',
    'Thunder',
    'Storm',
    'Blaze',
    'Frost',
    'Shadow',
    'Phoenix',
    'Dragon',
    'Tiger',
    'Eagle',
    'Falcon',
    'Ninja',
    'Samurai',
    'Wizard',
    'Knight',
    'Champion',
    'Legend',
    'Master',
    'Captain',
    'Admiral',
    'General',
  ];

  static final Random _random = Random();

  /// Generates a unique guest name by checking against existing players.
  ///
  /// If the [desiredName] is already taken, a random adjective is prepended.
  /// The method will keep trying different adjectives until a unique name is found.
  ///
  /// Parameters:
  /// - [desiredName]: The name the guest wants to use
  /// - [existingPlayers]: List of players currently in the game
  ///
  /// Returns:
  /// A unique name, either the original or with an adjective prefix
  ///
  /// Example:
  /// ```dart
  /// final uniqueName = GuestNameUtils.generateUniqueName(
  ///   desiredName: 'John',
  ///   existingPlayers: playerList,
  /// );
  /// // Returns: 'John' if available, or 'Happy John' if taken
  /// ```
  static String generateUniqueName({
    required String desiredName,
    required List<Player> existingPlayers,
  }) {
    final trimmedName = desiredName.trim();

    // Check if the name is available as-is
    if (!_isNameTaken(trimmedName, existingPlayers)) {
      return trimmedName;
    }

    // Name is taken, generate a unique name with adjective
    final availableAdjectives = List<String>.from(_adjectives);

    // Shuffle for randomness
    availableAdjectives.shuffle(_random);

    // Try each adjective until we find a unique combination
    for (final adjective in availableAdjectives) {
      final uniqueName = '$adjective $trimmedName';

      if (!_isNameTaken(uniqueName, existingPlayers)) {
        return uniqueName;
      }
    }

    // In the extremely unlikely case all adjectives are taken,
    // add a random number
    final fallbackName = '${availableAdjectives[0]} $trimmedName ${_random.nextInt(999)}';
    return fallbackName;
  }

  /// Checks if a name is already taken by an existing player.
  ///
  /// Comparison is case-insensitive to prevent similar names like
  /// "John" and "john" from being considered different.
  ///
  /// Parameters:
  /// - [name]: The name to check
  /// - [existingPlayers]: List of players to check against
  ///
  /// Returns:
  /// true if the name is already taken, false otherwise
  static bool _isNameTaken(String name, List<Player> existingPlayers) {
    final lowerName = name.toLowerCase();
    return existingPlayers.any(
      (player) => player.name.toLowerCase() == lowerName,
    );
  }

  /// Gets a random adjective from the list.
  ///
  /// This can be used for other purposes like generating fun display names.
  ///
  /// Returns:
  /// A random adjective string
  static String getRandomAdjective() {
    return _adjectives[_random.nextInt(_adjectives.length)];
  }

  /// Checks if a name is available (not taken by existing players).
  ///
  /// This is a public wrapper around [_isNameTaken] for external use.
  ///
  /// Parameters:
  /// - [name]: The name to check
  /// - [existingPlayers]: List of players to check against
  ///
  /// Returns:
  /// true if the name is available, false if taken
  static bool isNameAvailable({
    required String name,
    required List<Player> existingPlayers,
  }) {
    return !_isNameTaken(name, existingPlayers);
  }
}
