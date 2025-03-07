import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/constants.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class QuestionBoardPage extends StatelessWidget {
  const QuestionBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.i("QuestionBoardPage built");
    return Scaffold(
      appBar: CustomAppBar(title: "Question Board", showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Consumer<PlayerProvider>(
                builder: (context, playerProvider, child) {
                  AppLogger.i(
                    "Player list updated: ${playerProvider.playerList}",
                  );
                  return ListView.builder(
                    itemCount: playerProvider.playerList.length,
                    itemBuilder: (context, index) {
                      final player = playerProvider.playerList[index];
                      return ListTile(
                        title: Text(
                          player.name,
                          style: AppTextStyles.bodySmall,
                        ),
                        subtitle: Text(
                          'Score: ${player.score}',
                          style: AppTextStyles.caption,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
