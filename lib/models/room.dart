import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

enum RoomStatus { waiting, active, questionActive, ended }

class Room {
  final String roomId;
  final String roomCode;
  final String hostId;
  final RoomStatus status;
  final int createdAt;
  final int maxPlayers;
  final int currentQuestion;
  final int totalQuestions;
  final int? questionStartTime;

  Room({
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    this.status = RoomStatus.waiting,
    required this.createdAt,
    this.maxPlayers = 50,
    this.currentQuestion = 0,
    this.totalQuestions = 0,
    this.questionStartTime,
  });

  // Generate a unique 6-character room code
  static Future<String> generateRoomCode() async {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding confusing chars like 0, O, I, 1
    final random = Random();
    final database = FirebaseDatabase.instance.ref();

    String code;
    bool exists;

    do {
      code = '';
      for (int i = 0; i < 6; i++) {
        code += chars[random.nextInt(chars.length)];
      }

      // Check if room already exists
      final snapshot =
          await database.child('rooms').child(code.toLowerCase()).get();
      exists = snapshot.exists;
    } while (exists);

    AppLogger.i("Generated unique room code: $code");
    return code;
  }

  // Create Room from Realtime Database map
  factory Room.fromMap(Map<String, dynamic> data, String roomId) {
    return Room(
      roomId: roomId,
      roomCode: data['roomCode'] ?? '',
      hostId: data['hostId'] ?? '',
      status: _parseRoomStatus(data['status']),
      createdAt: data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      maxPlayers: data['maxPlayers'] ?? 50,
      currentQuestion: data['currentQuestion'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      questionStartTime: data['questionStartTime'],
    );
  }

  // Helper method to parse room status
  static RoomStatus _parseRoomStatus(dynamic status) {
    if (status == null) return RoomStatus.waiting;
    switch (status.toString()) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'active':
        return RoomStatus.active;
      case 'questionActive':
        return RoomStatus.questionActive;
      case 'ended':
        return RoomStatus.ended;
      default:
        return RoomStatus.waiting;
    }
  }

  // Convert Room to Realtime Database map (roomInfo structure)
  Map<String, dynamic> toRoomInfo() {
    return {
      'hostId': hostId,
      'roomCode': roomCode,
      'status': status.name,
      'createdAt': createdAt,
      'maxPlayers': maxPlayers,
      'currentQuestion': currentQuestion,
      'totalQuestions': totalQuestions,
      'questionStartTime': questionStartTime,
    };
  }

  // Copy with method for updating room data
  Room copyWith({
    String? roomId,
    String? roomCode,
    String? hostId,
    RoomStatus? status,
    int? createdAt,
    int? maxPlayers,
    int? currentQuestion,
    int? totalQuestions,
    int? questionStartTime,
  }) {
    return Room(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      questionStartTime: questionStartTime ?? this.questionStartTime,
    );
  }

  // Get formatted room code (with dash in middle for readability)
  String get formattedRoomCode {
    if (roomCode.length == 6) {
      return '${roomCode.substring(0, 3)}-${roomCode.substring(3)}';
    }
    return roomCode;
  }

  // Check if room is expired (older than 24 hours)
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - createdAt;
    return difference > (24 * 60 * 60 * 1000); // 24 hours in milliseconds
  }

  // Check if room is active (not ended and not expired)
  bool get isActive {
    return status != RoomStatus.ended && !isExpired;
  }

  @override
  String toString() {
    return 'Room(roomId: $roomId, roomCode: $roomCode, hostId: $hostId, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Room &&
        other.roomId == roomId &&
        other.roomCode == roomCode &&
        other.hostId == hostId;
  }

  @override
  int get hashCode {
    return roomId.hashCode ^ roomCode.hashCode ^ hostId.hashCode;
  }
}

// Player model for room participants
class RoomPlayer {
  final String playerId;
  final String name;
  final bool isHost;
  final int joinedAt;
  final int buzzCount;
  final bool isConnected;
  final int? lastSeen;

  RoomPlayer({
    required this.playerId,
    required this.name,
    this.isHost = false,
    required this.joinedAt,
    this.buzzCount = 0,
    this.isConnected = true,
    this.lastSeen,
  });

  factory RoomPlayer.fromMap(Map<String, dynamic> data, String playerId) {
    return RoomPlayer(
      playerId: playerId,
      name: data['name'] ?? '',
      isHost: data['isHost'] ?? false,
      joinedAt: data['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      buzzCount: data['buzzCount'] ?? 0,
      isConnected: data['isConnected'] ?? true,
      lastSeen: data['lastSeen'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isHost': isHost,
      'joinedAt': joinedAt,
      'buzzCount': buzzCount,
      'isConnected': isConnected,
      'lastSeen': lastSeen,
    };
  }

  RoomPlayer copyWith({
    String? playerId,
    String? name,
    bool? isHost,
    int? joinedAt,
    int? buzzCount,
    bool? isConnected,
    int? lastSeen,
  }) {
    return RoomPlayer(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt ?? this.joinedAt,
      buzzCount: buzzCount ?? this.buzzCount,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

// Buzzer entry model
class BuzzerEntry {
  final String playerId;
  final String playerName;
  final int timestamp;
  final int questionNumber;
  final int position;

  BuzzerEntry({
    required this.playerId,
    required this.playerName,
    required this.timestamp,
    required this.questionNumber,
    required this.position,
  });

  factory BuzzerEntry.fromMap(Map<String, dynamic> data) {
    return BuzzerEntry(
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      questionNumber: data['questionNumber'] ?? 0,
      position: data['position'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'timestamp': timestamp,
      'questionNumber': questionNumber,
      'position': position,
    };
  }

  String get buzzerKey => '${timestamp}_$playerId';
}

// Game state model
class GameState {
  final bool questionActive;
  final bool buzzersEnabled;
  final int topBuzzersCount;

  GameState({
    this.questionActive = false,
    this.buzzersEnabled = false,
    this.topBuzzersCount = 3,
  });

  factory GameState.fromMap(Map<String, dynamic> data) {
    return GameState(
      questionActive: data['questionActive'] ?? false,
      buzzersEnabled: data['buzzersEnabled'] ?? false,
      topBuzzersCount: data['topBuzzersCount'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionActive': questionActive,
      'buzzersEnabled': buzzersEnabled,
      'topBuzzersCount': topBuzzersCount,
    };
  }

  GameState copyWith({
    bool? questionActive,
    bool? buzzersEnabled,
    int? topBuzzersCount,
  }) {
    return GameState(
      questionActive: questionActive ?? this.questionActive,
      buzzersEnabled: buzzersEnabled ?? this.buzzersEnabled,
      topBuzzersCount: topBuzzersCount ?? this.topBuzzersCount,
    );
  }
}
