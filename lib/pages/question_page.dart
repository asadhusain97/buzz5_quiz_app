import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';

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
  late int score;
  late List<String> answerStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    setname = args?['setname'] ?? "Sample Set";
    question = args?['question'] ?? "Sample Question?";
    answer = args?['answer'] ?? "Sample Answer";
    score = args?['score'] ?? 0;

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
          children: [Text(setname), Text('Points: $score')],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(question, style: AppTextStyles.titleMedium),
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
                                            icon:
                                                Icons
                                                    .check_box, // Customize icon
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
                                            icon:
                                                Icons.cancel, // Customize icon
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
            SizedBox(height: 20),
            if (_showAnswer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(answer, style: AppTextStyles.bodyBig),
                  ElevatedButton(
                    onPressed: () {
                      // Done button logic
                    },
                    child: Text("Done"),
                  ),
                ],
              ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

class ToggleIconButton extends StatefulWidget {
  final IconData icon;
  final Color onColor;
  final Color offColor;
  final bool isDisabled;
  final ValueChanged<bool>? onToggle;

  const ToggleIconButton({
    super.key,
    required this.icon,
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
    return IconButton(
      icon: Icon(widget.icon, size: 30),
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
              },
    );
  }
}
