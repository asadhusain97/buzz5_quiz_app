import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/app_dimensions.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A widget that displays the current game code for multiplayer games.
///
/// Features:
/// - Displays formatted game code
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

        return _buildRoomCodeCard(context, room, connectedPlayers);
      },
    );
  }

  /// Builds the game code display card
  Widget _buildRoomCodeCard(BuildContext context, room, int connectedPlayers) {
    return Container(
      padding: AppDimensions.modalPadding,
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: AppDimensions.extraSmallSpacing + 2),
          _buildRoomCode(context, room.formattedRoomCode),
          SizedBox(height: AppDimensions.extraSmallSpacing),
          _buildPlayerCount(context, connectedPlayers),
          SizedBox(height: AppDimensions.extraSmallSpacing / 2),
          _buildInstructions(context),
        ],
      ),
    );
  }

  /// Creates the card decoration with border and shadow
  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: ColorConstants.transparent,
      borderRadius: AppDimensions.modalBorderRadius,
      border: Border.all(color: ColorConstants.primaryColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: ColorConstants.overlayMedium,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Builds the header with icon and title
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.doorbell,
          color: ColorConstants.primaryContainerColor,
          size: AppDimensions.smallIconSize + 4,
        ),
        SizedBox(width: AppDimensions.smallSpacing),
        Text(
          'Game Code',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: ColorConstants.surfaceColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds the formatted game code display
  Widget _buildRoomCode(BuildContext context, String formattedRoomCode) {
    return SelectableText(
      formattedRoomCode,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: ColorConstants.surfaceColor,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  /// Builds the connected players count
  Widget _buildPlayerCount(BuildContext context, int connectedPlayers) {
    return Text(
      '$connectedPlayers players connected',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: ColorConstants.secondaryContainerColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Builds the instruction text
  Widget _buildInstructions(BuildContext context) {
    return Text(
      'Join game using the code above',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
