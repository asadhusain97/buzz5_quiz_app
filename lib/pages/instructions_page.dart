import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/q_board_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
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
                _buildActionPanel(context),
              ],
            );
          } else {
            // Mobile/tablet layout
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildInstructionsPanel(context),
                  _buildActionPanel(context),
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

  Widget _buildActionPanel(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: EdgeInsets.all(24),
        child: Center(
          child: _buildLetsGoButton(context),
        ),
      ),
    );
  }

  Widget _buildLetsGoButton(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 300),
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
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rocket_launch,
            color: ColorConstants.primaryColor,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            "Ready to Start?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstants.surfaceColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Create a room for players to join",
            style: TextStyle(
              fontSize: 14,
              color: ColorConstants.lightTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
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

                // Reset game state - start with empty player list
                playerProvider.setPlayerList([]);
                playerProvider.resetAnsweredQuestions();
                AppLogger.i("Game state reset - starting with empty player list");

                // Always create a room (hosting is mandatory)
                final success = await roomProvider.createRoom();

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

                // Set game start time
                playerProvider.setGameStartTime(DateTime.now());

                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => QuestionBoardPage(),
                  ),
                );
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
