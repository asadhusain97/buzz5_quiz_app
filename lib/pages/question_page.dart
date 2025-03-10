import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  bool _showAnswer = false;
  late List<String> playerList;
  late String setname;
  late String question;
  late String answer;
  late int score;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    playerList =
        args?['playerNames'] ??
        ["John Doe", "Jane Doe", "Alice", "Bob", "Dk", "Sam", "Vishwakant"];
    setname = args?['setname'] ?? "Sample Set";
    question = args?['question'] ?? "Sample Question?";
    answer = args?['answer'] ?? "Sample Answer";
    score = args?['score'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("Question loaded");

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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Text(question, style: AppTextStyles.titleMedium),
            SizedBox(height: 40),
            SizedBox(
              width: 900,
              height: 200,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      (playerList.length <= 1)
                          ? 1
                          : (playerList.length <= 4)
                          ? 2
                          : (playerList.length <= 6)
                          ? 3
                          : 4,
                  childAspectRatio: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: playerList.length,
                itemBuilder: (context, index) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ToggleIconButton(
                              icon: Icons.check_box, // Customize icon
                              onColor:
                                  ColorConstants
                                      .correctAnsBtn, // Color when toggled ON
                              offColor:
                                  ColorConstants
                                      .ansBtn, // Color when toggled OFF
                              otherAnsSubmitted: true,
                              onToggle: (isOn) {
                                //do something
                              },
                            ),
                            Container(
                              width:
                                  100, // Fixed width to accommodate 15 characters
                              padding: const EdgeInsets.all(4.0),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    playerList[index],
                                    style: AppTextStyles.scoreCard.copyWith(
                                      fontSize: 20, // Set a default font size
                                    ),
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Handle overflow
                                  ),
                                ),
                              ),
                            ),
                            ToggleIconButton(
                              icon: Icons.cancel, // Customize icon
                              onColor:
                                  ColorConstants
                                      .wrongAnsBtn, // Color when toggled ON
                              offColor:
                                  ColorConstants
                                      .ansBtn, // Color when toggled OFF
                              otherAnsSubmitted: false,
                              onToggle: (isOn) {
                                //do something
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
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
  final bool otherAnsSubmitted;
  final ValueChanged<bool>? onToggle;

  const ToggleIconButton({
    super.key,
    required this.icon,
    required this.onColor,
    required this.offColor,
    required this.otherAnsSubmitted,
    this.onToggle,
  });

  @override
  _ToggleIconButtonState createState() => _ToggleIconButtonState();
}

class _ToggleIconButtonState extends State<ToggleIconButton> {
  bool isOn = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isDisabled = widget.otherAnsSubmitted;

    return AnimatedContainer(
      duration: Duration(milliseconds: 20),
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color:
            isDisabled
                ? Colors
                    .grey
                    .shade400 // Completely disabled state
                : isOn
                ? widget
                    .onColor // ON state
                : widget.offColor, // OFF state
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            isDisabled
                ? [] // No shadow when disabled
                : [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: isOn ? 6 : 3,
                    spreadRadius: 1,
                  ),
                ],
      ),
      child:
          isDisabled
              ? Icon(
                widget.icon,
                color: Colors.grey.shade100,
                size: 24,
              ) // Greyed-out icon
              : GestureDetector(
                onTap: () {
                  setState(() {
                    isOn = !isOn;
                  });
                  if (widget.onToggle != null) {
                    widget.onToggle!(isOn);
                  }
                },
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
    );
  }
}
