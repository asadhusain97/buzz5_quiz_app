import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/pages/final_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A reusable button widget that ends the current game and navigates to the final results page.
///
/// Features:
/// - Records game end time
/// - Sorts players by final score
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
  void _handleEndGame(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // Record game end time
    playerProvider.setGameEndTime(DateTime.now());

    // Sort players by final score
    playerProvider.sortPlayerList();

    // Navigate to final results page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinalPage()),
    );
  }

  /// Gets the button style configuration
  ButtonStyle _getButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(150, 50),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
}
