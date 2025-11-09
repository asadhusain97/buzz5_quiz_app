import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:buzz5_quiz_app/pages/final_page.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

/// A reusable button widget that ends the current game and navigates to the final results page.
///
/// Features:
/// - Records game end time
/// - Sorts players by final score
/// - Writes final standings to Firebase
/// - Sets room status to "ended"
/// - Sets deletion timestamp for server-side cleanup
/// - Navigates to final page with proper styling
/// - Consistent design with app theme
class EndGameButton extends StatelessWidget {
  const EndGameButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _handleEndGame(context),
        style: _getButtonStyle(context),
        icon: const Icon(Icons.emoji_events),
        label: Text(
          'End Game',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  /// Handles the end game logic
  Future<void> _handleEndGame(BuildContext context) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);

    // Get current room
    final currentRoom = roomProvider.currentRoom;
    if (currentRoom == null) {
      AppLogger.e("END GAME: Cannot end game - no active room");
      return;
    }

    final roomId = currentRoom.roomId;

    AppLogger.i("END GAME: Ending game for room $roomId");

    // Step 1: Get final player data and sort by score (highest first)
    final playerList = List.from(playerProvider.playerList);
    playerList.sort((a, b) => b.score.compareTo(a.score));

    // Step 2: Create final standings list
    final List<Map<String, dynamic>> finalStandings =
        playerList.map((player) {
          return {
            'name': player.name,
            'score': player.score,
            'firstHits': player.firstHits,
            'correctAnsCount': player.correctAnsCount,
            'wrongAnsCount': player.wrongAnsCount,
          };
        }).toList();

    AppLogger.i(
      "END GAME: Final standings prepared with ${finalStandings.length} players",
    );

    // Step 3: Calculate deletion timestamp (2 hours in the future)
    final deleteAtTimestamp =
        DateTime.now().add(Duration(hours: 2)).millisecondsSinceEpoch;

    AppLogger.i(
      "END GAME: Room will be deleted at timestamp: $deleteAtTimestamp",
    );

    // Step 4: Prepare atomic multi-path update
    final Map<String, dynamic> updateData = {
      'rooms/$roomId/roomInfo/status': 'ended',
      'rooms/$roomId/finalStandings': finalStandings,
      'rooms/$roomId/roomInfo/deleteAt': deleteAtTimestamp,
    };

    try {
      // Step 5: Execute atomic write to Firebase
      await FirebaseDatabase.instance.ref().update(updateData);

      AppLogger.i("END GAME: Successfully wrote final game state to Firebase");

      // Record game end time in provider
      playerProvider.setGameEndTime(DateTime.now());

      // Sort players by final score (for local state)
      playerProvider.sortPlayerList();

      // Step 6: Navigate host away from game
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FinalPage()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e("END GAME: Error ending game: $e");
      AppLogger.e("END GAME: Stack trace: $stackTrace");

      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error ending game: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Gets the button style configuration
  ButtonStyle _getButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(150, 50),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
}
