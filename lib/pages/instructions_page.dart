import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/q_board_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buzz5_quiz_app/models/player.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
import 'package:buzz5_quiz_app/models/room_provider.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

const String howToPlayMD = """
  Who is a Reader? YOU. (The person who'll act as Quiz Emcee, and will conduct the quiz and 'read' the questions)
  - Enter unique player names
  - Create a Game on a **[Buzzer app](https://buzzin.live/)** and get all the players to join 
  - On the next page, 'Select a Board' and the questions will load accordingly
  - Each Board has 5 sets of 5 questions; each with increasing difficulty from 10 to 50 points
  - Click on the set name to learn about what the set means and see example question (if available)
  - A random player starts the game (Green border indicates the player in control of the board)
  - The player in control chooses a question tile. (All questions are open for everyone for answering)
  - A player retains control to pick the next question, until another player scores
  - Wrong answers get negative points
  - The reader/Quiz Emcee can grant part points to players by clicking on their name during a specific question
  """;
const String aboutThisGameMD = """
  This game is inspired by the **[Buzzing with Kvizzing](https://youtu.be/Tku6Mk5zMjE?si=_zex3Ixa9kQFhGNO)** video series by *Kumar Varun*.

  All **questions and answers** are stored and updated from [**this sheet**](https://docs.google.com/spreadsheets/d/149cG62dE_5H9JYmNYoJ_h0w5exYSFNY-HvX8Yq-HZrI/edit?usp=sharing).
  Another option to submit your sets is to fill this [google form](https://docs.google.com/forms/d/e/1FAIpQLSfG_o2qm05MU1upotKMPmZIeILzn8RnaWdST0f56JaQ_NLueA/viewform). 
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
      appBar: CustomAppBar(title: "Set up", showBackButton: true),
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
                          "Instructions for the Reader",
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
      child: SingleChildScrollView(
        child: Container(padding: EdgeInsets.all(24), child: PlayerNameForm()),
      ),
    );
  }
}

class PlayerNameForm extends StatefulWidget {
  const PlayerNameForm({super.key});

  @override
  State<PlayerNameForm> createState() => _PlayerNameFormState();
}

class _PlayerNameFormState extends State<PlayerNameForm> {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _player3Controller = TextEditingController();
  final _player4Controller = TextEditingController();
  final _player5Controller = TextEditingController();
  final _player6Controller = TextEditingController();
  final _player7Controller = TextEditingController();
  final _player8Controller = TextEditingController();
  final _player9Controller = TextEditingController();
  final _player10Controller = TextEditingController();

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
          _player9Controller.text.trim(),
          _player10Controller.text.trim(),
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
      _player9Controller.text.trim(),
      _player10Controller.text.trim(),
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
          // Room Configuration Section
          Consumer<RoomProvider>(
            builder: (context, roomProvider, child) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstants.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.doorbell,
                      color: ColorConstants.primaryColor,
                      size: 36,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Host a Room",
                            style: AppTextStyles.titleSmall.copyWith(
                              color: ColorConstants.surfaceColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Create a room for others to join with a buzzer",
                            style: TextStyle(
                              color: ColorConstants.lightTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: roomProvider.hostRoom,
                      onChanged: (value) {
                        roomProvider.setHostRoom(value);
                      },
                      activeColor: ColorConstants.primaryColor,
                      activeTrackColor: ColorConstants.primaryColor.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 24),
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
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player5Controller,
                            playerNumber: 5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
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
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player9Controller,
                            playerNumber: 9,
                          ),
                          SizedBox(height: 16),
                          PlayerTextField(
                            controller: _player10Controller,
                            playerNumber: 10,
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
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player9Controller,
                      playerNumber: 9,
                    ),
                    SizedBox(height: 16),
                    PlayerTextField(
                      controller: _player10Controller,
                      playerNumber: 10,
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final roomProvider = Provider.of<RoomProvider>(
                  context,
                  listen: false,
                );
                final playerProvider = Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                );
                
                if (_validateUniqueNames()) {
                  _resetGameState(context);
                  
                  // Create room if hosting is enabled
                  if (roomProvider.hostRoom) {
                    // When hosting a room, don't add players to local list yet
                    // They will be added when they join the room
                    // Get the player names to store for validation
                    final playerNames = [
                      _player1Controller.text.trim(),
                      _player2Controller.text.trim(),
                      _player3Controller.text.trim(),
                      _player4Controller.text.trim(),
                      _player5Controller.text.trim(),
                      _player6Controller.text.trim(),
                      _player7Controller.text.trim(),
                      _player8Controller.text.trim(),
                      _player9Controller.text.trim(),
                      _player10Controller.text.trim(),
                    ].where((name) => name.isNotEmpty).toList();
                    
                    final success = await roomProvider.createRoom(
                      hostPlayerNames: playerNames.isNotEmpty ? playerNames : null,
                    );
                    if (!mounted) return;
                    if (!success && roomProvider.error != null) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline, 
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  roomProvider.error!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
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
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      );
                      return;
                    }
                  } else {
                    // Not hosting a room, add players to local list as before
                    _addPlayersToProvider(context);
                  }

                  // Set game start time for both hosting and non-hosting scenarios
                  playerProvider.setGameStartTime(DateTime.now());

                  if (mounted) {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => QuestionBoardPage(),
                      ),
                    );
                  }
                } else {
                  AppLogger.w("Player names are not unique");
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Player names must be unique',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          SizedBox(
            height: 24,
          ), // Extra bottom padding to ensure button is always accessible
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
    return TextFormField(
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
          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: '',
      ),
    );
  }
}
