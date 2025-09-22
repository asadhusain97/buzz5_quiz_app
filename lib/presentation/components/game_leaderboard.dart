import 'package:buzz5_quiz_app/config/app_dimensions.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

/// A reusable widget that displays the current game leaderboard with player scores.
///
/// Features:
/// - Real-time score updates via Provider
/// - Visual indicator for last positive player
/// - Connection status for multiplayer games
/// - Responsive design with scrolling support
class GameLeaderboard extends StatelessWidget {
  const GameLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, RoomProvider>(
      builder: (context, playerProvider, roomProvider, child) {
        // Synchronize providers if room is active
        if (roomProvider.hasActiveRoom) {
          roomProvider.setPlayerProvider(playerProvider);
        }

        AppLogger.i("Player list updated: ${playerProvider.playerList}");

        return _buildLeaderboardContent(context, playerProvider, roomProvider);
      },
    );
  }

  /// Builds the main leaderboard content
  Widget _buildLeaderboardContent(
    BuildContext context,
    PlayerProvider playerProvider,
    RoomProvider roomProvider,
  ) {
    return SingleChildScrollView(
      child: SizedBox(
        width: AppDimensions.leaderboardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Leaderboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: AppDimensions.defaultSpacing),
            _buildPlayersList(playerProvider, roomProvider),
          ],
        ),
      ),
    );
  }

  /// Builds the scrollable list of players with their scores
  Widget _buildPlayersList(
    PlayerProvider playerProvider,
    RoomProvider roomProvider,
  ) {
    return SizedBox(
      width: AppDimensions.leaderboardItemWidth,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: playerProvider.playerList.length,
        itemBuilder: (context, index) {
          final player = playerProvider.playerList[index];
          final isLastPositivePlayer =
              playerProvider.lastPositivePlayer == player;

          // Check room connection status
          final roomPlayer = _getRoomPlayer(roomProvider, player.name);
          final isConnectedToRoom = roomPlayer?.isConnected ?? false;

          return _buildPlayerCard(
            context,
            player,
            isLastPositivePlayer,
            isConnectedToRoom,
            roomProvider.hasActiveRoom,
          );
        },
      ),
    );
  }

  /// Builds individual player card with score and connection status
  Widget _buildPlayerCard(
    BuildContext context,
    player,
    bool isLastPositivePlayer,
    bool isConnectedToRoom,
    bool hasActiveRoom,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppDimensions.extraSmallSpacing),
      padding: AppDimensions.smallPadding,
      decoration: _getCardDecoration(isLastPositivePlayer, context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Connection status indicator
                if (hasActiveRoom)
                  _buildConnectionIndicator(context, isConnectedToRoom),
                Expanded(
                  child: Text(
                    player.name,
                    style: AppTextStyles.scoreCard,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.extraSmallSpacing),
          Text('${player.score}', style: AppTextStyles.scoreCard),
        ],
      ),
    );
  }

  /// Creates decoration for player cards
  BoxDecoration _getCardDecoration(
    bool isLastPositivePlayer,
    BuildContext context,
  ) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
      border: Border.all(
        color:
            isLastPositivePlayer
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : Theme.of(context).colorScheme.outline,
        width: 2,
      ),
      borderRadius: AppDimensions.defaultBorderRadius,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
          blurRadius: AppDimensions.shadowBlur,
          spreadRadius: AppDimensions.shadowSpread,
        ),
      ],
    );
  }

  /// Builds connection status indicator
  Widget _buildConnectionIndicator(BuildContext context, bool isConnected) {
    return Container(
      width: 8,
      height: 8,
      margin: EdgeInsets.only(right: AppDimensions.smallSpacing),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isConnected
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
      ),
    );
  }

  /// Helper method to get room player by name
  RoomPlayer? _getRoomPlayer(RoomProvider roomProvider, String playerName) {
    try {
      return roomProvider.roomPlayers.firstWhere(
        (rp) => rp.name.toLowerCase() == playerName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
