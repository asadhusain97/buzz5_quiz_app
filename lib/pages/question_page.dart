import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/models/questionDone.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/playerProvider.dart';
import 'package:buzz5_quiz_app/models/player.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  bool _showAnswer = false;
  late String setname;
  late String question;
  late String answer;
  late String qstnMedia;
  late String ansMedia;
  late int score;
  late int negScore;
  // Track button states for each player
  Map<String, PlayerButtonState> playerButtonStates = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    setname = args?['setname'] ?? "Sample Set";
    question = args?['question'] ?? "Sample Question?";
    answer = args?['answer'] ?? "Sample Answer";
    qstnMedia = args?['qstn_media'] ?? "";
    ansMedia = args?['ans_media'] ?? "";
    score = args?['score'] ?? 1;
    negScore = score * -1;

    // Initialize button states for each player
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    for (var player in playerProvider.playerList) {
      playerButtonStates[player.name] = PlayerButtonState();
    }

    // Log media URLs for debugging
    if (qstnMedia.isNotEmpty) {
      AppLogger.i("Question loaded with media: qstnMedia='$qstnMedia'");
    }
    if (ansMedia.isNotEmpty) {
      AppLogger.i("Question loaded with media: ansMedia='$ansMedia'");
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("Question loaded");

    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(setname, style: AppTextStyles.titleMedium),
            Text('Points: $score', style: AppTextStyles.titleMedium),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Question section with intelligent layout based on content
            _buildContentSection(question, qstnMedia),
            SizedBox(height: 40),
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  height: 200,
                  width: _calculatePlayerContainerWidth(
                    playerProvider.playerList.length,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 290,
                          childAspectRatio: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent:
                              50, // Specify the minimum height for the child
                        ),
                        itemCount: playerProvider.playerList.length,
                        shrinkWrap: true,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final player = playerProvider.playerList[index];
                          final buttonState = playerButtonStates[player.name]!;
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildToggleButton(
                                    isOn: buttonState.correctActive,
                                    isDisabled: buttonState.wrongActive,
                                    iconData: Icons.check_box,
                                    onColor: ColorConstants.correctAnsBtn,
                                    offColor: ColorConstants.ansBtn,
                                    onPressed: () {
                                      setState(() {
                                        if (buttonState.correctActive) {
                                          // Toggle off
                                          buttonState.correctActive = false;
                                          playerProvider.undoLastPointForPlayer(
                                            player,
                                          );
                                        } else {
                                          // Toggle on
                                          buttonState.correctActive = true;
                                          playerProvider.addPointToPlayer(
                                            player,
                                            score,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 2,
                                        right: 2,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          player.name,
                                          style: AppTextStyles.scoreCard,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildToggleButton(
                                    isOn: buttonState.wrongActive,
                                    isDisabled: buttonState.correctActive,
                                    iconData: Icons.cancel,
                                    onColor: ColorConstants.wrongAnsBtn,
                                    offColor: ColorConstants.ansBtn,
                                    onPressed: () {
                                      setState(() {
                                        if (buttonState.wrongActive) {
                                          // Toggle off
                                          buttonState.wrongActive = false;
                                          playerProvider.undoLastPointForPlayer(
                                            player,
                                          );
                                        } else {
                                          // Toggle on
                                          buttonState.wrongActive = true;
                                          playerProvider.addPointToPlayer(
                                            player,
                                            negScore,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Show answer logic
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                style: ElevatedButton.styleFrom(minimumSize: Size(150, 40)),
                child: Text("Show Answer"),
              ),
            ),
            SizedBox(height: 30),
            if (_showAnswer) _buildAnswerSection(answer, ansMedia),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // Helper method to build content section (question or answer)
  Widget _buildContentSection(String text, String mediaUrl) {
    if (text.isEmpty && mediaUrl.isEmpty) {
      return Text("I have no question for you.."); // Empty space if no content
    } else if (text.isEmpty && mediaUrl.isNotEmpty) {
      // Only image, center it
      return Center(child: SimplerNetworkImage(imageUrl: mediaUrl));
    } else if (text.isNotEmpty && mediaUrl.isEmpty) {
      // Only text, center it
      return Center(
        child: Text(
          text,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      // Both text and image, show side by side with 50 spacing
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 50), // Fixed 50 spacing
          SimplerNetworkImage(imageUrl: mediaUrl),
        ],
      );
    }
  }

  // Helper method to build the answer section with "Done" button
  Widget _buildAnswerSection(String text, String mediaUrl) {
    if (text.isEmpty && mediaUrl.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("I have no answer for you.."),
          SizedBox(width: 50),
          DoneButton(context: context),
        ],
      );
    } else if (text.isEmpty && mediaUrl.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SimplerNetworkImage(imageUrl: mediaUrl),
          SizedBox(width: 50),
          DoneButton(context: context),
        ],
      );
    } else if (text.isNotEmpty && mediaUrl.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: 50),
          DoneButton(context: context),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SimplerNetworkImage(imageUrl: mediaUrl),
        SizedBox(width: 50),
        Text(
          text,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(width: 50),
        DoneButton(context: context),
      ],
    );
  }

  Widget _buildToggleButton({
    required bool isOn,
    required bool isDisabled,
    required IconData iconData,
    required Color onColor,
    required Color offColor,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(iconData, size: 30),
      color: isDisabled ? Colors.grey : (isOn ? onColor : offColor),
      onPressed: isDisabled ? null : onPressed,
    );
  }

  double _calculatePlayerContainerWidth(int playerCount) {
    if (playerCount <= 1) return 300;
    if (playerCount <= 4) return 500;
    if (playerCount <= 6) return 700;
    return 1200;
  }
}

// Simple class to track button states for each player
class PlayerButtonState {
  bool correctActive = false;
  bool wrongActive = false;
}

class DoneButton extends StatelessWidget {
  const DoneButton({super.key, required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    // Extract the questionId from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String questionId = args?['qid'] ?? "";

    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: Size(150, 40)),
      onPressed: () {
        if (questionId.isNotEmpty) {
          // Mark this question as answered
          Provider.of<AnsweredQuestionsProvider>(
            context,
            listen: false,
          ).markQuestionAsAnswered(questionId);

          AppLogger.i("Question $questionId marked as answered");
        }
        // Return to previous screen
        Navigator.of(context).pop();
      },
      child: Text("Done"),
    );
  }
}

// Simpler network image without border
class SimplerNetworkImage extends StatelessWidget {
  final String imageUrl;

  const SimplerNetworkImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return SizedBox(
        height: 150,
        width: 150,
        child: Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, imageUrl);
      },
      child: SizedBox(
        height: 150,
        width: 150,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            AppLogger.e(
              "Failed to load image from URL: $imageUrl, error: $error",
            );
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with pinch to zoom
                  InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                  // Close button
                  Positioned(
                    top: 20,
                    right: 20,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
