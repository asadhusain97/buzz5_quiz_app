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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: [
                  RoundDropDown(),
                  SizedBox(height: 50),
                  Leaderboard(),
                  SizedBox(height: 60),
                  EndGameButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundDropDown extends StatelessWidget {
  const RoundDropDown({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Choose Round:', style: AppTextStyles.bodyBig),
        SizedBox(width: 20),
        DropdownButton<String>(
          items:
              <String>['Round 1', 'Round 2', 'Round 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (_) {},
        ),
        SizedBox(width: 10),
        IconButton(onPressed: () {}, icon: Icon(Icons.arrow_forward)),
      ],
    );
  }
}

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        AppLogger.i("Player list updated: ${playerProvider.playerList}");
        return SingleChildScrollView(
          child: SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Leaderboard', style: AppTextStyles.titleMedium),
                SizedBox(height: 20.0),
                SizedBox(
                  width: 180.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: playerProvider.playerList.length,
                    itemBuilder: (context, index) {
                      final player = playerProvider.playerList[index];
                      final isLastPositivePlayer =
                          playerProvider.lastPositivePlayer == player;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isLastPositivePlayer
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(player.name, style: AppTextStyles.body),
                            Text(
                              '${player.score}',
                              style: AppTextStyles.bodyBig,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EndGameButton extends StatelessWidget {
  const EndGameButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // Add your end game logic here
        },
        style: ElevatedButton.styleFrom(minimumSize: Size(200, 60)),
        icon: Icon(Icons.emoji_events),
        label: Text('End Game', style: AppTextStyles.buttonTextSmall),
      ),
    );
  }
}
