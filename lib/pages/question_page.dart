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
  late dynamic answer;
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
              iconSize: 26,
            ),
          ),
        ],
        backgroundColor: Color(0x00000000),
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
            _buildQuestionSection(question, qstnMedia),
            SizedBox(height: 40),
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  height: 200,
                  width: _calculatePlayerBoardContainerWidth(
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
                                  ToggleButton(
                                    key: ValueKey('correct_${player.name}'),
                                    initialOn: buttonState.correctOn,
                                    isDisabled: buttonState.correctDisabled,
                                    iconData: Icons.check,
                                    onColor: ColorConstants.correctAnsBtn,
                                    offColor: ColorConstants.ansBtn,
                                    onToggle: (isOn) {
                                      // force update the UI
                                      setState(() {
                                        buttonState.setCorrect(isOn);
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
                                  ToggleButton(
                                    key: ValueKey('wrong_${player.name}'),
                                    initialOn: buttonState.wrongOn,
                                    isDisabled: buttonState.wrongDisabled,
                                    iconData: Icons.cancel_outlined,
                                    onColor: ColorConstants.wrongAnsBtn,
                                    offColor: ColorConstants.ansBtn,
                                    onToggle: (isOn) {
                                      // force update the UI
                                      setState(() {
                                        buttonState.setWrong(isOn);
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
  Widget _buildQuestionSection(dynamic text, String mediaUrl) {
    String displayText = text.toString(); // Convert text to string if it's not

    if (displayText.isEmpty && mediaUrl.isEmpty) {
      return Text("I have no question for you.."); // Empty space if no content
    } else if (displayText.isEmpty && mediaUrl.isNotEmpty) {
      // Only image, center it
      return Center(child: SimplerNetworkImage(imageUrl: mediaUrl));
    } else if (displayText.isNotEmpty && mediaUrl.isEmpty) {
      // Only text, center it
      return Center(
        child: Text(
          displayText,
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
          Text(
            displayText,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: 50), // Fixed 50 spacing
          SimplerNetworkImage(imageUrl: mediaUrl),
        ],
      );
    }
  }

  // Helper method to build the answer section with "Done" button
  Widget _buildAnswerSection(dynamic text, String mediaUrl) {
    String displayText = text.toString(); // Convert text to string if it's not
    if (displayText.isEmpty && mediaUrl.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("I have no answer for you.."),
          SizedBox(width: 50),
          DoneButton(
            context: context,
            playerButtonStates: playerButtonStates,
            score: score,
            negScore: negScore,
          ),
        ],
      );
    } else if (displayText.isEmpty && mediaUrl.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SimplerNetworkImage(imageUrl: mediaUrl),
          SizedBox(width: 50),
          DoneButton(
            context: context,
            playerButtonStates: playerButtonStates,
            score: score,
            negScore: negScore,
          ),
        ],
      );
    } else if (displayText.isNotEmpty && mediaUrl.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayText,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: 50),
          DoneButton(
            context: context,
            playerButtonStates: playerButtonStates,
            score: score,
            negScore: negScore,
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SimplerNetworkImage(imageUrl: mediaUrl),
        SizedBox(width: 50),
        Text(
          displayText,
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(width: 50),
        DoneButton(
          context: context,
          playerButtonStates: playerButtonStates,
          score: score,
          negScore: negScore,
        ),
      ],
    );
  }

  double _calculatePlayerBoardContainerWidth(int playerCount) {
    if (playerCount <= 1) return 300;
    if (playerCount <= 4) return 500;
    if (playerCount <= 6) return 700;
    return 1200;
  }
}

// Simple class to track button states for each player
class PlayerButtonState {
  bool correctOn = false;
  bool wrongOn = false;
  bool correctDisabled = false;
  bool wrongDisabled = false;

  // Reset all states
  void reset() {
    correctOn = false;
    wrongOn = false;
    correctDisabled = false;
    wrongDisabled = false;
  }

  // Set correct answer
  void setCorrect(bool isOn) {
    correctOn = isOn;
    wrongDisabled = isOn; // When correct is on, wrong is disabled

    // If correct is being turned off, make sure wrong is enabled
    if (!isOn) {
      wrongDisabled = false;
    }
  }

  // Set wrong answer
  void setWrong(bool isOn) {
    wrongOn = isOn;
    correctDisabled = isOn; // When wrong is on, correct is disabled

    // If wrong is being turned off, make sure correct is enabled
    if (!isOn) {
      correctDisabled = false;
    }
  }
}

class DoneButton extends StatelessWidget {
  const DoneButton({
    super.key,
    required this.context,
    required this.playerButtonStates,
    required this.score,
    required this.negScore,
  });

  final BuildContext context;
  final Map<String, PlayerButtonState> playerButtonStates;
  final int score;
  final int negScore;

  @override
  Widget build(BuildContext context) {
    // Extract the questionId from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String questionId = args?['qid'] ?? "";

    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: Size(150, 40)),
      onPressed: () {
        // Process all player scores based on button states
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );

        // Update scores for all players
        for (final player in playerProvider.playerList) {
          final buttonState = playerButtonStates[player.name];
          if (buttonState != null) {
            if (buttonState.correctOn) {
              // Add positive points for correct answer
              playerProvider.addPointToPlayer(player, score);
              AppLogger.i("Added $score points to ${player.name}");
            } else if (buttonState.wrongOn) {
              // Add negative points for wrong answer
              playerProvider.addPointToPlayer(player, negScore);
              AppLogger.i("Added $negScore points to ${player.name}");
            }
          }
        }

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
        _showImageOverlay(context, imageUrl);
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
        ),
      ),
    );
  }

  void _showImageOverlay(BuildContext context, String imageUrl) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final Size screenSize = MediaQuery.of(context).size;
        final double maxWidth = screenSize.width * 0.8;
        final double maxHeight = screenSize.height * 0.8;

        return Stack(
          children: [
            // Transparent background; tap to remove overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () => overlayEntry.remove(),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Image container centered on screen
            Center(
              child: Container(
                width: maxWidth,
                height: maxHeight,
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10.0),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Stack(
                    children: [
                      // Zoom-able image wrapped in Center to ensure it is centered
                      InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Center(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Close button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () => overlayEntry.remove(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlayState.insert(overlayEntry);
  }
}
// New stateful widget: ToggleButton

class ToggleButton extends StatefulWidget {
  final bool initialOn;
  final bool isDisabled;
  final IconData iconData;
  final Color onColor;
  final Color offColor;
  final ValueChanged<bool>? onToggle; // returns the new isOn value

  const ToggleButton({
    Key? key,
    this.initialOn = false,
    this.isDisabled = false,
    required this.iconData,
    required this.onColor,
    required this.offColor,
    this.onToggle,
  }) : super(key: key);

  @override
  _ToggleButtonState createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.initialOn;
  }

  @override
  void didUpdateWidget(covariant ToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update internal state when props change
    if (widget.initialOn != oldWidget.initialOn) {
      setState(() {
        _isOn = widget.initialOn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(widget.iconData, size: 30),
      color:
          widget.isDisabled
              ? Colors.grey
              : (_isOn ? widget.onColor : widget.offColor),
      onPressed:
          widget.isDisabled
              ? null
              : () {
                final newState = !_isOn;
                setState(() {
                  _isOn = newState;
                });
                if (widget.onToggle != null) widget.onToggle!(newState);
              },
    );
  }
}
