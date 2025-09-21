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

        return _buildLeaderboardContent(
          playerProvider,
          roomProvider,
        );
      },
    );
  }

  /// Builds the main leaderboard content
  Widget _buildLeaderboardContent(
    PlayerProvider playerProvider,
    RoomProvider roomProvider,
  ) {
    return SingleChildScrollView(
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Leaderboard', style: AppTextStyles.titleMedium),
            const SizedBox(height: 20.0),
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
      width: 180.0,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: playerProvider.playerList.length,
        itemBuilder: (context, index) {
          final player = playerProvider.playerList[index];
          final isLastPositivePlayer = playerProvider.lastPositivePlayer == player;

          // Check room connection status
          final roomPlayer = _getRoomPlayer(roomProvider, player.name);
          final isConnectedToRoom = roomPlayer?.isConnected ?? false;

          return _buildPlayerCard(
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
    player,
    bool isLastPositivePlayer,
    bool isConnectedToRoom,
    bool hasActiveRoom,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: _getCardDecoration(isLastPositivePlayer),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Connection status indicator
                if (hasActiveRoom) _buildConnectionIndicator(isConnectedToRoom),
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
          const SizedBox(width: 8),
          Text(
            '${player.score}',
            style: AppTextStyles.scoreCard,
          ),
        ],
      ),
    );
  }

  /// Creates decoration for player cards
  BoxDecoration _getCardDecoration(bool isLastPositivePlayer) {
    return BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, 0.1),
      border: Border.all(
        color: isLastPositivePlayer ? Colors.green : Colors.grey,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(8.0),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.1),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Builds connection status indicator
  Widget _buildConnectionIndicator(bool isConnected) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected
          ? Colors.green
          : Colors.grey.withValues(alpha: 0.5),
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