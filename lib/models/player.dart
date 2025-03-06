// lib/models/player.dart
class Player {
  String name;
  int score;
  List<int> allPoints;

  Player({
    required this.name,
    this.score = 0,
    List<int>? allPoints, // Nullable to provide default value
  }) : allPoints = allPoints ?? [];

  // Method to add points
  void addPoints(int point) {
    allPoints.add(point);
    score += point;
  }

  // Method to reset the player's score
  void resetScore() {
    score = 0;
    allPoints.clear();
  }
}
