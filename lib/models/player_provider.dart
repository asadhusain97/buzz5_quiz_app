import 'dart:math';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:flutter/material.dart';

class PlayerProvider with ChangeNotifier {
  List<Player> _playerList = [];
  Player? _lastPositivePlayer;

  List<Player> get playerList => _playerList;
  Player? get lastPositivePlayer => _lastPositivePlayer;

  void addPlayer(Player player) {
    _playerList.add(player);
    if (_lastPositivePlayer == null && _playerList.isNotEmpty) {
      _lastPositivePlayer =
          _playerList[Random().nextInt(_playerList.length)]; // Random default
    }
    notifyListeners();
  }

  void removePlayer(Player player) {
    _playerList.remove(player);
    notifyListeners();
  }

  void setPlayerList(List<Player> playerList) {
    _playerList = playerList;
    if (_lastPositivePlayer == null && _playerList.isNotEmpty) {
      _lastPositivePlayer =
          _playerList[Random().nextInt(_playerList.length)]; // Random default
    }
    notifyListeners();
  }

  void sortPlayerList() {
    _playerList.sort((a, b) {
      // 1. Sort by decreasing score
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }

      // 2. Sort by lowest sum of negative points
      int sumNegativeA = a.allPoints.fold(
        0,
        (value, point) => point < 0 ? value + point : value,
      );
      int sumNegativeB = b.allPoints.fold(
        0,
        (value, point) => point < 0 ? value + point : value,
      );
      if (sumNegativeA != sumNegativeB) {
        return sumNegativeA.compareTo(sumNegativeB);
      }

      // 3. Sort alphabetically by name
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void addPointToPlayer(Player player, int point) {
    int playerIndex = _playerList.indexOf(player);
    if (playerIndex != -1) {
      _playerList[playerIndex].allPoints.add(point);
      if (point > 0) {
        _lastPositivePlayer = _playerList[playerIndex];
      }
      notifyListeners();
    }
  }
}
