import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/final_page.dart';
import 'package:buzz5_quiz_app/pages/qBoard_page.dart';
import 'package:buzz5_quiz_app/pages/question_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:buzz5_quiz_app/models/playerProvider.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

const String howToPlayMD = """
  ## How to Play
  - Enter **unique** player names
  - **Choose a round** on the next page, and the **question board** will load accordingly
  - The board has **5 sets** of **5 questions**, each with varying difficulty and points
  - A **random** player starts _(yellow border indicates the player in control of the board)_  
  - The selected player/ player in control **chooses a question from a set**  
  - **Be quick** to buzz to answer and earn points, but beware of **negative points** for wrong answers  
  - The player **retains control** to pick the next question until another player scores
  """;
const String aboutThisGameMD = """
  ## About This Game
  This game is inspired by the **[Buzzing with Kvizzing](https://youtu.be/Tku6Mk5zMjE?si=_zex3Ixa9kQFhGNO)** video series by *Kumar Varun*.

  All **questions and answers** are stored and updated from [**this sheet**](https://docs.google.com/spreadsheets/d/149cG62dE_5H9JYmNYoJ_h0w5exYSFNY-HvX8Yq-HZrI/edit?usp=sharing).
  """;

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppLogger.e('Could not launch $url');
      throw 'Could not launch $url';
    }
    AppLogger.i('Launched URL: $url');
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("InstructionsPage built");
    return Scaffold(
      appBar: CustomAppBar(title: "Instructions", showBackButton: true),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 40,
              bottom: 10,
              right: 10,
              top: 10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: howToPlayMD,
                  selectable: false,
                  styleSheet: MarkdownStyleSheet(
                    h2: AppTextStyles.titleBig,
                    p: AppTextStyles.bodySmall,
                  ),
                ),
                SizedBox(height: 60),
                MarkdownBody(
                  data: aboutThisGameMD,
                  selectable: false,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      _launchURL(href);
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    h2: AppTextStyles.titleBig,
                    p: AppTextStyles.bodySmall,
                  ),
                ),
                SizedBox(height: 60),
                Text(
                  "Get ready, think fast, and have fun! 🎉",
                  style: AppTextStyles.titleBig,
                ),
              ],
            ),
          ),
          Flexible(child: PlayerNameForm()),
        ],
      ),
    );
  }
}

class PlayerNameForm extends StatelessWidget {
  PlayerNameForm({super.key});

  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _player3Controller = TextEditingController();
  final _player4Controller = TextEditingController();
  final _player5Controller = TextEditingController();
  final _player6Controller = TextEditingController();
  final _player7Controller = TextEditingController();
  final _player8Controller = TextEditingController();

  bool _validateUniqueNames() {
    final names =
        [
          _player1Controller.text.trim(),
          _player2Controller.text.trim(),
          _player3Controller.text.trim(),
          _player4Controller.text.trim(),
          _player5Controller.text.trim(),
          _player6Controller.text.trim(),
          _player7Controller.text.trim(),
          _player8Controller.text.trim(),
        ].where((name) => name.isNotEmpty).toList(); // Filter out empty names

    final uniqueNames = names.toSet();
    AppLogger.i("Validating unique names: $names");
    return uniqueNames.length == names.length;
  }

  void _addPlayersToProvider(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final names = [
      _player1Controller.text.trim(),
      _player2Controller.text.trim(),
      _player3Controller.text.trim(),
      _player4Controller.text.trim(),
      _player5Controller.text.trim(),
      _player6Controller.text.trim(),
      _player7Controller.text.trim(),
      _player8Controller.text.trim(),
    ];

    final nonEmptyNames = names.where((name) => name.isNotEmpty).toList();

    if (nonEmptyNames.isEmpty) {
      playerProvider.addPlayer(Player(name: "Lone Ranger"));
      AppLogger.i("Added default player: Lone Ranger");
    } else {
      for (var name in nonEmptyNames) {
        playerProvider.addPlayer(Player(name: name));
        AppLogger.i("Added player: $name");
      }
    }
    playerProvider.setLastPositivePlayer();
  }

  void _resetGameState(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.setPlayerList([]);
    playerProvider.resetAnsweredQuestions();
    AppLogger.i("Game state reset (players and answered questions)");
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("PlayerNameForm built");
    return SizedBox(
      width: 600.0,
      height: 800.0,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          bottom: 150,
          right: 40,
          top: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 0,
                bottom: 0,
                right: 0,
                top: 0,
              ),
              child: Text(
                "Enter player names",
                style: AppTextStyles.titleMedium,
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    PlayerTextField(controller: _player1Controller),
                    SizedBox(height: 10),
                    PlayerTextField(controller: _player2Controller),
                    SizedBox(height: 10),
                    PlayerTextField(controller: _player3Controller),
                    SizedBox(height: 10),
                    PlayerTextField(controller: _player4Controller),
                  ],
                ),
                Column(
                  children: [
                    PlayerTextField(controller: _player5Controller),
                    SizedBox(height: 10),
                    PlayerTextField(controller: _player6Controller),
                    SizedBox(height: 10),
                    PlayerTextField(controller: _player7Controller),
                    SizedBox(height: 10),
                    PlayerTextField(controller: _player8Controller),
                  ],
                ),
              ],
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(
                left: 0,
                bottom: 0,
                right: 0,
                top: 0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_validateUniqueNames()) {
                    _resetGameState(context);
                    _addPlayersToProvider(context);
                    // Record the game start time now
                    Provider.of<PlayerProvider>(
                      context,
                      listen: false,
                    ).setGameStartTime(DateTime.now());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionBoardPage(),
                      ),
                    );
                  } else {
                    AppLogger.w("Player names are not unique");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Player names must be unique',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: Size(250, 60)),
                child: Text("Lets Go!", style: AppTextStyles.buttonTextBig),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerTextField extends StatelessWidget {
  final TextEditingController controller;
  const PlayerTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.0,
      height: 40.0,
      child: TextFormField(
        controller: controller,
        maxLength: 15,
        decoration: InputDecoration(
          hintText: 'Enter player name',
          hintStyle: AppTextStyles.hintText,
          prefixIcon: Icon(Icons.person, size: 20.0),
          fillColor: Colors.white24,
          hoverColor: Colors.white30,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: ColorConstants.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: ColorConstants.secondaryColor),
          ),
          counterText: '',
        ),
      ),
    );
  }
}
