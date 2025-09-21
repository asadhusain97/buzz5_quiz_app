import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A widget that displays the current room code for multiplayer games.
///
/// Features:
/// - Displays formatted room code
/// - Shows connected player count
/// - Responsive design with visual styling
/// - Automatically hides when no active room
class RoomCodeDisplay extends StatelessWidget {
  const RoomCodeDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        // Hide if no active room
        if (!roomProvider.hasActiveRoom || roomProvider.currentRoom == null) {
          return const SizedBox.shrink();
        }

        final room = roomProvider.currentRoom!;
        final connectedPlayers = _getConnectedPlayersCount(roomProvider);

        return _buildRoomCodeCard(room, connectedPlayers);
      },
    );
  }

  /// Builds the room code display card
  Widget _buildRoomCodeCard(room, int connectedPlayers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          _buildRoomCode(room.formattedRoomCode),
          const SizedBox(height: 4),
          _buildPlayerCount(connectedPlayers),
          const SizedBox(height: 2),
          _buildInstructions(),
        ],
      ),
    );
  }

  /// Creates the card decoration with border and shadow
  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: ColorConstants.primaryColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Builds the header with icon and title
  Widget _buildHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.doorbell,
          color: ColorConstants.primaryContainerColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Game Code',
          style: TextStyle(
            color: ColorConstants.surfaceColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds the formatted room code display
  Widget _buildRoomCode(String formattedRoomCode) {
    return SelectableText(
      formattedRoomCode,
      style: TextStyle(
        color: ColorConstants.primaryContainerColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  /// Builds the connected players count
  Widget _buildPlayerCount(int connectedPlayers) {
    return Text(
      '$connectedPlayers players connected',
      style: TextStyle(
        color: ColorConstants.secondaryContainerColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Builds the instruction text
  Widget _buildInstructions() {
    return Text(
      'Join game using the code above',
      style: TextStyle(
        color: ColorConstants.lightTextColor,
        fontSize: 11,
      ),
    );
  }

  /// Helper method to count connected players
  int _getConnectedPlayersCount(RoomProvider roomProvider) {
    return roomProvider.roomPlayers
        .where((player) => !player.isHost && player.isConnected)
        .length;
  }
}