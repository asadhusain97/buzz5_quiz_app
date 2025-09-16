import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:buzz5_quiz_app/models/room_provider.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
import 'package:buzz5_quiz_app/models/auth_provider.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  bool _isHelpExpanded = false;
  late DateTime _joinedTime;
  List<BuzzerEntry> _buzzerEntries = [];
  bool _hasPlayerBuzzed = false;
  StreamSubscription? _buzzerSubscription;
  StreamSubscription? _questionSubscription;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Question state variables
  bool _isQuestionActive = false;
  int? _questionStartTime;

  @override
  void initState() {
    super.initState();
    _joinedTime = DateTime.now();
    _setupBuzzerListener();
    AppLogger.i("GameRoomPage initialized");
  }

  @override
  void dispose() {
    _buzzerSubscription?.cancel();
    _questionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: CustomAppBar(title: "Game Room", showBackButton: false),
      child: Consumer2<RoomProvider, PlayerProvider>(
        builder: (context, roomProvider, playerProvider, child) {
          // Set up playerProvider synchronization with roomProvider if not already set
          if (roomProvider.hasActiveRoom) {
            roomProvider.setPlayerProvider(playerProvider);
            // Start listening to buzzer entries if room is active
            if (roomProvider.currentRoom != null) {
              _startListeningToBuzzers(roomProvider.currentRoom!.roomId);
            }
          }
          final room = roomProvider.currentRoom;
          final roomPlayers = roomProvider.roomPlayers;
          final hostPlayer = roomPlayers.firstWhere(
            (player) => player.isHost,
            orElse:
                () =>
                    RoomPlayer(playerId: '', name: 'Unknown Host', joinedAt: 0),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 80 : 16,
              vertical: 16,
            ),
            child: Column(
              children: [
                // Collapsible Help Widget
                _buildHelpWidget(),
                SizedBox(height: 20),

                // Header Row: Left Info | Right Actions
                Row(
                  children: [
                    // Left third: Room info
                    Expanded(
                      child: _buildLeftInfoPanel(room, hostPlayer, roomPlayers),
                    ),
                    // Center third: Empty space
                    Expanded(child: SizedBox()),
                    // Right third: Actions
                    Expanded(child: _buildRightActionsPanel()),
                  ],
                ),

                SizedBox(height: 40),

                // Center: Large Buzzer Button
                _buildBuzzerButton(),

                SizedBox(height: 40),

                // Bottom: Connected Players List (excluding host)
                _buildPlayersList(roomPlayers.where((p) => !p.isHost).toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelpWidget() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isHelpExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isHelpExpanded = expanded;
          });
        },
        leading: Icon(
          Icons.info_outline,
          color: ColorConstants.primaryContainerColor,
          size: 20,
        ),
        title: Text(
          "What happens next?",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.primaryContainerColor,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              "• The Quiz MC will read and display the questions and answers\n"
              "• You'll be able to buzz in when questions are active\n"
              "• Buzz carefully as there are negative points\n"
              "• Closing the tab/browser will not affect your connection or points\n"
              "• Leaving the game will forfeit your points\n",
              style: AppTextStyles.body.copyWith(
                color: ColorConstants.lightTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftInfoPanel(
    Room? room,
    RoomPlayer hostPlayer,
    List<RoomPlayer> roomPlayers,
  ) {
    if (room == null) return SizedBox();

    final connectedCount =
        roomPlayers.where((p) => p.isConnected && !p.isHost).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room Code
        Text(
          "Room Code",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          room.formattedRoomCode,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: ColorConstants.primaryContainerColor,
          ),
        ),
        SizedBox(height: 16),

        // Connected Players Count
        Text(
          "Connected",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "$connectedCount players",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.secondaryContainerColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),

        // Host Name (get display name from Firebase Auth if available)
        Text(
          "Host",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Consumer2<RoomProvider, AuthProvider>(
          builder: (context, roomProvider, authProvider, child) {
            // If the current user is the host, show their display name from auth
            final isCurrentUserHost = authProvider.user?.uid == room.hostId;
            String hostDisplayName = hostPlayer.name;

            if (isCurrentUserHost && authProvider.user != null) {
              hostDisplayName = authProvider.user!.displayNameOrEmail;
            }

            return Text(
              hostDisplayName,
              style: AppTextStyles.titleSmall.copyWith(
                color: ColorConstants.lightTextColor,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRightActionsPanel() {
    final timeSinceJoined = DateTime.now().difference(_joinedTime).inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Time Since Joined
        Text(
          "Connected",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "${timeSinceJoined}m ago",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.lightTextColor,
          ),
        ),
        SizedBox(height: 16),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Refresh Button
            IconButton(
              onPressed: () {
                final roomProvider = Provider.of<RoomProvider>(
                  context,
                  listen: false,
                );
                roomProvider.refreshPlayerList();
                AppLogger.i("Refreshing room status");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Room status refreshed"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(Icons.refresh),
              color: ColorConstants.primaryColor,
              tooltip: "Refresh",
            ),
            SizedBox(width: 8),

            // Leave Room Button
            ElevatedButton(
              onPressed: () => _showLeaveRoomDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.exit_to_app, size: 16),
                  SizedBox(width: 4),
                  Text("Leave", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuzzerButton() {
    final bool canBuzz = _isQuestionActive && !_hasPlayerBuzzed;
    return GestureDetector(
      onTap: canBuzz ? _onBuzzerPressed : null,
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: _getBuzzerGradientColors(),
            stops: [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            // Outer shadow for depth
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: Offset(0, 8),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            // Inner shadow for 3D effect
            BoxShadow(
              color: Colors.red.shade900.withValues(alpha: 0.6),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: -2,
            ),
            // Top highlight
            BoxShadow(
              color: Colors.red.shade200.withValues(alpha: 0.4),
              offset: Offset(0, -2),
              blurRadius: 8,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _getBuzzerBorderColor(), width: 3),
          ),
          child: Center(
            child: Text(
              _getBuzzerText(),
              style: TextStyle(
                color: _getBuzzerTextColor(),
                fontSize: _getBuzzerFontSize(),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList(List<RoomPlayer> roomPlayers) {
    if (roomPlayers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Text(
          "No other players have joined yet",
          style: AppTextStyles.body.copyWith(color: ColorConstants.hintGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final connectedPlayers = roomPlayers.where((p) => p.isConnected).length;

    // Sort players: buzzed players first (by buzz position), then un-buzzed players
    final sortedPlayers = _getSortedPlayerList(roomPlayers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "All Players ($connectedPlayers)",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.primaryContainerColor,
          ),
        ),
        SizedBox(height: 12),
        ...sortedPlayers.map((player) => _buildPlayerTile(player)),
      ],
    );
  }

  Widget _buildPlayerTile(RoomPlayer player) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isCurrentUser =
        playerProvider.playerList.isNotEmpty &&
        player.name == playerProvider.playerList.first.name;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? ColorConstants.primaryColor.withValues(alpha: 0.1)
                : ColorConstants.darkCardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border:
            isCurrentUser
                ? Border.all(color: ColorConstants.primaryColor, width: 1)
                : null,
      ),
      child: Row(
        children: [
          // Connection status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.isConnected ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 12),

          // Player name with YOU tag
          Expanded(
            child: Row(
              children: [
                Text(
                  player.name,
                  style: AppTextStyles.body.copyWith(
                    color: ColorConstants.lightTextColor,
                    fontWeight:
                        isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                // You badge (immediate right of name)
                if (isCurrentUser) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorConstants.secondaryColor.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "YOU",
                      style: TextStyle(
                        color: ColorConstants.secondaryContainerColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Buzzer timing (right side) - only show when question is active
          if (_getBuzzerEntryForPlayer(player.playerId) != null &&
              _isQuestionActive)
            _buildBuzzerTiming(_getBuzzerEntryForPlayer(player.playerId)!),
        ],
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ColorConstants.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Leave Room?',
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.lightTextColor,
            ),
          ),
          content: Text(
            'Are you sure you want to leave this game room?\n'
            'Your score will be lost forever.',
            style: AppTextStyles.body.copyWith(
              color: ColorConstants.lightTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: ColorConstants.primaryContainerColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _leaveRoom();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Leave Room'),
            ),
          ],
        );
      },
    );
  }

  void _setupBuzzerListener() {
    // We'll set up the listener when we have an active room
    // This will be called from the Consumer2 widget when room is available
  }

  void _startListeningToBuzzers(String roomId) {
    _buzzerSubscription?.cancel();
    _questionSubscription?.cancel();

    // Listen to current question state
    _startListeningToQuestionState(roomId);

    final buzzersRef = _database
        .child('rooms')
        .child(roomId)
        .child('currentQuestionBuzzes')
        .orderByChild('timestamp');

    AppLogger.i("Starting to listen for buzzer entries in room: $roomId");

    _buzzerSubscription = buzzersRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      final newBuzzerEntries = <BuzzerEntry>[];

      if (data != null && data is Map) {
        final buzzersMap = Map<String, dynamic>.from(data);
        for (final entry in buzzersMap.entries) {
          final playerId = entry.key;
          final buzzerData = Map<String, dynamic>.from(entry.value);
          final buzzerEntry = BuzzerEntry(
            playerId: buzzerData['playerId'] ?? playerId,
            playerName: buzzerData['playerName'] ?? 'Unknown',
            timestamp: buzzerData['timestamp'] ?? 0,
            questionNumber: 1, // Default question number
            position: buzzerData['position'] ?? 0,
          );
          newBuzzerEntries.add(buzzerEntry);
        }
      }

      // Sort by timestamp (fastest first)
      newBuzzerEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update positions based on sorted order
      for (int i = 0; i < newBuzzerEntries.length; i++) {
        newBuzzerEntries[i] = BuzzerEntry(
          playerId: newBuzzerEntries[i].playerId,
          playerName: newBuzzerEntries[i].playerName,
          timestamp: newBuzzerEntries[i].timestamp,
          questionNumber: newBuzzerEntries[i].questionNumber,
          position: i + 1,
        );
      }

      // Check if current player has buzzed
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      final hasPlayerBuzzed =
          currentUser != null &&
          newBuzzerEntries.any((entry) => entry.playerId == currentUser.uid);

      setState(() {
        _buzzerEntries = newBuzzerEntries;
        _hasPlayerBuzzed = hasPlayerBuzzed;
      });

      AppLogger.i("Buzzer entries updated: ${_buzzerEntries.length} entries");
    });
  }

  void _startListeningToQuestionState(String roomId) {
    final questionRef = _database
        .child('rooms')
        .child(roomId)
        .child('currentQuestion');

    AppLogger.i("Starting to listen for question state in room: $roomId");

    _questionSubscription = questionRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      bool isActive = false;
      int? startTime;

      if (data != null && data is Map) {
        final questionData = Map<String, dynamic>.from(data);
        isActive = questionData['isActive'] ?? false;
        startTime = questionData['startTime'];
      }

      if (mounted) {
        setState(() {
          _isQuestionActive = isActive;
          _questionStartTime = startTime;
          // Reset buzzer state when question changes
          if (!isActive) {
            _hasPlayerBuzzed = false;
            _buzzerEntries.clear();
          }
        });
      }

      AppLogger.i(
        "Question state updated: active=$isActive, startTime=$startTime",
      );
    });
  }

  Future<void> _onBuzzerPressed() async {
    if (!_isQuestionActive) {
      AppLogger.i("No question active, buzzer disabled");
      return;
    }

    if (_hasPlayerBuzzed) {
      AppLogger.i("Player has already buzzed, ignoring");
      return;
    }

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentRoom = roomProvider.currentRoom;
    final currentUser = authProvider.user;

    if (currentRoom == null || currentUser == null) {
      AppLogger.e("Cannot buzz: no active room or user");
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final position = _buzzerEntries.length + 1;
      final roomPlayer = roomProvider.roomPlayers.firstWhere(
        (p) => p.playerId == currentUser.uid,
        orElse:
            () => RoomPlayer(
              playerId: currentUser.uid,
              name: currentUser.displayName,
              joinedAt: DateTime.now().millisecondsSinceEpoch,
            ),
      );
      final playerName = roomPlayer.name;

      // Save to Firebase under currentQuestionBuzzes
      await _database
          .child('rooms')
          .child(currentRoom.roomId)
          .child('currentQuestionBuzzes')
          .child(currentUser.uid)
          .set({
            'playerId': currentUser.uid,
            'playerName': playerName,
            'timestamp': timestamp,
            'position': position,
          });

      // Update player's buzz count
      final playerRef = _database
          .child('rooms')
          .child(currentRoom.roomId)
          .child('players')
          .child(currentUser.uid);

      final currentPlayerSnapshot = await playerRef.get();
      if (currentPlayerSnapshot.exists) {
        final playerData = Map<String, dynamic>.from(
          currentPlayerSnapshot.value as Map,
        );
        final currentBuzzCount = playerData['buzzCount'] ?? 0;
        await playerRef.child('buzzCount').set(currentBuzzCount + 1);
      }

      AppLogger.i("Buzzer pressed by $playerName at timestamp: $timestamp");
    } catch (e) {
      AppLogger.e("Error recording buzzer press: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error recording buzz: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Format absolute time for first player (no '+' prefix)
  String _formatAbsoluteTimeForFirst(int timestamp) {
    if (_questionStartTime == null) {
      return "--:--";
    }

    final diffMs = timestamp - _questionStartTime!;
    final diffSeconds = diffMs / 1000.0;

    if (diffSeconds < 60) {
      return "${diffSeconds.toStringAsFixed(3)}s";
    } else {
      final minutes = (diffSeconds / 60).floor();
      final remainingSeconds = diffSeconds % 60;
      return "$minutes:${remainingSeconds.toStringAsFixed(3).padLeft(6, '0')}";
    }
  }

  // Format relative time from first player (with '+' prefix and 3 decimals)
  String _formatRelativeTimeFromFirst(
    int currentTimestamp,
    int firstTimestamp,
  ) {
    final diffMs = currentTimestamp - firstTimestamp;
    final diffSeconds = diffMs / 1000.0;
    return "+${diffSeconds.toStringAsFixed(3)}s";
  }

  BuzzerEntry? _getBuzzerEntryForPlayer(String playerId) {
    try {
      return _buzzerEntries.firstWhere((entry) => entry.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildBuzzerTiming(BuzzerEntry entry) {
    final position = _buzzerEntries.indexOf(entry) + 1;
    final isFirstPlayer = position == 1;

    // For first player: show absolute time without '+'
    // For others: show relative time from first player
    String timeDisplay;
    if (isFirstPlayer) {
      timeDisplay = _formatAbsoluteTimeForFirst(entry.timestamp);
    } else {
      final firstEntry = _buzzerEntries.first;
      timeDisplay = _formatRelativeTimeFromFirst(
        entry.timestamp,
        firstEntry.timestamp,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Position badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _getRankingColor(position),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "#$position",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 4),
        // Time display (absolute for first, relative for others)
        Text(
          timeDisplay,
          style: TextStyle(
            color: ColorConstants.secondaryContainerColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Get ranking color based on colors.dart temperature system
  Color _getRankingColor(int position) {
    switch (position) {
      case 1:
        return ColorConstants.rank1Color; // Hot red - 1st place
      case 2:
        return ColorConstants.rank2Color; // Orange - 2nd place
      case 3:
        return ColorConstants.rank3Color; // Yellow - 3rd place
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return ColorConstants.championTierColor; // Light green - ranks 4-10
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
        return ColorConstants.veteranTierColor; // Cyan - ranks 11-25
      default:
        return ColorConstants.challengerTierColor; // Cool blue - ranks 26+
    }
  }

  // Buzzer visual state helpers
  List<Color> _getBuzzerGradientColors() {
    if (!_isQuestionActive) {
      // Inactive - grey
      return [Colors.grey.shade300, Colors.grey.shade500, Colors.grey.shade700];
    } else if (_hasPlayerBuzzed) {
      // Buzzed - darker grey
      return [Colors.grey.shade400, Colors.grey.shade600, Colors.grey.shade800];
    } else {
      // Active - red
      return [Colors.red.shade400, Colors.red.shade600, Colors.red.shade800];
    }
  }

  String _getBuzzerText() {
    if (!_isQuestionActive) {
      return "Wait...";
    } else if (_hasPlayerBuzzed) {
      return "Buzzed";
    } else {
      return "BUZZER";
    }
  }

  Color _getBuzzerTextColor() {
    if (!_isQuestionActive) {
      return Colors.grey.shade600;
    } else if (_hasPlayerBuzzed) {
      return Colors.grey.shade400;
    } else {
      return Colors.white;
    }
  }

  double _getBuzzerFontSize() {
    if (!_isQuestionActive) {
      return 18;
    } else if (_hasPlayerBuzzed) {
      return 20;
    } else {
      return 24;
    }
  }

  Color _getBuzzerBorderColor() {
    if (!_isQuestionActive) {
      return Colors.grey.shade400.withValues(alpha: 0.8);
    } else if (_hasPlayerBuzzed) {
      return Colors.grey.shade500.withValues(alpha: 0.8);
    } else {
      return Colors.red.shade300.withValues(alpha: 0.8);
    }
  }

  // Sort players: buzzed players first (by buzz position), then un-buzzed players
  List<RoomPlayer> _getSortedPlayerList(List<RoomPlayer> players) {
    if (!_isQuestionActive || _buzzerEntries.isEmpty) {
      // Default sorting when no question is active or no buzzes yet
      return players;
    }

    final buzzedPlayerIds = _buzzerEntries.map((e) => e.playerId).toSet();
    final buzzedPlayers = <RoomPlayer>[];
    final unbuzzedPlayers = <RoomPlayer>[];

    // Separate buzzed and un-buzzed players
    for (final player in players) {
      if (buzzedPlayerIds.contains(player.playerId)) {
        buzzedPlayers.add(player);
      } else {
        unbuzzedPlayers.add(player);
      }
    }

    // Sort buzzed players by their buzz order (position)
    buzzedPlayers.sort((a, b) {
      final aEntry = _buzzerEntries.firstWhere((e) => e.playerId == a.playerId);
      final bEntry = _buzzerEntries.firstWhere((e) => e.playerId == b.playerId);
      return aEntry.position.compareTo(bEntry.position);
    });

    // Return buzzed players first, then un-buzzed players
    return [...buzzedPlayers, ...unbuzzedPlayers];
  }

  void _leaveRoom() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // Properly leave the room (removes from Firebase)
    await roomProvider.leaveRoom();
    playerProvider.setPlayerList([]);

    AppLogger.i("Left the room");

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
