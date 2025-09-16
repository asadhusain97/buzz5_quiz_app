import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/models/question_done.dart';
import 'package:buzz5_quiz_app/pages/final_page.dart';
import 'package:buzz5_quiz_app/pages/question_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
import 'package:buzz5_quiz_app/models/room_provider.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/qrow.dart';

class QuestionBoardPage extends StatelessWidget {
  const QuestionBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.i("QuestionBoardPage built");
    return BasePage(
      appBar: CustomAppBar(title: "Question Board", showBackButton: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [QuestionBoardContent()],
        ),
      ),
    );
  }
}

class QuestionBoardContent extends StatefulWidget {
  const QuestionBoardContent({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QuestionBoardContentState createState() => _QuestionBoardContentState();
}

class _QuestionBoardContentState extends State<QuestionBoardContent> {
  String? selectedRound;
  late Future<List<QRow>> _qrowsFuture;
  List<QRow> _allQRows = [];
  List<QRow> _filteredQRows = [];
  List<String> uniqueRounds = [];
  List<String> uniqueSetNames = [];
  bool isDataLoaded = false;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    AppLogger.i("QuestionBoardContent initState called");
    _fetchQRows();
  }

  Future<void> _fetchQRows() async {
    setState(() {
      isDataLoaded = false;
      hasError = false;
    });

    try {
      _qrowsFuture = QRow.fetchAll();
      await _loadData();
    } catch (e) {
      AppLogger.e("Error in _fetchQRows: $e");
      setState(() {
        isDataLoaded = true;
        hasError = true;
        errorMessage = "Failed to initialize data: ${e.toString()}";
      });
    }
  }

  Future<void> _loadData() async {
    try {
      _allQRows = await _qrowsFuture;

      // Add debug logging
      AppLogger.i("Loaded ${_allQRows.length} QRows from API");

      final uniqueRoundsResult = QRow.getUniqueRounds(_allQRows);

      // Add debug logging for rounds
      AppLogger.i(
        "Found ${uniqueRoundsResult.length} unique rounds: $uniqueRoundsResult",
      );

      setState(() {
        uniqueRounds = uniqueRoundsResult;
        isDataLoaded = true;
        hasError = false;
      });
    } catch (e) {
      AppLogger.e("Error loading QRows: $e");
      setState(() {
        isDataLoaded = true; // Still mark as loaded to show error message
        hasError = true;
        errorMessage = e.toString();
      });

      // Show error snackbar
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load questions: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _filterQRowsByRound(String round) {
    AppLogger.i("Filtering QRows for round: $round");

    // Get the QRows for this round
    final filteredRows = QRow.filterByRound(_allQRows, round);
    AppLogger.i("Found ${filteredRows.length} QRows for round: $round");

    // Get unique set names for this round
    final setNames = QRow.getUniqueSetNames(filteredRows);
    AppLogger.i(
      "Found ${setNames.length} unique set names for round $round: $setNames",
    );

    setState(() {
      selectedRound = round;
      _filteredQRows = filteredRows;
      uniqueSetNames = setNames;
    });
  }

  List<QRow> _getQRowsForSetName(String setName) {
    return QRow.filterBySetName(_filteredQRows, setName);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Left side with controls
        if (!isDataLoaded) ...[
          // Show loading indicator in the center of the screen
          Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Loading boards...',
                    style: AppTextStyles.bodyBig,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasError) ...[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Error loading boards',
                              style: AppTextStyles.bodyBig.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: AppTextStyles.body.copyWith(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isDataLoaded = false;
                              hasError = false;
                            });
                            _fetchQRows();
                          },
                          icon: Icon(Icons.refresh),
                          label: Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Center(
                    child: RoundDropDown(
                      selectedRound: selectedRound,
                      onRoundSelected: (String? round) {
                        if (round != null) {
                          _filterQRowsByRound(round);
                        }
                      },
                      rounds: uniqueRounds,
                    ),
                  ),
                  SizedBox(height: 30),
                  if (selectedRound != null) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoomCodeDisplay(),
                        SizedBox(height: 30),
                        Leaderboard(),
                        SizedBox(height: 45),
                        EndGameButton(),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Spacing between controls and question board
          if (selectedRound != null) ...[SizedBox(width: 80)],

          // Question board area - only show if round is selected and there are set names
          if (selectedRound != null) ...[
            if (uniqueSetNames.isEmpty) ...[
              SizedBox(
                width: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, size: 48, color: Colors.amber),
                      SizedBox(height: 20),
                      Text(
                        'No question sets found for this round',
                        style: AppTextStyles.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: 950,
                height: 900,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 24.0,
                        runSpacing: 24.0,
                        alignment: WrapAlignment.center,
                        children:
                            uniqueSetNames.map((setName) {
                              final List<QRow> setData = _getQRowsForSetName(
                                setName,
                              );
                              // Convert QRow objects to Map format for QSet
                              final List<Map<String, dynamic>> setDataMaps =
                                  setData
                                      .map(
                                        (qrow) => {
                                          'qid': qrow.qid,
                                          'round': qrow.round,
                                          'set_name': qrow.setName,
                                          'points': qrow.points,
                                          'question': qrow.question,
                                          'qstn_media': qrow.qstnMedia,
                                          'answer': qrow.answer,
                                          'ans_media': qrow.ansMedia,
                                          'set_explanation':
                                              qrow.setExplanation,
                                          'set_example_question':
                                              qrow.setExampleQuestion,
                                          'set_example_answer':
                                              qrow.setExampleAnswer,
                                        },
                                      )
                                      .toList();

                              return QSet(data: setDataMaps);
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class RoundDropDown extends StatelessWidget {
  final String? selectedRound;
  final Function(String?) onRoundSelected;
  final List<String> rounds;

  const RoundDropDown({
    super.key,
    required this.selectedRound,
    required this.onRoundSelected,
    required this.rounds,
  });

  @override
  Widget build(BuildContext context) {
    // Debug print to verify the rounds
    AppLogger.i("Building RoundDropDown with ${rounds.length} rounds: $rounds");

    return Container(
      width: 200, // Set a fixed width
      padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Select a Board:', style: AppTextStyles.bodyBig),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Center(child: Text('Select a round')),
                value: selectedRound,
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                items:
                    rounds.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child: Text(value, style: AppTextStyles.body),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  AppLogger.i("Round selected: $newValue");
                  onRoundSelected(newValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, RoomProvider>(
      builder: (context, playerProvider, roomProvider, child) {
        // Set up playerProvider synchronization with roomProvider if not already set
        if (roomProvider.hasActiveRoom) {
          roomProvider.setPlayerProvider(playerProvider);
        }

        AppLogger.i("Player list updated: ${playerProvider.playerList}");
        return SingleChildScrollView(
          child: SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Leaderboard', style: AppTextStyles.titleMedium),
                SizedBox(height: 20.0),
                SizedBox(
                  width: 180.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: playerProvider.playerList.length,
                    itemBuilder: (context, index) {
                      final player = playerProvider.playerList[index];
                      final isLastPositivePlayer =
                          playerProvider.lastPositivePlayer == player;

                      // Check if this player is connected to the room
                      RoomPlayer? roomPlayer;
                      try {
                        roomPlayer = roomProvider.roomPlayers.firstWhere(
                          (rp) =>
                              rp.name.toLowerCase() ==
                              player.name.toLowerCase(),
                        );
                      } catch (e) {
                        roomPlayer = null;
                      }
                      final isConnectedToRoom =
                          roomPlayer != null && roomPlayer.isConnected;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(
                            255,
                            255,
                            255,
                            0.1,
                          ), // Translucent white
                          border: Border.all(
                            color:
                                isLastPositivePlayer
                                    ? Colors.green
                                    : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(
                                0,
                                0,
                                0,
                                0.1,
                              ), // Translucent black
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // Connection status indicator
                                  if (roomProvider.hasActiveRoom) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isConnectedToRoom
                                                ? Colors.green
                                                : Colors.grey.withValues(
                                                  alpha: 0.5,
                                                ),
                                      ),
                                    ),
                                  ],
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: AppTextStyles.scoreCard,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${player.score}',
                              style: AppTextStyles.scoreCard,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EndGameButton extends StatelessWidget {
  const EndGameButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // Record game end time
          Provider.of<PlayerProvider>(
            context,
            listen: false,
          ).setGameEndTime(DateTime.now());
          // Sort players by score before ending the game
          Provider.of<PlayerProvider>(context, listen: false).sortPlayerList();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FinalPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: Size(200, 60),
          backgroundColor: ColorConstants.primaryContainerColor,
        ),
        icon: Icon(Icons.emoji_events),
        label: Text(
          'End Game',
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.surfaceColor,
          ),
        ),
      ),
    );
  }
}

class QSet extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const QSet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Sort data by points
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => a['points'].compareTo(b['points']));

    return Container(
      width: 150,
      margin: EdgeInsets.all(2.0),
      padding: EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (data.isNotEmpty) {
                _showSetInfoPopup(context, data[0]);
              }
            },
            borderRadius: BorderRadius.circular(8.0),
            hoverColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
            child: Container(
              width: 150,
              height: 80,
              padding: EdgeInsets.all(8.0), // Padding inside the box
              margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600, width: 1.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 130),
                    child: Text(
                      data.isNotEmpty
                          ? data[0]['set_name']
                          : 'No setname present',
                      style: AppTextStyles.titleMedium,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.0),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(sortedData.length, (index) {
              final item = sortedData[index];
              final String questionId =
                  "${item['qid']}"; // Unique ID for each question

              // Use Consumer to listen for changes in answered questions
              return Consumer<AnsweredQuestionsProvider>(
                builder: (context, answeredProvider, child) {
                  final bool isAnswered = answeredProvider.isQuestionAnswered(
                    questionId,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child:
                        isAnswered
                            // Show tick mark if question is answered
                            ? ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => QuestionPage(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'qid':
                                            questionId, // Pass the questionId
                                        'setname': item['set_name'],
                                        'question': item['question'],
                                        'answer': item['answer'],
                                        'score': item['points'],
                                        'qstn_media': item['qstn_media'] ?? "",
                                        'ans_media': item['ans_media'] ?? "",
                                        'playerList':
                                            Provider.of<PlayerProvider>(
                                                  context,
                                                  listen: false,
                                                ).playerList
                                                .map((player) => player.name)
                                                .toList(),
                                      },
                                    ),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      final curvedAnimation = CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOut,
                                      );
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 1),
                                          end: Offset.zero,
                                        ).animate(curvedAnimation),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(90),
                                ),
                                padding: EdgeInsets.all(0),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  // color: Colors.grey.shade400,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.green.shade300,
                                        size: 30,
                                      ),
                                      Text(
                                        item['points'].toString(),
                                        style: AppTextStyles.titleSmall
                                            .copyWith(
                                              color: Colors.green.shade500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            // Show regular button if not answered
                            : ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => QuestionPage(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'qid':
                                            questionId, // Pass the questionId
                                        'setname': item['set_name'],
                                        'question': item['question'],
                                        'answer': item['answer'],
                                        'score': item['points'],
                                        'qstn_media': item['qstn_media'] ?? "",
                                        'ans_media': item['ans_media'] ?? "",
                                        'playerList':
                                            Provider.of<PlayerProvider>(
                                                  context,
                                                  listen: false,
                                                ).playerList
                                                .map((player) => player.name)
                                                .toList(),
                                      },
                                    ),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      final curvedAnimation = CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOut,
                                      );
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 1),
                                          end: Offset.zero,
                                        ).animate(curvedAnimation),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(45),
                                ),
                                padding: EdgeInsets.all(0),
                                backgroundColor:
                                    ColorConstants.primaryContainerColor,
                              ),
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    item['points'].toString(),
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: ColorConstants.surfaceColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showSetInfoPopup(BuildContext context, Map<String, dynamic> setData) {
    // Helper function to truncate text to 500 characters
    String truncateText(String text, int maxLength) {
      if (text.length <= maxLength) return text;
      return '${text.substring(0, maxLength)}...';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: ColorConstants.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    setData['set_name'] ?? 'Category Info',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: ColorConstants.lightTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Explanation Section
                Text(
                  'Explanation',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: ColorConstants.secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  truncateText(
                    setData['set_explanation'] ?? 'No explanation available',
                    500,
                  ),
                  style: AppTextStyles.body.copyWith(
                    color: ColorConstants.lightTextColor,
                  ),
                ),

                const SizedBox(height: 20),

                // Example Question Section - only show if data exists
                if (setData['set_example_question'] != null &&
                    setData['set_example_question']
                        .toString()
                        .trim()
                        .isNotEmpty) ...[
                  Text(
                    'Example Question',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: ColorConstants.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    truncateText(setData['set_example_question'], 500),
                    style: AppTextStyles.body.copyWith(
                      color: ColorConstants.lightTextColor,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Example Answer Section - only show if data exists
                if (setData['set_example_answer'] != null &&
                    setData['set_example_answer']
                        .toString()
                        .trim()
                        .isNotEmpty) ...[
                  Text(
                    'Example Answer',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: ColorConstants.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    truncateText(setData['set_example_answer'], 500),
                    style: AppTextStyles.body.copyWith(
                      color: ColorConstants.lightTextColor,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Close Button
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryContainerColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: ColorConstants.lightTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RoomCodeDisplay extends StatelessWidget {
  const RoomCodeDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        // Only show room code if there's an active room
        if (!roomProvider.hasActiveRoom || roomProvider.currentRoom == null) {
          return SizedBox.shrink();
        }

        final room = roomProvider.currentRoom!;
        final connectedPlayers =
            roomProvider.roomPlayers
                .where((player) => !player.isHost && player.isConnected)
                .length;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: ColorConstants.primaryColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.doorbell,
                    color: ColorConstants.primaryContainerColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Room Code',
                    style: TextStyle(
                      color: ColorConstants.surfaceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              SelectableText(
                room.formattedRoomCode,
                style: TextStyle(
                  color: ColorConstants.primaryContainerColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$connectedPlayers players connected',
                style: TextStyle(
                  color: ColorConstants.secondaryContainerColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Join room using the code above',
                style: TextStyle(
                  color: ColorConstants.lightTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
