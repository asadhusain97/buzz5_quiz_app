import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/providers/question_done.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

// BuzzerEntry class to track player buzzer data
class BuzzerEntry {
  final String playerId;
  final String playerName;
  final int timestamp;
  final int questionNumber;
  final int position;

  BuzzerEntry({
    required this.playerId,
    required this.playerName,
    required this.timestamp,
    required this.questionNumber,
    required this.position,
  });
}

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  // Track custom award points per player for this question
  Map<String, int> customAwardPoints = {};

  // Timer and Firebase functionality
  Timer? _questionTimer;
  int _elapsedSeconds = 0;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _currentRoomId;

  // Buzzer functionality
  List<BuzzerEntry> _buzzerEntries = [];
  StreamSubscription? _buzzerSubscription;

  // Timer management methods
  void _startTimer() {
    _elapsedSeconds = 0;
    _questionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
    AppLogger.i("Question timer started");
  }

  void _stopTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
    AppLogger.i("Question timer stopped at $_elapsedSeconds seconds");
  }

  // Firebase question state management
  Future<void> _startQuestion() async {
    if (_currentRoomId == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final questionRef = _database
          .child('rooms')
          .child(_currentRoomId!)
          .child('currentQuestion');

      // Set question as active with start time and full question data
      await questionRef.set({
        'isActive': true,
        'startTime': timestamp,
        'questionId': 'q_$timestamp', // Simple question ID
        // Include full question data for host control panel
        'setName': setname,
        'question': question,
        'answer': answer,
        'points': score,
        'qstnMedia': qstnMedia,
        'ansMedia': ansMedia,
      });

      // Clear current question buzzes
      await _database
          .child('rooms')
          .child(_currentRoomId!)
          .child('currentQuestionBuzzes')
          .remove();

      // Start listening to buzzer entries
      _startListeningToBuzzers();

      AppLogger.i(
        "Question started in room $_currentRoomId at timestamp $timestamp",
      );
    } catch (e) {
      AppLogger.e("Error starting question: $e");
    }
  }

  Future<void> _endQuestion() async {
    if (_currentRoomId == null) return;

    try {
      await _database
          .child('rooms')
          .child(_currentRoomId!)
          .child('currentQuestion')
          .child('isActive')
          .set(false);

      AppLogger.i("Question ended in room $_currentRoomId");
    } catch (e) {
      AppLogger.e("Error ending question: $e");
    }
  }

  // Format timer display
  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Method to show award point edit dialog
  void _showAwardPointDialog(String playerName) {
    final TextEditingController controller = TextEditingController();
    controller.text =
        customAwardPoints[playerName]?.toString() ?? score.toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Stack(
            children: [
              // Transparent background that can be tapped to close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: ColorConstants.transparent,
                  child: SizedBox.expand(),
                ),
              ),
              // Actual dialog content
              Center(
                child: Material(
                  color: ColorConstants.transparent,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 200, maxWidth: 500),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorConstants.darkCardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.overlayMedium,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Change reward points for $playerName',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: ColorConstants.lightTextColor,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close,
                                color: ColorConstants.lightTextColor,
                              ),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^-?\d*'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: ColorConstants.tertiaryColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: ColorConstants.tertiaryColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: ColorConstants.primaryColor,
                                    ),
                                  ),
                                  hintText: 'Points',
                                  hintStyle: TextStyle(
                                    color: ColorConstants.hintGrey,
                                  ),
                                  filled: true,
                                  fillColor: ColorConstants.surfaceColor,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                style: AppTextStyles.body.copyWith(
                                  color: ColorConstants.darkTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 20),
                            SizedBox(
                              width: 100, // Fixed width for the button
                              height: 48, // Match text field height
                              child: ElevatedButton(
                                onPressed: () {
                                  final points =
                                      int.tryParse(controller.text) ?? score;
                                  setState(() {
                                    customAwardPoints[playerName] = points;
                                  });
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstants.primaryColor,
                                  foregroundColor:
                                      ColorConstants.lightTextColor,
                                ),
                                child: Text('Done'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Start the timer immediately
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    _endQuestion();
    _buzzerSubscription?.cancel();
    super.dispose();
  }

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

    // Initialize button states for each player (only if they don't exist)
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    for (var player in playerProvider.playerList) {
      if (!playerButtonStates.containsKey(player.name)) {
        playerButtonStates[player.name] = PlayerButtonState();
      }
    }

    // Get current room ID and start question
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    if (roomProvider.hasActiveRoom && _currentRoomId == null) {
      _currentRoomId = roomProvider.currentRoom?.roomId;
      if (_currentRoomId != null) {
        _startQuestion();
      }
    }

    // Log media URLs for debugging
    if (qstnMedia.isNotEmpty) {
      AppLogger.i("Question loaded with media: qstnMedia='$qstnMedia'");
    }
    if (ansMedia.isNotEmpty) {
      AppLogger.i("Question loaded with media: ansMedia='$ansMedia'");
    }
  }

  // Start listening to buzzer entries in Firebase
  void _startListeningToBuzzers() {
    if (_currentRoomId == null) return;

    _buzzerSubscription?.cancel();

    final buzzersRef = _database
        .child('rooms')
        .child(_currentRoomId!)
        .child('currentQuestionBuzzes')
        .orderByChild('timestamp');

    AppLogger.i(
      "Starting to listen for buzzer entries in room: $_currentRoomId",
    );

    _buzzerSubscription = buzzersRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      final newBuzzerEntries = <BuzzerEntry>[];

      if (data != null && data is Map) {
        final buzzersMap = Map<String, dynamic>.from(data);
        for (final entry in buzzersMap.entries) {
          final playerId = entry.key;
          final buzzerData = Map<String, dynamic>.from(entry.value);
          final buzzerEntry = BuzzerEntry(
            playerId: buzzerData['playerId'] ?? playerId,
            playerName: buzzerData['playerName'] ?? 'Unknown',
            timestamp: buzzerData['timestamp'] ?? 0,
            questionNumber: 1, // Default question number
            position: buzzerData['position'] ?? 0,
          );
          newBuzzerEntries.add(buzzerEntry);
        }
      }

      // Sort by timestamp (fastest first)
      newBuzzerEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update positions based on sorted order
      for (int i = 0; i < newBuzzerEntries.length; i++) {
        newBuzzerEntries[i] = BuzzerEntry(
          playerId: newBuzzerEntries[i].playerId,
          playerName: newBuzzerEntries[i].playerName,
          timestamp: newBuzzerEntries[i].timestamp,
          questionNumber: newBuzzerEntries[i].questionNumber,
          position: i + 1,
        );
      }

      // Track first hits: if we have new buzzer entries and the first one is new
      if (newBuzzerEntries.isNotEmpty) {
        final firstBuzzer = newBuzzerEntries.first;
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        final firstPlayer = playerProvider.getPlayerByName(
          firstBuzzer.playerName,
        );

        // Only increment if this is a new first buzzer (position 1)
        if (firstPlayer != null && firstBuzzer.position == 1) {
          // Check if this is a new first buzzer by comparing with previous state
          final wasFirstBefore =
              _buzzerEntries.isNotEmpty &&
              _buzzerEntries.first.playerName == firstBuzzer.playerName;

          if (!wasFirstBefore) {
            playerProvider.incrementFirstHits(firstPlayer);
            AppLogger.i(
              "Incremented first hits for first buzzer: ${firstBuzzer.playerName}",
            );
          }
        }
      }

      setState(() {
        _buzzerEntries = newBuzzerEntries;
      });

      AppLogger.i("Buzzer entries updated: ${_buzzerEntries.length} entries");
    });
  }

  // Get buzzer entry for a specific player
  BuzzerEntry? _getBuzzerEntryForPlayer(String playerName) {
    try {
      return _buzzerEntries.firstWhere(
        (entry) => entry.playerName == playerName,
      );
    } catch (e) {
      return null;
    }
  }

  // Get ranking color based on colors.dart temperature system
  Color _getRankingColor(int position) {
    switch (position) {
      case 1:
        return ColorConstants.rank1Color; // Hot red - 1st place
      case 2:
        return ColorConstants.rank2Color; // Orange - 2nd place
      case 3:
        return ColorConstants.rank3Color; // Yellow - 3rd place
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return ColorConstants.championTierColor; // Light green - ranks 4-10
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
        return ColorConstants.veteranTierColor; // Cyan - ranks 11-25
      default:
        return ColorConstants.challengerTierColor; // Cool blue - ranks 26+
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
        backgroundColor: ColorConstants.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Set name (left)
            Text(setname, style: AppTextStyles.titleMedium),

            // Timer (center)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConstants.secondaryContainerColor.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorConstants.secondaryContainerColor.withValues(
                    alpha: 0.5,
                  ),
                  width: 1,
                ),
              ),
              child: Text(
                _formatTimer(_elapsedSeconds),
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.secondaryContainerColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),

            // Points (right)
            Text('Points: $score', style: AppTextStyles.titleMedium),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Question section with intelligent layout based on content
                SizedBox(height: 40),
                _buildQuestionSection(question, qstnMedia),
                SizedBox(height: 40),
                _playerGrid(playerProvider),
                SizedBox(height: 30),
                _showAnswerButton(),
                SizedBox(height: 30),
                if (_showAnswer) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildAnswerSection(answer, ansMedia),
                  ),
                  SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Center _showAnswerButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Show answer logic
          setState(() {
            _showAnswer = !_showAnswer;
          });
        },
        style: ElevatedButton.styleFrom(
          minimumSize: Size(180, 60),
          backgroundColor: ColorConstants.primaryContainerColor,
        ),
        child: Text(
          "Show Answer",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.surfaceColor,
          ),
        ),
      ),
    );
  }

  Center _playerGrid(PlayerProvider playerProvider) {
    // Return empty container if no players
    if (playerProvider.playerList.isEmpty) {
      return Center(child: SizedBox.shrink());
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _calculatePlayerBoardContainerWidth(
              playerProvider.playerList.length,
            ),
          ),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 290,
              childAspectRatio: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 50, // Each row is 50 high
            ),
            itemCount: playerProvider.playerList.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final player = playerProvider.playerList[index];
              final buttonState = playerButtonStates[player.name]!;
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ColorConstants.primaryContainerColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ToggleButton(
                        key: ValueKey('correct_${player.name}'),
                        initialOn: buttonState.correctOn,
                        isDisabled: buttonState.correctDisabled,
                        iconData: Icons.check,
                        onColor: ColorConstants.correctAnsBtn,
                        offColor: ColorConstants.cardColor,
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
                          padding: EdgeInsets.only(left: 2, right: 2),
                          child: _PlayerNameWithRank(
                            player: player,
                            buzzerEntry: _getBuzzerEntryForPlayer(player.name),
                            onEditTap: () => _showAwardPointDialog(player.name),
                          ),
                        ),
                      ),
                      ToggleButton(
                        key: ValueKey('wrong_${player.name}'),
                        initialOn: buttonState.wrongOn,
                        isDisabled: buttonState.wrongDisabled,
                        iconData: Icons.cancel_outlined,
                        onColor: ColorConstants.wrongAnsBtn,
                        offColor: ColorConstants.cardColor,
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
        ),
      ),
    );
  }

  // Helper method to build content section (question or answer)
  Widget _buildQuestionSection(dynamic text, String mediaUrl) {
    String displayText = text.toString(); // Convert text to string if it's not

    // Define consistent maximum width for the entire question section
    const double maxSectionWidth = 800.0;
    const double maxTextWidth = 600.0;

    if (displayText.isEmpty && mediaUrl.isEmpty) {
      // Case 1: Nothing - show default message in centered container
      return Container(
        constraints: BoxConstraints(maxWidth: maxSectionWidth),
        child: Center(
          child: Text(
            "I have no question for you..",
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (displayText.isEmpty && mediaUrl.isNotEmpty) {
      // Case 2: Only image - center the image in consistent container
      return Container(
        constraints: BoxConstraints(maxWidth: maxSectionWidth),
        child: Center(child: SimplerNetworkImage(imageUrl: mediaUrl)),
      );
    } else if (displayText.isNotEmpty && mediaUrl.isEmpty) {
      // Case 3: Only text - text with proper wrapping in centered container
      return Container(
        constraints: BoxConstraints(maxWidth: maxSectionWidth),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxTextWidth),
            child: Text(
              displayText,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
    } else {
      // Case 4: Both text and image - side by side with proper text wrapping
      return Container(
        constraints: BoxConstraints(maxWidth: maxSectionWidth),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text container with flexible width
              Flexible(
                flex: 1,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxTextWidth),
                  child: Text(
                    displayText,
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              SizedBox(width: 50), // Fixed spacing
              // Image container
              SimplerNetworkImage(imageUrl: mediaUrl),
            ],
          ),
        ),
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
            customAwardPoints: customAwardPoints,
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
            customAwardPoints: customAwardPoints,
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
            customAwardPoints: customAwardPoints,
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
          customAwardPoints: customAwardPoints,
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
    required this.customAwardPoints,
  });

  final BuildContext context;
  final Map<String, PlayerButtonState> playerButtonStates;
  final int score;
  final int negScore;
  final Map<String, int> customAwardPoints;

  @override
  Widget build(BuildContext context) {
    // Extract the questionId from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String questionId = args?['qid'] ?? "";

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(120, 60),
        backgroundColor: ColorConstants.primaryColor,
      ),
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
              // Use custom award points if set, otherwise use default score
              final pointsToAdd = customAwardPoints[player.name] ?? score;
              playerProvider.addPointToPlayer(player, pointsToAdd);
              AppLogger.i("Added $pointsToAdd points to ${player.name}");
            } else if (buttonState.wrongOn) {
              // Use negative custom award points if set, otherwise use default negScore
              final pointsToSubtract =
                  customAwardPoints[player.name] != null
                      ? -customAwardPoints[player.name]!
                      : negScore;
              playerProvider.addPointToPlayer(player, pointsToSubtract);
              AppLogger.i("Added $pointsToSubtract points to ${player.name}");
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
      child: Text(
        "Done",
        style: AppTextStyles.titleSmall.copyWith(
          color: ColorConstants.surfaceColor,
        ),
      ),
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
          child: Icon(
            Icons.image_not_supported,
            color: ColorConstants.greyMedium,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _showImageOverlay(context, imageUrl);
      },
      child: Container(
        padding: EdgeInsets.all(6),
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
                child: Container(color: ColorConstants.transparent),
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
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(color: ColorConstants.shadow, blurRadius: 10.0),
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
    super.key,
    this.initialOn = false,
    this.isDisabled = false,
    required this.iconData,
    required this.onColor,
    required this.offColor,
    this.onToggle,
  });

  @override
  // ignore: library_private_types_in_public_api
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

class _PlayerNameWithRank extends StatefulWidget {
  final dynamic player; // Player object from PlayerProvider
  final BuzzerEntry? buzzerEntry;
  final VoidCallback onEditTap;

  const _PlayerNameWithRank({
    required this.player,
    required this.buzzerEntry,
    required this.onEditTap,
  });

  @override
  State<_PlayerNameWithRank> createState() => _PlayerNameWithRankState();
}

class _PlayerNameWithRankState extends State<_PlayerNameWithRank> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final playerName = widget.player.name;
    final buzzerEntry = widget.buzzerEntry;
    final questionPageState =
        context.findAncestorStateOfType<_QuestionPageState>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rank badge (if player has buzzed)
          if (buzzerEntry != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color:
                    questionPageState?._getRankingColor(buzzerEntry.position) ??
                    Colors.grey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "#${buzzerEntry.position}",
                style: AppTextStyles.smallCaption.copyWith(
                  color: ColorConstants.lightTextColor,
                ),
              ),
            ),
            SizedBox(width: 4),
          ],
          // Player name
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                playerName,
                style: AppTextStyles.scoreCard,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Edit icon on hover
          if (_isHovered)
            GestureDetector(
              onTap: widget.onEditTap,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: ColorConstants.secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
