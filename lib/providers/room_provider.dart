import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart' as app_auth;
import 'package:buzz5_quiz_app/config/logger.dart';
import 'dart:async';

class RoomProvider with ChangeNotifier {
  Room? _currentRoom;
  bool _hostRoom = true; // Default to hosting a room
  bool _isCreatingRoom = false;
  String? _error;
  List<RoomPlayer> _roomPlayers = [];
  StreamSubscription? _playersSubscription;
  PlayerProvider? _playerProvider;
  app_auth.AuthProvider? _authProvider;

  // Database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Room? get currentRoom => _currentRoom;
  bool get hostRoom => _hostRoom;
  bool get isCreatingRoom => _isCreatingRoom;
  String? get error => _error;
  bool get hasActiveRoom => _currentRoom != null && _currentRoom!.isActive;
  List<RoomPlayer> get roomPlayers => _roomPlayers;
  int get playerCount => _roomPlayers.length;

  // Toggle room hosting
  void setHostRoom(bool value) {
    _hostRoom = value;
    AppLogger.i("Host room setting changed to: $value");
    notifyListeners();
  }

  // Set PlayerProvider for synchronization
  void setPlayerProvider(PlayerProvider playerProvider) {
    _playerProvider = playerProvider;
    AppLogger.i("PlayerProvider set for synchronization");
  }

  // Set AuthProvider for user authentication (supports both Firebase auth and local guests)
  void setAuthProvider(app_auth.AuthProvider authProvider) {
    _authProvider = authProvider;
    AppLogger.i("AuthProvider set for RoomProvider");
  }

  // Sync roomPlayers to local playerList (excluding host)
  void _syncPlayersToProvider() {
    if (_playerProvider == null) return;

    // Convert roomPlayers to Player objects (excluding host for game scoring)
    final nonHostPlayers = _roomPlayers.where((rp) => !rp.isHost).toList();
    final currentPlayerList = _playerProvider!.playerList;
    final newPlayerList = <Player>[];

    for (final roomPlayer in nonHostPlayers) {
      // Try to find existing player to preserve scoring data by Firebase UID
      Player? existingPlayer;
      try {
        existingPlayer = currentPlayerList.firstWhere(
          (p) => p.accountId == roomPlayer.playerId,
        );
      } catch (e) {
        existingPlayer = null;
      }

      if (existingPlayer != null) {
        // Keep existing player with their scores, but update the name if changed
        existingPlayer.name = roomPlayer.name;
        newPlayerList.add(existingPlayer);
        AppLogger.i(
          "Preserved existing player data for ${roomPlayer.playerId} with new name: ${roomPlayer.name}",
        );
      } else {
        // Create new player for scoring
        // Try Firebase user first, then fall back to AuthProvider for guests
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final appUser = _authProvider?.user;
        final currentUid = firebaseUser?.uid ?? appUser?.uid;

        final accountId =
            (roomPlayer.playerId == currentUid)
                ? currentUid
                : roomPlayer.playerId;

        newPlayerList.add(Player(name: roomPlayer.name, accountId: accountId));
        AppLogger.i(
          "Created new player for ${roomPlayer.playerId} with name: ${roomPlayer.name}",
        );
      }
    }

    // Update playerList with synchronized players
    _playerProvider!.setPlayerList(newPlayerList);
    AppLogger.i("Synchronized ${newPlayerList.length} players to playerList");
  }

  // Create a new room
  Future<bool> createRoom({List<String>? hostPlayerNames}) async {
    if (_isCreatingRoom) return false;

    _isCreatingRoom = true;
    _error = null;
    notifyListeners();

    try {
      // Get user from Firebase Auth or local guest
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final appUser = _authProvider?.user;
      final uid = firebaseUser?.uid ?? appUser?.uid;
      final displayName = firebaseUser?.displayName ?? appUser?.displayName;

      if (uid == null) {
        _error = "Please log in to host a game";
        AppLogger.e("Cannot create room: User not authenticated");
        return false;
      }

      final roomCode = await Room.generateRoomCode();
      final roomId = roomCode.toLowerCase(); // Use lowercase for database path
      final now = DateTime.now().millisecondsSinceEpoch;

      final room = Room(
        roomId: roomId,
        roomCode: roomCode,
        hostId: uid,
        status: RoomStatus.waiting,
        createdAt: now,
      );

      // Create room structure in Realtime Database
      final roomRef = _database.child('rooms').child(roomId);

      // Set room info
      await roomRef.child('roomInfo').set(room.toRoomInfo());

      // Store allowed player names for validation during join
      if (hostPlayerNames != null && hostPlayerNames.isNotEmpty) {
        final allowedPlayersMap = <String, bool>{};
        for (final playerName in hostPlayerNames) {
          allowedPlayersMap[playerName.toLowerCase()] = true;
        }
        await roomRef.child('allowedPlayers').set(allowedPlayersMap);
        AppLogger.i("Stored allowed player names: $hostPlayerNames");
      }

      // Initialize empty game state
      final gameState = GameState();
      await roomRef.child('gameState').set(gameState.toMap());

      // Add host as first player
      final hostPlayer = RoomPlayer(
        playerId: uid,
        name: displayName ?? 'Host',
        isHost: true,
        joinedAt: now,
      );
      await roomRef.child('players').child(uid).set(hostPlayer.toMap());

      _currentRoom = room;
      final userType = appUser?.isGuest == true ? 'Guest' : 'Authenticated';
      AppLogger.i("Room created successfully: $roomCode with ID: $roomId ($userType user)");

      // Set up presence tracking for the host (skip for guests as they don't have Firebase auth)
      if (firebaseUser != null) {
        await _setupPresenceTracking(roomId, uid);
      } else {
        AppLogger.i("Skipping presence tracking for guest user");
      }

      // Start listening for player changes
      _startListeningToPlayers();

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
      final snapshot =
          await _database.child('rooms').child(roomId).child('roomInfo').get();

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

  // Join an existing room with player name validation
  Future<bool> joinRoom(String roomCode, {String? playerName}) async {
    try {
      // Get user from Firebase Auth or local guest
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final appUser = _authProvider?.user;
      final uid = firebaseUser?.uid ?? appUser?.uid;
      final displayName = firebaseUser?.displayName ?? appUser?.displayName;

      if (uid == null) {
        _error = "User not authenticated";
        AppLogger.e("Cannot join room: User not authenticated");
        return false;
      }

      final room = await getRoomByCode(roomCode);
      if (room == null) {
        _error = "Room not found";
        return false;
      }

      if (!room.isActive || room.isExpired) {
        _error = "Room is no longer active";
        return false;
      }

      // Validate player name if provided
      if (playerName != null && playerName.trim().isNotEmpty) {
        final isValidPlayerName = await _validatePlayerName(
          room.roomId,
          playerName.trim(),
        );
        if (!isValidPlayerName) {
          _error =
              "Player name '$playerName' is not allowed in this room. Please check with the host.";
          AppLogger.w(
            "Player name validation failed for: $playerName in room: $roomCode",
          );
          return false;
        }
      }

      // Check if this user is the host
      final isHost = uid == room.hostId;

      // Add player to room (if host, update existing host entry with new name if provided)
      final player = RoomPlayer(
        playerId: uid,
        name:
            playerName?.trim() ??
            displayName ??
            (isHost ? 'Host' : 'Player'),
        isHost: isHost,
        joinedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _database
          .child('rooms')
          .child(room.roomId)
          .child('players')
          .child(uid)
          .set(player.toMap());

      _currentRoom = room;

      final userType = appUser?.isGuest == true ? 'Guest' : 'Authenticated';
      if (isHost) {
        AppLogger.i(
          "Host rejoined room: $roomCode with display name: ${player.name} ($userType user)",
        );
      } else {
        AppLogger.i(
          "Player joined room: $roomCode with name: ${player.name} ($userType user)",
        );
      }

      // Set up presence tracking for this player (skip for guests as they don't have Firebase auth)
      if (firebaseUser != null) {
        await _setupPresenceTracking(room.roomId, uid);
      } else {
        AppLogger.i("Skipping presence tracking for guest user");
      }

      // Start listening for player changes
      _startListeningToPlayers();

      notifyListeners();
      return true;
    } catch (e) {
      _error = "Failed to join room: $e";
      AppLogger.e("Error joining room: $e");
      notifyListeners();
      return false;
    }
  }

  // Validate if a player name is allowed in the room
  Future<bool> _validatePlayerName(String roomId, String playerName) async {
    try {
      final snapshot =
          await _database
              .child('rooms')
              .child(roomId)
              .child('allowedPlayers')
              .get();

      if (!snapshot.exists) {
        // If no allowed players are set, allow any name (backward compatibility)
        AppLogger.i("No allowed players restriction for room: $roomId");
        return true;
      }

      final allowedPlayers = Map<String, dynamic>.from(snapshot.value as Map);
      final normalizedPlayerName = playerName.toLowerCase();

      final isAllowed = allowedPlayers.containsKey(normalizedPlayerName);
      AppLogger.i(
        "Player name validation for '$playerName': ${isAllowed ? 'ALLOWED' : 'DENIED'}",
      );

      return isAllowed;
    } catch (e) {
      AppLogger.e("Error validating player name: $e");
      // On error, allow the player to join (fail-safe)
      return true;
    }
  }

  // Set up Firebase presence tracking for a player
  Future<void> _setupPresenceTracking(String roomId, String playerId) async {
    try {
      final playerRef = _database
          .child('rooms')
          .child(roomId)
          .child('players')
          .child(playerId);

      // Create presence references
      final connectedRef = _database.child('.info/connected');
      final presenceRef = playerRef.child('isConnected');
      final lastSeenRef = playerRef.child('lastSeen');

      // Listen for connection state changes
      connectedRef.onValue.listen((event) {
        final connected = event.snapshot.value == true;
        if (connected) {
          // Set player as connected
          presenceRef.set(true);
          lastSeenRef.set(DateTime.now().millisecondsSinceEpoch);

          // Set up disconnect handler - this will trigger when connection is lost
          presenceRef.onDisconnect().set(false);
          lastSeenRef.onDisconnect().set(DateTime.now().millisecondsSinceEpoch);

          AppLogger.i(
            "Presence tracking set up for player $playerId in room $roomId",
          );
        } else {
          // Connection lost - this will be handled by onDisconnect() automatically
          AppLogger.i("Connection lost for player $playerId");
        }
      });
    } catch (e) {
      AppLogger.e("Error setting up presence tracking: $e");
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

  // Start listening to real-time player changes
  void _startListeningToPlayers() {
    if (_currentRoom == null) return;

    // Cancel any existing subscription
    _playersSubscription?.cancel();

    final playersRef = _database
        .child('rooms')
        .child(_currentRoom!.roomId)
        .child('players');

    AppLogger.i(
      "Starting to listen for player changes in room: ${_currentRoom!.roomId}",
    );

    _playersSubscription = playersRef.onValue.listen((event) {
      final data = event.snapshot.value;
      final newPlayers = <RoomPlayer>[];

      if (data != null && data is Map) {
        final playersMap = Map<String, dynamic>.from(data);
        for (final entry in playersMap.entries) {
          final playerId = entry.key;
          final playerData = Map<String, dynamic>.from(entry.value);
          final player = RoomPlayer.fromMap(playerData, playerId);
          newPlayers.add(player);
        }
      }

      // Sort players by join time (host first)
      newPlayers.sort((a, b) {
        if (a.isHost && !b.isHost) return -1;
        if (!a.isHost && b.isHost) return 1;
        return a.joinedAt.compareTo(b.joinedAt);
      });

      _roomPlayers = newPlayers;
      AppLogger.i(
        "Player count updated: ${_roomPlayers.length} players in room",
      );

      // Sync roomPlayers to local playerList for game scoring
      _syncPlayersToProvider();

      notifyListeners();
    });
  }

  // Stop listening to player changes
  void _stopListeningToPlayers() {
    _playersSubscription?.cancel();
    _playersSubscription = null;
    _roomPlayers.clear();
    AppLogger.i("Stopped listening for player changes");
  }

  // End/close current room
  Future<void> endRoom() async {
    if (_currentRoom != null) {
      await updateRoomStatus(RoomStatus.ended);
      AppLogger.i("Room ended: ${_currentRoom!.roomId}");
    }
    _stopListeningToPlayers();
    _currentRoom = null;
    notifyListeners();
  }

  // Leave current room (removes player from Firebase and clears local state)
  Future<void> leaveRoom() async {
    if (_currentRoom == null) return;

    try {
      // Get user from Firebase Auth or local guest
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final appUser = _authProvider?.user;
      final uid = firebaseUser?.uid ?? appUser?.uid;

      if (uid != null) {
        // Remove player from the room in Firebase
        await _database
            .child('rooms')
            .child(_currentRoom!.roomId)
            .child('players')
            .child(uid)
            .remove();

        AppLogger.i(
          "Removed player $uid from room ${_currentRoom!.roomId}",
        );
      }
    } catch (e) {
      AppLogger.e("Error removing player from room: $e");
    }

    // Clear local state
    clearRoom();
  }

  // Clear current room (for internal use)
  void clearRoom() {
    _stopListeningToPlayers();
    _currentRoom = null;
    AppLogger.i("Cleared current room");
    notifyListeners();
  }

  // Reset all room data
  void reset() {
    _stopListeningToPlayers();
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

  // Force refresh player list (useful for refresh button)
  void refreshPlayerList() {
    if (_currentRoom != null) {
      AppLogger.i(
        "Force refreshing player list for room: ${_currentRoom!.roomId}",
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopListeningToPlayers();
    super.dispose();
  }
}
