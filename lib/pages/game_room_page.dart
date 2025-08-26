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

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  bool _isHelpExpanded = false;
  late DateTime _joinedTime;

  @override
  void initState() {
    super.initState();
    _joinedTime = DateTime.now();
    AppLogger.i("GameRoomPage initialized");
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: CustomAppBar(title: "Game Room", showBackButton: false),
      child: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
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
              "• The game host will select questions and start the game\n"
              "• You'll be able to buzz in when questions are active\n"
              "• Your score will be tracked throughout the game\n"
              "• Stay connected to participate in the full experience!",
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
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.red.shade400,
              Colors.red.shade600,
              Colors.red.shade800,
            ],
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
            border: Border.all(
              color: Colors.red.shade300.withValues(alpha: 0.8),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              "BUZZER",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
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
        ...roomPlayers.map((player) => _buildPlayerTile(player)),
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

          // Player name
          Expanded(
            child: Text(
              player.name,
              style: AppTextStyles.body.copyWith(
                color: ColorConstants.lightTextColor,
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),

          // Host badge (removed since hosts don't appear in this list)

          // You badge
          if (isCurrentUser) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorConstants.secondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "YOU",
                style: TextStyle(
                  color: ColorConstants.secondaryContainerColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
            'Are you sure you want to leave this game room?',
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
