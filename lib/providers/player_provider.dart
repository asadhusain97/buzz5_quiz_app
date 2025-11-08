import 'dart:math';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class PlayerProvider with ChangeNotifier {
  List<Player> _playerList = [];
  String? _lastPositivePlayerName;
  String? _lastPositivePlayerAccountId;
  DateTime? _gameStartTime;
  DateTime? _gameEndTime;

  List<Player> get playerList => _playerList;

  /// Returns the player who last answered correctly, or null if none.
  ///
  /// This getter uses name and accountId matching to ensure the active player
  /// status persists reliably across:
  /// - Player list sorting (sortPlayerList)
  /// - Player list updates (setPlayerList)
  /// - Player disconnections/re-connections in multiplayer
  /// - Questions with no correct answers
  ///
  /// The active player remains highlighted until a different player answers
  /// correctly, even if multiple questions pass with no correct answers.
  ///
  /// Returns null if:
  /// - No player has answered correctly yet
  /// - The last positive player was removed from the game
  Player? get lastPositivePlayer {
    if (_lastPositivePlayerName == null) return null;

    try {
      return _playerList.firstWhere(
        (player) =>
            player.name == _lastPositivePlayerName &&
            player.accountId == _lastPositivePlayerAccountId,
      );
    } catch (e) {
      // Player not found in current list (may have been removed)
      AppLogger.w(
        "Last positive player '$_lastPositivePlayerName' not found in current player list",
      );
      return null;
    }
  }

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
    // Don't reset lastPositivePlayer - it should persist across list updates
    // The getter will find the player by name/accountId if they still exist
    AppLogger.i("Set player list: $playerList");
    notifyListeners();
  }

  /// Sets a random player as the last positive player.
  /// This is typically used at game start to initialize the active player.
  void setLastPositivePlayer() {
    if (playerList.isNotEmpty) {
      final randomIndex = Random().nextInt(playerList.length);
      final player = playerList[randomIndex];
      _lastPositivePlayerName = player.name;
      _lastPositivePlayerAccountId = player.accountId;
      AppLogger.i("Set lastPositivePlayer to: ${player.name}");
    }
    notifyListeners();
  }

  /// Manually sets a specific player as the last positive player.
  /// Use this when you need to explicitly assign active player status.
  void setLastPositivePlayerTo(Player player) {
    _lastPositivePlayerName = player.name;
    _lastPositivePlayerAccountId = player.accountId;
    AppLogger.i("Manually set lastPositivePlayer to: ${player.name}");
    notifyListeners();
  }

  /// Clears the last positive player status.
  /// Use this when starting a new game or resetting the active player indicator.
  void clearLastPositivePlayer() {
    _lastPositivePlayerName = null;
    _lastPositivePlayerAccountId = null;
    AppLogger.i("Cleared lastPositivePlayer");
    notifyListeners();
  }

  void sortPlayerList() {
    _playerList.sort((a, b) {
      // 1. Sort by decreasing score (highest score first)
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }

      // 2. Sort by lowest sum of negative points descending
      // (players with fewer negative points come first)
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

      // 3. Sort by first hits (more first hits come first)
      if (b.firstHits != a.firstHits) {
        return b.firstHits.compareTo(a.firstHits);
      }

      // 4. Sort alphabetically by name as final tiebreaker
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
        // Store the player's identifying information, not the object reference
        // This ensures the active player status persists across list modifications
        _lastPositivePlayerName = _playerList[playerIndex].name;
        _lastPositivePlayerAccountId = _playerList[playerIndex].accountId;
        AppLogger.i(
          "Set lastPositivePlayer to: ${_playerList[playerIndex].name}",
        );
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

  // Increment first hits for a player when they buzz first
  void incrementFirstHits(Player player) {
    int playerIndex = _playerList.indexOf(player);
    if (playerIndex != -1) {
      _playerList[playerIndex].firstHits++;
      AppLogger.i(
        "Incremented first hits for ${player.name}: ${_playerList[playerIndex].firstHits}",
      );
      notifyListeners();
    }
  }

  // Get player by name - helper method
  Player? getPlayerByName(String name) {
    try {
      return _playerList.firstWhere((player) => player.name == name);
    } catch (e) {
      return null;
    }
  }
}
