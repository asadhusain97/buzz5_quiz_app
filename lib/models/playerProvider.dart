import 'dart:math';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class PlayerProvider with ChangeNotifier {
  List<Player> _playerList = [];
  Player? _lastPositivePlayer;
  DateTime? _gameStartTime;
  DateTime? _gameEndTime;

  List<Player> get playerList => _playerList;
  Player? get lastPositivePlayer => _lastPositivePlayer;

  // New getter for game time (in minutes)
  String get gameTime {
    if (_gameStartTime != null && _gameEndTime != null) {
      final duration = _gameEndTime!.difference(_gameStartTime!);
      return '${duration.inMinutes}m';
    }
    return 'TBD';
  }

  final Set<String> _answeredQuestions = {};

  void addPlayer(Player player) {
    _playerList.add(player);
    AppLogger.i("Added player: ${player.name}");
    notifyListeners();
  }

  void removePlayer(Player player) {
    _playerList.remove(player);
    AppLogger.i("Removed player: ${player.name}");
    notifyListeners();
  }

  void setPlayerList(List<Player> playerList) {
    _playerList = playerList;
    _lastPositivePlayer = null;
    AppLogger.i("Set player list: $playerList");
    notifyListeners();
  }

  void setLastPositivePlayer() {
    if (playerList.isNotEmpty) {
      final randomIndex = Random().nextInt(playerList.length);
      _lastPositivePlayer = playerList[randomIndex];
      AppLogger.i("Set lastPositivePlayer to: ${_lastPositivePlayer?.name}");
    }
    notifyListeners();
  }

  void sortPlayerList() {
    _playerList.sort((a, b) {
      // 1. Sort by decreasing score
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }

      // 2. Sort by lowest sum of negative points descending (players with less negative total come first)
      int sumNegativeA = a.allPoints.fold(
        0,
        (value, point) => point < 0 ? value + point : value,
      );
      int sumNegativeB = b.allPoints.fold(
        0,
        (value, point) => point < 0 ? value + point : value,
      );
      if (sumNegativeA != sumNegativeB) {
        return sumNegativeB.compareTo(sumNegativeA);
      }

      // 3. Sort alphabetically by name
      return a.name.compareTo(b.name);
    });
    AppLogger.i("Player list sorted");
    notifyListeners();
  }

  void addPointToPlayer(Player player, int point) {
    int playerIndex = _playerList.indexOf(player);
    if (playerIndex != -1) {
      _playerList[playerIndex].addPoints(point);
      if (point > 0) {
        _lastPositivePlayer = _playerList[playerIndex];
        AppLogger.i("Set lastPositivePlayer to: ${_lastPositivePlayer?.name}");
      }
      AppLogger.i("Added $point points to ${player.name}");
      notifyListeners();
    }
  }

  void undoLastPointForPlayer(Player player) {
    int playerIndex = _playerList.indexOf(player);
    if (playerIndex != -1) {
      _playerList[playerIndex].undoLastPoint();
      AppLogger.i("Undid last point for ${player.name}");
      notifyListeners();
    }
  }

  // Check if a question has been answered
  bool isQuestionAnswered(String questionId) {
    return _answeredQuestions.contains(questionId);
  }

  // Mark a question as answered
  void markQuestionAsAnswered(String questionId) {
    if (questionId.isNotEmpty) {
      _answeredQuestions.add(questionId);
      notifyListeners(); // Notify listeners to update UI
    }
  }

  // Reset answered questions
  void resetAnsweredQuestions() {
    _answeredQuestions.clear();
    notifyListeners();
  }

  void setGameStartTime(DateTime startTime) {
    _gameStartTime = startTime;
    notifyListeners();
  }

  void setGameEndTime(DateTime endTime) {
    _gameEndTime = endTime;
    notifyListeners();
  }
}
