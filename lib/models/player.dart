import 'package:buzz5_quiz_app/config/logger.dart';

class Player {
  String name;
  int score;
  List<int> allPoints;

  Player({required this.name, this.score = 0, List<int>? allPoints})
    : allPoints = allPoints ?? [];

  // Method to add points
  void addPoints(int point) {
    allPoints.add(point);
    score += point;
    AppLogger.i("Added $point points to $name. New score: $score");
  }

  // Method to reset the player's score
  void resetScore() {
    score = 0;
    allPoints.clear();
    AppLogger.i("Reset score for $name");
  }
}
