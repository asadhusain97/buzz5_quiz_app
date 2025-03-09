import 'package:buzz5_quiz_app/config/logger.dart';

class Player {
  String name;
  int score;
  List<int> allPoints;
  int correctAnsCount;
  int correctAnsTotal;
  int wrongAnsCount;
  int wrongAnsTotal;

  Player({
    required this.name,
    this.score = 0,
    List<int>? allPoints,
    this.correctAnsCount = 0,
    this.correctAnsTotal = 0,
    this.wrongAnsCount = 0,
    this.wrongAnsTotal = 0,
  }) : allPoints = allPoints ?? [];

  // Method to add points
  void addPoints(int point) {
    allPoints.add(point);
    score += point;
    if (point > 0) {
      correctAnsCount++;
      correctAnsTotal += point;
    } else {
      wrongAnsCount++;
      wrongAnsTotal += point;
    }
    AppLogger.i("Added $point points to $name. New score: $score");
  }

  // Method to reset the player's score
  void resetScore() {
    score = 0;
    allPoints.clear();
    correctAnsCount = 0;
    correctAnsTotal = 0;
    wrongAnsCount = 0;
    wrongAnsTotal = 0;
    AppLogger.i("Reset score for $name");
  }
}
