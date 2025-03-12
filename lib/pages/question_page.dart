import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
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
  late List<String> answerStatus;

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

    final playerProvider = Provider.of<PlayerProvider>(context);
    answerStatus = List<String>.filled(playerProvider.playerList.length, "");
  }

  bool isCorrect(int index) {
    return answerStatus[index] == 'correct';
  }

  bool isWrong(int index) {
    return answerStatus[index] == 'wrong';
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
          children: [Text(setname, style: AppTextStyles.titleMedium), Text('Points: $score', style: AppTextStyles.titleMedium)],
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
                  width:
                      playerProvider.playerList.length == 1
                          ? 300
                          : playerProvider.playerList.length == 2
                          ? 500
                          : playerProvider.playerList.length == 3
                          ? 500
                          : playerProvider.playerList.length == 4
                          ? 500
                          : playerProvider.playerList.length == 5
                          ? 700
                          : playerProvider.playerList.length == 6
                          ? 700
                          : 1200,
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
                          return Center(
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                return Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Flexible(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ToggleIconButton(
                                            player:
                                                playerProvider
                                                    .playerList[index],
                                            point: score,
                                            iconType:
                                                "correctAns", // Customize icon
                                            onColor:
                                                ColorConstants
                                                    .correctAnsBtn, // Color when toggled ON
                                            offColor:
                                                ColorConstants
                                                    .ansBtn, // Color when toggled OFF
                                            isDisabled: isWrong(index),
                                            onToggle: (isOn) {
                                              setState(() {
                                                answerStatus[index] =
                                                    isOn ? 'correct' : '';
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
                                                  playerProvider
                                                      .playerList[index]
                                                      .name,
                                                  style:
                                                      AppTextStyles.scoreCard,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis, // Handle overflow
                                                ),
                                              ),
                                            ),
                                          ),
                                          ToggleIconButton(
                                            player:
                                                playerProvider
                                                    .playerList[index],
                                            point: negScore,
                                            iconType:
                                                "wrongAns", // Customize icon
                                            onColor:
                                                ColorConstants
                                                    .wrongAnsBtn, // Color when toggled ON
                                            offColor:
                                                ColorConstants
                                                    .ansBtn, // Color when toggled OFF
                                            isDisabled: isCorrect(index),
                                            onToggle: (isOn) {
                                              setState(() {
                                                answerStatus[index] =
                                                    isOn ? 'wrong' : '';
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                child: Text("Show Answer"),
              ),
            ),
            SizedBox(height: 30),
            if (_showAnswer)
              _buildAnswerSection(),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build content section (question or answer)
  Widget _buildContentSection(String text, String mediaUrl) {
    if (text.isEmpty && mediaUrl.isEmpty) {
      return SizedBox(); // Empty space if no content
    } else if (text.isEmpty && mediaUrl.isNotEmpty) {
      // Only image, center it
      return Center(
        child: SimplerNetworkImage(imageUrl: mediaUrl),
      );
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
  Widget _buildAnswerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Content (text and/or image)
        Container(
          margin: EdgeInsets.only(right: 30), // Space for button
          child: _buildContentSection(answer, ansMedia),
        ),
        
        // Done button always on right
ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Done"),
          ),

      ],
    );
  }
}

class ToggleIconButton extends StatefulWidget {
  final Player player;
  final int point;
  final String iconType;
  final Color onColor;
  final Color offColor;
  final bool isDisabled;
  final ValueChanged<bool>? onToggle;

  const ToggleIconButton({
    super.key,
    required this.player,
    required this.point,
    required this.iconType,
    required this.onColor,
    required this.offColor,
    required this.isDisabled,
    this.onToggle,
  });

  @override
  _ToggleIconButtonState createState() => _ToggleIconButtonState();
}

class _ToggleIconButtonState extends State<ToggleIconButton> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    IconData icon;
    if (widget.iconType == 'correctAns') {
      icon = Icons.check_box;
    } else if (widget.iconType == 'wrongAns') {
      icon = Icons.cancel;
    } else {
      icon = Icons.help; // Default icon if none match
    }

    return IconButton(
      icon: Icon(icon, size: 30),
      color:
          widget.isDisabled
              ? Colors.grey
              : isOn
              ? widget.onColor
              : widget.offColor,
      onPressed:
          widget.isDisabled
              ? null
              : () {
                setState(() {
                  isOn = !isOn;
                });
                if (widget.onToggle != null) {
                  widget.onToggle!(isOn);
                }
                if (isOn) {
                  // Use PlayerProvider to update score instead of direct player manipulation
                  playerProvider.addPointToPlayer(widget.player, widget.point);
                  AppLogger.i("Added ${widget.point} points to ${widget.player.name} via PlayerProvider");
                } else {
                  // Use PlayerProvider to undo points
                  playerProvider.undoLastPointForPlayer(widget.player);
                  AppLogger.i("Undid last point for ${widget.player.name} via PlayerProvider");
                }
              },
    );
  }
}

// Simpler network image without border
class SimplerNetworkImage extends StatelessWidget {
  final String imageUrl;
  
  const SimplerNetworkImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
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
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
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
      builder: (context) => Dialog(
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
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
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
