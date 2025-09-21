import 'package:buzz5_quiz_app/config/logger.dart';

/// Represents a player in the quiz game with scoring and statistics tracking.
///
/// The Player class manages all aspects of a player's game state including:
/// - Score calculation and history
/// - Answer statistics (correct/wrong counts and totals)
/// - First hit tracking (for competitive features)
/// - Point management with undo functionality
///
/// This class is used throughout the game for:
/// - Leaderboard display and sorting
/// - Score tracking during gameplay
/// - Statistics calculation for final results
/// - Undo operations for score corrections
///
/// Example usage:
/// ```dart
/// final player = Player(name: 'John Doe');
/// player.addPoints(10); // Adds 10 points for correct answer
/// player.addPoints(-5); // Subtracts 5 points for wrong answer
/// player.undoLastPoint(); // Undoes the -5 point deduction
/// print(player.score); // Prints: 10
/// ```
class Player {
  /// The display name of the player
  ///
  /// This is shown in the leaderboard and throughout the game UI.
  /// Required field that cannot be empty.
  String name;

  /// Optional account identifier for authenticated users
  ///
  /// Links the player to a persistent user account for statistics
  /// and progress tracking across game sessions.
  String? accountId;

  /// Current total score for the player
  ///
  /// This is the sum of all points added during the game.
  /// Can be negative if the player has more wrong answers than correct ones.
  int score;

  /// Complete history of all points added during the game
  ///
  /// Maintains chronological order of point additions/subtractions.
  /// Used for undo operations and detailed statistics.
  /// Positive values represent correct answers, negative values represent wrong answers.
  List<int> allPoints;

  /// Number of correct answers given by the player
  ///
  /// Incremented each time positive points are added.
  /// Used for accuracy calculations and statistics display.
  int correctAnsCount;

  /// Total points earned from correct answers only
  ///
  /// Sum of all positive point values added to the player.
  /// Used to calculate average points per correct answer.
  int correctAnsTotal;

  /// Number of wrong answers given by the player
  ///
  /// Incremented each time negative points are added.
  /// Used for accuracy calculations and statistics display.
  int wrongAnsCount;

  /// Total points lost from wrong answers only
  ///
  /// Sum of all negative point values (stored as negative numbers).
  /// Used to calculate penalty impact and statistics.
  int wrongAnsTotal;

  /// Number of times this player was first to buzz in
  ///
  /// Tracks competitive engagement and quick response times.
  /// Used for additional statistics and potential bonus scoring.
  int firstHits;

  /// Creates a new Player instance.
  ///
  /// Parameters:
  /// - [name]: Required display name for the player
  /// - [accountId]: Optional account identifier for persistence
  /// - [score]: Starting score (defaults to 0)
  /// - [allPoints]: Initial point history (defaults to empty list)
  /// - [correctAnsCount]: Starting correct answer count (defaults to 0)
  /// - [correctAnsTotal]: Starting correct points total (defaults to 0)
  /// - [wrongAnsCount]: Starting wrong answer count (defaults to 0)
  /// - [wrongAnsTotal]: Starting wrong points total (defaults to 0)
  /// - [firstHits]: Starting first hits count (defaults to 0)
  ///
  /// Example:
  /// ```dart
  /// // Basic player creation
  /// final player = Player(name: 'Alice');
  ///
  /// // Player with existing score data
  /// final existingPlayer = Player(
  ///   name: 'Bob',
  ///   accountId: 'user_123',
  ///   score: 25,
  ///   allPoints: [10, 15, -5, 5],
  /// );
  /// ```
  Player({
    required this.name,
    this.accountId,
    this.score = 0,
    List<int>? allPoints,
    this.correctAnsCount = 0,
    this.correctAnsTotal = 0,
    this.wrongAnsCount = 0,
    this.wrongAnsTotal = 0,
    this.firstHits = 0,
  }) : allPoints = allPoints ?? [];

  /// Adds points to the player's score and updates statistics.
  ///
  /// This method:
  /// - Adds the point value to the total score
  /// - Records the point value in the points history
  /// - Updates correct/wrong answer statistics based on point value
  /// - Logs the action for debugging purposes
  ///
  /// Positive points are treated as correct answers.
  /// Negative points are treated as wrong answers.
  /// Zero points are recorded but don't affect answer statistics.
  ///
  /// Parameters:
  /// - [point]: The point value to add (can be positive, negative, or zero)
  ///
  /// Example:
  /// ```dart
  /// player.addPoints(15);  // Correct answer worth 15 points
  /// player.addPoints(-10); // Wrong answer with 10 point penalty
  /// player.addPoints(0);   // No points awarded/deducted
  /// ```
  void addPoints(int point) {
    // Add to points history for undo functionality
    allPoints.add(point);

    // Update total score
    score += point;

    // Update statistics based on point value
    if (point > 0) {
      correctAnsCount++;
      correctAnsTotal += point;
    } else if (point < 0) {
      wrongAnsCount++;
      wrongAnsTotal += point;
    }
    // Zero points don't affect answer statistics

    AppLogger.i("Added $point points to $name. New score: $score");
  }

  /// Removes the most recently added points and reverts associated statistics.
  ///
  /// This method:
  /// - Removes the last point entry from the history
  /// - Subtracts the point value from the total score
  /// - Decrements the appropriate answer count and total
  /// - Does nothing if no points have been added yet
  /// - Logs the action for debugging purposes
  ///
  /// This is useful for correcting scoring mistakes during gameplay.
  ///
  /// Example:
  /// ```dart
  /// player.addPoints(10);    // Score: 10, Correct: 1
  /// player.addPoints(-5);    // Score: 5, Wrong: 1
  /// player.undoLastPoint();  // Score: 10, Wrong: 0 (undid the -5)
  /// player.undoLastPoint();  // Score: 0, Correct: 0 (undid the +10)
  /// player.undoLastPoint();  // No effect (no more points to undo)
  /// ```
  void undoLastPoint() {
    if (allPoints.isEmpty) {
      AppLogger.w("Cannot undo - no points history for $name");
      return;
    }

    // Get and remove the last point value
    int lastPoint = allPoints.removeLast();

    // Revert the score change
    score -= lastPoint;

    // Revert the statistics changes
    if (lastPoint > 0) {
      correctAnsCount--;
      correctAnsTotal -= lastPoint;
    } else if (lastPoint < 0) {
      wrongAnsCount--;
      wrongAnsTotal -= lastPoint;
    }

    AppLogger.i("Undid $lastPoint points for $name. New score: $score");
  }

  /// Calculates the player's answer accuracy as a percentage.
  ///
  /// Returns the percentage of correct answers out of total answers.
  /// Returns 0.0 if no answers have been given.
  ///
  /// Example:
  /// ```dart
  /// // Player with 3 correct, 1 wrong answer
  /// final accuracy = player.getAccuracy(); // Returns: 75.0
  /// ```
  double getAccuracy() {
    final totalAnswers = correctAnsCount + wrongAnsCount;
    if (totalAnswers == 0) return 0.0;
    return (correctAnsCount / totalAnswers) * 100.0;
  }

  /// Calculates the average points earned per correct answer.
  ///
  /// Returns 0.0 if no correct answers have been given.
  ///
  /// Example:
  /// ```dart
  /// // Player earned 30 points from 2 correct answers
  /// final avg = player.getAveragePointsPerCorrect(); // Returns: 15.0
  /// ```
  double getAveragePointsPerCorrect() {
    if (correctAnsCount == 0) return 0.0;
    return correctAnsTotal / correctAnsCount;
  }

  /// Gets the total number of questions answered by this player.
  ///
  /// This includes both correct and wrong answers.
  ///
  /// Example:
  /// ```dart
  /// final total = player.getTotalAnswers(); // Returns: correctAnsCount + wrongAnsCount
  /// ```
  int getTotalAnswers() {
    return correctAnsCount + wrongAnsCount;
  }

  /// Creates a string representation of the player for debugging.
  ///
  /// Returns a formatted string containing the player's key statistics.
  ///
  /// Example output:
  /// ```
  /// Player{name: John Doe, score: 25, correct: 3, wrong: 1, firstHits: 2}
  /// ```
  @override
  String toString() {
    return 'Player{'
        'name: $name, '
        'score: $score, '
        'correct: $correctAnsCount, '
        'wrong: $wrongAnsCount, '
        'firstHits: $firstHits'
        '}';
  }

  /// Determines if two Player objects are equal based on name and accountId.
  ///
  /// Two players are considered equal if they have the same name and accountId.
  /// This is useful for identifying the same player across different game sessions.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
           other.name == name &&
           other.accountId == accountId;
  }

  /// Generates a hash code for the Player based on name and accountId.
  ///
  /// This ensures that equal Player objects have the same hash code,
  /// which is important for using Player objects in Sets and Map keys.
  @override
  int get hashCode => Object.hash(name, accountId);

  /// Creates a copy of this Player with optionally modified values.
  ///
  /// This is useful for creating variations of a player or for
  /// implementing undo/redo functionality at a higher level.
  ///
  /// Parameters: All parameters are optional and default to current values.
  ///
  /// Example:
  /// ```dart
  /// final newPlayer = originalPlayer.copyWith(
  ///   name: 'New Name',
  ///   score: 100,
  /// );
  /// ```
  Player copyWith({
    String? name,
    String? accountId,
    int? score,
    List<int>? allPoints,
    int? correctAnsCount,
    int? correctAnsTotal,
    int? wrongAnsCount,
    int? wrongAnsTotal,
    int? firstHits,
  }) {
    return Player(
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      score: score ?? this.score,
      allPoints: allPoints ?? List<int>.from(this.allPoints),
      correctAnsCount: correctAnsCount ?? this.correctAnsCount,
      correctAnsTotal: correctAnsTotal ?? this.correctAnsTotal,
      wrongAnsCount: wrongAnsCount ?? this.wrongAnsCount,
      wrongAnsTotal: wrongAnsTotal ?? this.wrongAnsTotal,
      firstHits: firstHits ?? this.firstHits,
    );
  }

  /// Converts the Player to a Map for serialization purposes.
  ///
  /// This is useful for storing player data in databases or APIs.
  ///
  /// Returns a Map<String, dynamic> representation of the player.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'accountId': accountId,
      'score': score,
      'allPoints': allPoints,
      'correctAnsCount': correctAnsCount,
      'correctAnsTotal': correctAnsTotal,
      'wrongAnsCount': wrongAnsCount,
      'wrongAnsTotal': wrongAnsTotal,
      'firstHits': firstHits,
    };
  }

  /// Creates a Player instance from a Map.
  ///
  /// This is useful for deserializing player data from databases or APIs.
  ///
  /// Parameters:
  /// - [map]: The Map<String, dynamic> containing player data
  ///
  /// Returns a new Player instance with data from the map.
  ///
  /// Example:
  /// ```dart
  /// final map = {
  ///   'name': 'Alice',
  ///   'score': 50,
  ///   'correctAnsCount': 5,
  /// };
  /// final player = Player.fromMap(map);
  /// ```
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'] as String,
      accountId: map['accountId'] as String?,
      score: map['score'] as int? ?? 0,
      allPoints: List<int>.from(map['allPoints'] as List? ?? []),
      correctAnsCount: map['correctAnsCount'] as int? ?? 0,
      correctAnsTotal: map['correctAnsTotal'] as int? ?? 0,
      wrongAnsCount: map['wrongAnsCount'] as int? ?? 0,
      wrongAnsTotal: map['wrongAnsTotal'] as int? ?? 0,
      firstHits: map['firstHits'] as int? ?? 0,
    );
  }
}