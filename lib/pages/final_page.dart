import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/home_page.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/playerProvider.dart';
import 'package:provider/provider.dart';

class FinalPage extends StatelessWidget {
  const FinalPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.i("FinalPage built");
    return Scaffold(
      appBar: CustomAppBar(title: 'Well Played!', showBackButton: true),
      body: Padding(
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

class ScoreBoard extends StatelessWidget {
  const ScoreBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return SizedBox(
          width: 300,
          height: 800,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text('🏆 Final Standing', style: AppTextStyles.titleBig),
              SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  itemCount: playerProvider.playerList.length,
                  itemBuilder: (context, index) {
                    final player = playerProvider.playerList[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: index == 0 ? Colors.yellow : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
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
                                      'Wrong ans:  ${player.wrongAnsCount} (${player.wrongAnsTotal})',
                                      style: AppTextStyles.scoreSubtitle,
                                    ),
                                    Text(
                                      'Correct ans:  ${player.correctAnsCount} (+${player.correctAnsTotal})',
                                      style: AppTextStyles.scoreSubtitle,
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Accuracy:  ${player.allPoints.isNotEmpty ? '${(player.correctAnsCount / player.allPoints.length * 100).toStringAsFixed(1)}%' : '-'}',
                                      style: AppTextStyles.scoreSubtitle,
                                    ),
                                    Text(
                                      'Total attempts:  ${player.allPoints.length}',
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
      },
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
                    Text('$gameTime', style: AppTextStyles.titleBig),
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
                  MaterialPageRoute(
                    builder: (context) {
                      return HomePage(onThemeChanged: (bool) {});
                    },
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 50), // Set the minimum size
              ),
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }
}
