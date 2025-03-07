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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [QuestionBoardContent()],
        ),
      ),
    );
  }
}

class QuestionBoardContent extends StatefulWidget {
  const QuestionBoardContent({super.key});

  @override
  _QuestionBoardContentState createState() => _QuestionBoardContentState();
}

class _QuestionBoardContentState extends State<QuestionBoardContent> {
  String? selectedRound;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Row(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  RoundDropDown(
                    selectedRound: selectedRound,
                    onRoundSelected: (String? round) {
                      setState(() {
                        selectedRound = round;
                      });
                    },
                  ),
                  SizedBox(height: 50),
                  if (selectedRound != null) ...[
                    Leaderboard(),
                    SizedBox(height: 60),
                    EndGameButton(),
                  ],
                ],
              ),
            ),
            if (selectedRound != null) ...[SizedBox(width: 50)],
            if (selectedRound != null) ...[
              SizedBox(
                width: 800,
                height: 800,
                child: Column(children: [SetNames()]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class RoundDropDown extends StatelessWidget {
  final String? selectedRound;
  final Function(String?) onRoundSelected;

  const RoundDropDown({
    super.key,
    required this.selectedRound,
    required this.onRoundSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(height: 30),
        Text('Choose Round:', style: AppTextStyles.bodyBig),
        SizedBox(width: 20),
        DropdownButton<String>(
          hint: Text('...'),
          value: selectedRound,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          items:
              <String>['Round 1', 'Round 2', 'Round 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (String? newValue) {
            onRoundSelected(newValue);
          },
        ),
        if (selectedRound != null) ...[
          SizedBox(width: 10),
          IconButton(onPressed: () {}, icon: Icon(Icons.arrow_forward)),
        ],
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

class SetNames extends StatelessWidget {
  const SetNames({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Row(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(child: Text('Box ${index + 1}')),
              ),
              SizedBox(width: 30.0),
            ],
          );
        },
      ),
    );
  }
}
