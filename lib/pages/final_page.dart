import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
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
                        border: Border.all(color: Colors.grey),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wrong answers:  ${player.wrongAnsCount} (${player.wrongAnsTotal})',
                                  style: AppTextStyles.scoreSubtitle,
                                ),
                                Text(
                                  'Correct answers:  ${player.correctAnsCount} (+${player.correctAnsTotal})',
                                  style: AppTextStyles.scoreSubtitle,
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
    return Column();
  }
}
