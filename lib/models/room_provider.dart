import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class RoomProvider with ChangeNotifier {
  Room? _currentRoom;
  bool _hostRoom = true; // Default to hosting a room
  bool _isCreatingRoom = false;
  String? _error;
  
  // Database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Room? get currentRoom => _currentRoom;
  bool get hostRoom => _hostRoom;
  bool get isCreatingRoom => _isCreatingRoom;
  String? get error => _error;
  bool get hasActiveRoom => _currentRoom != null && _currentRoom!.isActive;

  // Toggle room hosting
  void setHostRoom(bool value) {
    _hostRoom = value;
    AppLogger.i("Host room setting changed to: $value");
    notifyListeners();
  }

  // Create a new room
  Future<bool> createRoom() async {
    if (_isCreatingRoom) return false;
    
    _isCreatingRoom = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = "User not authenticated";
        AppLogger.e("Cannot create room: User not authenticated");
        return false;
      }

      final roomCode = await Room.generateRoomCode();
      final roomId = roomCode.toLowerCase(); // Use lowercase for database path
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final room = Room(
        roomId: roomId,
        roomCode: roomCode,
        hostId: user.uid,
        status: RoomStatus.waiting,
        createdAt: now,
      );

      // Create room structure in Realtime Database
      final roomRef = _database.child('rooms').child(roomId);
      
      // Set room info
      await roomRef.child('roomInfo').set(room.toRoomInfo());
      
      // Initialize empty game state
      final gameState = GameState();
      await roomRef.child('gameState').set(gameState.toMap());
      
      // Add host as first player
      final hostPlayer = RoomPlayer(
        playerId: user.uid,
        name: user.displayName ?? user.email?.split('@')[0] ?? 'Host',
        isHost: true,
        joinedAt: now,
      );
      await roomRef.child('players').child(user.uid).set(hostPlayer.toMap());

      _currentRoom = room;
      AppLogger.i("Room created successfully: $roomCode with ID: $roomId");
      return true;

    } catch (e) {
      _error = "Failed to create room: $e";
      AppLogger.e("Error creating room: $e");
      return false;
    } finally {
      _isCreatingRoom = false;
      notifyListeners();
    }
  }

  // Get room by code
  Future<Room?> getRoomByCode(String roomCode) async {
    try {
      final roomId = roomCode.toLowerCase();
      final snapshot = await _database
          .child('rooms')
          .child(roomId)
          .child('roomInfo')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Room.fromMap(data, roomId);
      }
      return null;
    } catch (e) {
      AppLogger.e("Error getting room by code: $e");
      return null;
    }
  }

  // Join an existing room
  Future<bool> joinRoom(String roomCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = "User not authenticated";
        return false;
      }

      final room = await getRoomByCode(roomCode);
      if (room != null && room.isActive && !room.isExpired) {
        // Add player to room
        final player = RoomPlayer(
          playerId: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'Player',
          joinedAt: DateTime.now().millisecondsSinceEpoch,
        );
        
        await _database
            .child('rooms')
            .child(room.roomId)
            .child('players')
            .child(user.uid)
            .set(player.toMap());
        
        _currentRoom = room;
        AppLogger.i("Joined room: $roomCode");
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = "Failed to join room: $e";
      AppLogger.e("Error joining room: $e");
      notifyListeners();
      return false;
    }
  }

  // Update room status
  Future<void> updateRoomStatus(RoomStatus status) async {
    if (_currentRoom == null) return;

    try {
      final updatedRoom = _currentRoom!.copyWith(status: status);

      await _database
          .child('rooms')
          .child(_currentRoom!.roomId)
          .child('roomInfo')
          .child('status')
          .set(status.name);

      _currentRoom = updatedRoom;
      AppLogger.i("Room status updated: ${status.name}");
      notifyListeners();
    } catch (e) {
      _error = "Failed to update room status: $e";
      AppLogger.e("Error updating room status: $e");
      notifyListeners();
    }
  }

  // End/close current room
  Future<void> endRoom() async {
    if (_currentRoom != null) {
      await updateRoomStatus(RoomStatus.ended);
      AppLogger.i("Room ended: ${_currentRoom!.roomId}");
    }
    _currentRoom = null;
    notifyListeners();
  }

  // Clear current room (for leaving)
  void clearRoom() {
    _currentRoom = null;
    AppLogger.i("Cleared current room");
    notifyListeners();
  }

  // Reset all room data
  void reset() {
    _currentRoom = null;
    _hostRoom = true;
    _isCreatingRoom = false;
    _error = null;
    AppLogger.i("Room provider reset");
    notifyListeners();
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}