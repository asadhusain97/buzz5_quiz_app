import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/main.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:provider/provider.dart';

class FinalPage extends StatelessWidget {
  const FinalPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.i("FinalPage built");
    return BasePage(
      appBar: CustomAppBar(title: 'Well Played!', showBackButton: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [ScoreBoard(), GameStats()],
        ),
      ),
    );
  }
}

class ScoreBoard extends StatefulWidget {
  const ScoreBoard({super.key});

  @override
  State<ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<ScoreBoard> {
  late final List<Player> _sortedPlayerList;

  @override
  void initState() {
    super.initState();
    // Capture and sort the player list once at initialization
    // This ensures the leaderboard never changes after being displayed
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _sortedPlayerList = List<Player>.from(playerProvider.playerList);
    _sortPlayerListLocally();
  }

  /// Sort the player list using the same logic as PlayerProvider
  /// to ensure consistent ordering
  void _sortPlayerListLocally() {
    _sortedPlayerList.sort((a, b) {
      // 1. Sort by decreasing score (highest score first)
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }

      // 2. Sort by lowest sum of negative points descending
      // (players with fewer negative points come first)
      int sumNegativeA = a.allPoints.fold(
        0,
        (value, point) => point < 0 ? value + point : value,
      );
      int sumNegativeB = b.allPoints.fold(
        0,
        (value, point) => point < 0 ? value + point : value,
      );
      if (sumNegativeA != sumNegativeB) {
        return sumNegativeB.compareTo(sumNegativeA);
      }

      // 3. Sort by first hits (more first hits come first)
      if (b.firstHits != a.firstHits) {
        return b.firstHits.compareTo(a.firstHits);
      }

      // 4. Sort alphabetically by name as final tiebreaker
      return a.name.compareTo(b.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: 300,
          height: 900,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text('🏆 Final Standing', style: AppTextStyles.titleBig),
              SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  itemCount: _sortedPlayerList.length,
                  itemBuilder: (context, index) {
                    final player = _sortedPlayerList[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.1,
                        ), // Translucent white
                        border: Border.all(
                          color: index == 0 ? Colors.yellow : Colors.grey,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(
                              0,
                              0,
                              0,
                              0.1,
                            ), // Translucent black
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 5, right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${index + 1}. ${player.name}',
                                  style: AppTextStyles.scoreCard,
                                ),
                                Text(
                                  '${player.score}',
                                  style: AppTextStyles.scoreCard,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2),
                          Padding(
                            padding: EdgeInsets.only(left: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'First hits:  ${player.firstHits}',
                                      style: AppTextStyles.scoreSubtitle,
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Accuracy:  ${player.allPoints.isNotEmpty ? '${(player.correctAnsCount / player.allPoints.length * 100).toStringAsFixed(1)}%' : '-'} (${player.allPoints.length} attempts)',
                                      style: AppTextStyles.scoreSubtitle,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }
}

class GameStats extends StatelessWidget {
  const GameStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final playerList = playerProvider.playerList;
        final totalAttempts = playerList.fold(
          0,
          (sum, player) => sum + player.allPoints.length,
        );
        final correctAnswers = playerList.fold(
          0,
          (sum, player) => sum + player.correctAnsCount,
        );
        final wrongAnswers = playerList.fold(
          0,
          (sum, player) => sum + player.wrongAnsCount,
        );
        // Use the computed game time from the provider
        final gameTime = playerProvider.gameTime;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Game Statistics',
              style: AppTextStyles.headingSmall.copyWith(
                color: ColorConstants.primaryColor,
              ),
            ),
            SizedBox(height: 80),
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      totalAttempts > 0
                          ? '${(correctAnswers / totalAttempts * 100).toStringAsFixed(1)}%'
                          : '-',
                      style: AppTextStyles.titleBig,
                    ),
                    Text('Accuracy', style: AppTextStyles.gameStatTitles),
                  ],
                ),
                SizedBox(width: 30),
                Column(
                  children: [
                    Text('$totalAttempts', style: AppTextStyles.titleBig),
                    Text('Total attempts', style: AppTextStyles.gameStatTitles),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Column(
                  children: [
                    Text('$wrongAnswers', style: AppTextStyles.titleBig),
                    Text('Wrong answers', style: AppTextStyles.gameStatTitles),
                  ],
                ),
                SizedBox(width: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$correctAnswers', style: AppTextStyles.titleBig),
                    Text(
                      'Correct answers',
                      style: AppTextStyles.gameStatTitles,
                    ),
                  ],
                ),
                SizedBox(width: 30),
                Column(
                  children: [
                    Text(gameTime, style: AppTextStyles.titleBig),
                    Text('Game time', style: AppTextStyles.gameStatTitles),
                  ],
                ),
              ],
            ),
            SizedBox(height: 80),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyApp()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 50), // Set the minimum size
                backgroundColor: ColorConstants.primaryContainerColor,
              ),
              child: Text(
                'Play Again',
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.surfaceColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
