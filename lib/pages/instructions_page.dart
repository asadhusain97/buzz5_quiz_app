import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/qBoard_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:buzz5_quiz_app/models/playerProvider.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

const String howToPlayMD = """
  - Enter **unique** player names
  - **Choose a round** on the next page, and the **question board** will load accordingly
  - The board has **5 sets** of **5 questions**, each with varying difficulty and points
  - A **random** player starts _(yellow border indicates the player in control of the board)_  
  - The selected player/ player in control **chooses a question from a set**  
  - **Be quick** to buzz to answer and earn points, but beware of **negative points** for wrong answers  
  - The player **retains control** to pick the next question until another player scores
  """;
const String aboutThisGameMD = """
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
    return BasePage(
      appBar: CustomAppBar(title: "Instructions", showBackButton: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionsPanel(context),
                _buildPlayerFormPanel(context),
              ],
            );
          } else {
            // Mobile/tablet layout
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildInstructionsPanel(context),
                  _buildPlayerFormPanel(context),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInstructionsPanel(BuildContext context) {
    return Expanded(
      flex: 1,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? ColorConstants.darkCardColor
                          : ColorConstants.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primaryContainerColor,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: ColorConstants.surfaceColor,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "How to Play",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.surfaceColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    MarkdownBody(
                      data: howToPlayMD,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? ColorConstants.lightTextColor
                                  : ColorConstants.darkTextColor,
                        ),
                        strong: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? ColorConstants.darkCardColor
                          : ColorConstants.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primaryContainerColor,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ColorConstants.surfaceColor,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "About This Game",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.surfaceColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    MarkdownBody(
                      data: aboutThisGameMD,
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          _launchURL(href);
                        }
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? ColorConstants.lightTextColor
                                  : ColorConstants.darkTextColor,
                        ),
                        a: TextStyle(
                          color: ColorConstants.secondaryContainerColor,
                          decoration: TextDecoration.underline,
                        ),
                        strong: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerFormPanel(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(padding: EdgeInsets.all(24), child: PlayerNameForm()),
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
    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? ColorConstants.darkCardColor
                : ColorConstants.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor,
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  color: ColorConstants.surfaceColor,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  "Enter player names",
                  style: AppTextStyles.titleMedium.copyWith(
                    color: ColorConstants.surfaceColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                // Two-column layout for wider screens
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          PlayerTextField(
                            controller: _player1Controller,
                            playerNumber: 1,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player2Controller,
                            playerNumber: 2,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player3Controller,
                            playerNumber: 3,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player4Controller,
                            playerNumber: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          PlayerTextField(
                            controller: _player5Controller,
                            playerNumber: 5,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player6Controller,
                            playerNumber: 6,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player7Controller,
                            playerNumber: 7,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player8Controller,
                            playerNumber: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Single-column layout for narrower screens
                return Column(
                  children: [
                    PlayerTextField(
                      controller: _player1Controller,
                      playerNumber: 1,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player2Controller,
                      playerNumber: 2,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player3Controller,
                      playerNumber: 3,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player4Controller,
                      playerNumber: 4,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player5Controller,
                      playerNumber: 5,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player6Controller,
                      playerNumber: 6,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player7Controller,
                      playerNumber: 7,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player8Controller,
                      playerNumber: 8,
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 32),
          Container(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                if (_validateUniqueNames()) {
                  _resetGameState(context);
                  _addPlayersToProvider(context);
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
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Player names must be unique',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: ColorConstants.errorContainerColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(12),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: ColorConstants.lightTextColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_filled, size: 28),
                  SizedBox(width: 8),
                  Text("Let's Go!", style: AppTextStyles.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerTextField extends StatelessWidget {
  final TextEditingController controller;
  final int playerNumber;

  const PlayerTextField({
    super.key,
    required this.controller,
    required this.playerNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextFormField(
        controller: controller,
        maxLength: 15,
        style: TextStyle(
          color: ColorConstants.darkTextColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Player $playerNumber',
          hintStyle: TextStyle(
            color: ColorConstants.hintGrey,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.person_rounded,
            color: ColorConstants.primaryColor,
            size: 20,
          ),
          filled: true,
          fillColor: ColorConstants.backgroundColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ColorConstants.tertiaryColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ColorConstants.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }
}
