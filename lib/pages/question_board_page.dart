// ignore_for_file: use_build_context_synchronously

import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/presentation/components/game_leaderboard.dart';
import 'package:buzz5_quiz_app/presentation/components/room_code_display.dart';
import 'package:buzz5_quiz_app/presentation/components/end_game_button.dart';
import 'package:buzz5_quiz_app/presentation/components/question_set_widget.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/qrow.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:buzz5_quiz_app/widgets/game_instructions_dialog.dart';
import 'package:provider/provider.dart';

/// The main question board page where players can select and answer quiz questions.
///
/// This page displays a Jeopardy-style game board with:
/// - Question sets organized by categories
/// - Player leaderboard and game code (for multiplayer)
/// - Game controls and navigation
///
/// Features:
/// - Responsive layout with horizontal and vertical scrolling
/// - Support for both manual and multiplayer modes
/// - Real-time question state tracking
/// - Smooth navigation transitions
class QuestionBoardPage extends StatelessWidget {
  /// The selected round/board for the current game
  final String? selectedRound;

  /// All available questions fetched from the data source
  final List<QRow>? allQRows;

  /// Whether the game is using manual players (no game code needed)
  final bool hasManualPlayers;

  const QuestionBoardPage({
    super.key,
    this.selectedRound,
    this.allQRows,
    this.hasManualPlayers = false,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.i("QuestionBoardPage built for round: $selectedRound");

    return BasePage(
      appBar: const CustomAppBar(title: "Question Board", showBackButton: true),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            QuestionBoardContent(
              selectedRound: selectedRound,
              allQRows: allQRows,
              hasManualPlayers: hasManualPlayers,
            ),
          ],
        ),
      ),
    );
  }
}

/// The main content area of the question board.
///
/// This widget manages:
/// - Question filtering by selected round
/// - Question set organization and display
/// - Game controls layout (leaderboard, game code, end game button)
class QuestionBoardContent extends StatefulWidget {
  final String? selectedRound;
  final List<QRow>? allQRows;
  final bool hasManualPlayers;

  const QuestionBoardContent({
    super.key,
    this.selectedRound,
    this.allQRows,
    this.hasManualPlayers = false,
  });

  @override
  State<QuestionBoardContent> createState() => _QuestionBoardContentState();
}

class _QuestionBoardContentState extends State<QuestionBoardContent> {
  late String selectedRound;
  List<QRow> _allQRows = [];
  List<QRow> _filteredQRows = [];
  List<String> uniqueSetNames = [];

  @override
  void initState() {
    super.initState();
    AppLogger.i("QuestionBoardContent initState called");

    // Initialize with passed data
    selectedRound = widget.selectedRound!;
    _allQRows = widget.allQRows!;

    // Filter questions by selected round
    _filterQRowsByRound(selectedRound);
  }

  /// Filters questions to show only those belonging to the selected round
  void _filterQRowsByRound(String round) {
    AppLogger.i("Filtering QRows for round: $round");

    // Get questions for this round
    final filteredRows = QRow.filterByRound(_allQRows, round);
    AppLogger.i("Found ${filteredRows.length} QRows for round: $round");

    // Extract unique set names (categories)
    final setNames = QRow.getUniqueSetNames(filteredRows);
    AppLogger.i(
      "Found ${setNames.length} unique set names for round $round: $setNames",
    );

    setState(() {
      _filteredQRows = filteredRows;
      uniqueSetNames = setNames;
    });

    // Precache all images in the background after the UI is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAllQuestionImages();
      // Show game instructions popup
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      showDialog(
        context: context,
        barrierDismissible: false, // User must press Start
        builder:
            (context) => GameInstructionsDialog(
              gameCode: roomProvider.currentRoom?.formattedRoomCode,
              hasManualPlayers: widget.hasManualPlayers,
            ),
      );
    });
  }

  /// Precaches all question and answer images for instant loading.
  ///
  /// This method:
  /// - Runs in the background without blocking UI
  /// - Downloads all images to browser cache
  /// - Makes question pages load instantly when clicked
  /// - Handles errors gracefully without affecting game flow
  ///
  /// Images are cached using Flutter's image cache which:
  /// - Stores images in browser memory
  /// - Persists during the session
  /// - Automatically manages cache size
  Future<void> _precacheAllQuestionImages() async {
    // Capture context before async operations
    final buildContext = context;
    if (!mounted) return;

    int imageCount = 0;
    int successCount = 0;
    int errorCount = 0;

    AppLogger.i(
      "Starting to precache images for ${_filteredQRows.length} questions",
    );

    for (final qrow in _filteredQRows) {
      // Check if widget is still mounted before each async operation
      if (!mounted) {
        AppLogger.w("Widget unmounted during image precaching, stopping");
        return;
      }

      // Precache question media if it exists
      if (qrow.qstnMedia.isNotEmpty) {
        imageCount++;
        try {
          await precacheImage(
            NetworkImage(qrow.qstnMedia),
            buildContext,
            onError: (exception, stackTrace) {
              errorCount++;
              AppLogger.w(
                "Failed to precache question image: ${qrow.qstnMedia} - $exception",
              );
            },
          );
          successCount++;
          AppLogger.d("Precached question image for: ${qrow.question}");
        } catch (e) {
          errorCount++;
          AppLogger.w("Error precaching question image: $e");
        }
      }

      // Check mounted again before next async operation
      if (!mounted) {
        AppLogger.w("Widget unmounted during image precaching, stopping");
        return;
      }

      // Precache answer media if it exists
      if (qrow.ansMedia.isNotEmpty) {
        imageCount++;
        try {
          await precacheImage(
            NetworkImage(qrow.ansMedia),
            buildContext,
            onError: (exception, stackTrace) {
              errorCount++;
              AppLogger.w(
                "Failed to precache answer image: ${qrow.ansMedia} - $exception",
              );
            },
          );
          successCount++;
          AppLogger.d("Precached answer image for: ${qrow.question}");
        } catch (e) {
          errorCount++;
          AppLogger.w("Error precaching answer image: $e");
        }
      }
    }

    AppLogger.i(
      "Image precaching complete: $successCount/$imageCount succeeded, $errorCount failed",
    );
  }

  /// Gets all questions for a specific set/category name
  List<QRow> _getQRowsForSetName(String setName) {
    return QRow.filterBySetName(_filteredQRows, setName);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Left side: Game controls and information
        _buildGameControls(),

        // Spacing between controls and question board
        const SizedBox(width: 80),

        // Right side: Question board
        _buildQuestionBoard(),
      ],
    );
  }

  /// Builds the left sidebar with game controls
  Widget _buildGameControls() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show game code only for multiplayer mode
              if (!widget.hasManualPlayers) ...[
                const RoomCodeDisplay(),
                const SizedBox(height: 30),
              ],

              // Player leaderboard
              const GameLeaderboard(),
              const SizedBox(height: 45),

              // End game button
              const EndGameButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the main question board area
  Widget _buildQuestionBoard() {
    // Show empty state if no question sets found
    if (uniqueSetNames.isEmpty) {
      return _buildEmptyState();
    }

    // Show question sets in a scrollable grid
    return SizedBox(
      width: 950,
      height: 900,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildQuestionSets(),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state when no questions are found
  Widget _buildEmptyState() {
    return SizedBox(
      width: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 48, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              'No question sets found for this round',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the grid of question sets
  Widget _buildQuestionSets() {
    return Wrap(
      spacing: 24.0,
      runSpacing: 24.0,
      alignment: WrapAlignment.center,
      children:
          uniqueSetNames.map((setName) {
            final List<QRow> setData = _getQRowsForSetName(setName);

            // Convert QRow objects to Map format for QuestionSetWidget
            final List<Map<String, dynamic>> setDataMaps =
                setData.map((qrow) => _convertQRowToMap(qrow)).toList();

            return QuestionSetWidget(data: setDataMaps);
          }).toList(),
    );
  }

  /// Converts a QRow object to Map format for compatibility
  Map<String, dynamic> _convertQRowToMap(QRow qrow) {
    return {
      'qid': qrow.qid,
      'round': qrow.round,
      'set_name': qrow.setName,
      'points': qrow.points,
      'question': qrow.question,
      'qstn_media': qrow.qstnMedia,
      'answer': qrow.answer,
      'ans_media': qrow.ansMedia,
      'set_explanation': qrow.setExplanation,
    };
  }
}

/// A reusable dropdown widget for selecting game rounds/boards.
///
/// This widget provides:
/// - Clean dropdown interface for round selection
/// - Proper styling consistent with app theme
/// - Callback for handling selection changes
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
    AppLogger.i("Building RoundDropDown with ${rounds.length} rounds: $rounds");

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Select a Board:', style: AppTextStyles.bodyBig),
          const SizedBox(height: 12),
          _buildDropdown(context),
        ],
      ),
    );
  }

  /// Builds the actual dropdown widget
  Widget _buildDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Center(child: Text('Select a round')),
          value: selectedRound,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          items:
              rounds.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Center(child: Text(value, style: AppTextStyles.body)),
                );
              }).toList(),
          onChanged: (String? newValue) {
            AppLogger.i("Round selected: $newValue");
            onRoundSelected(newValue);
          },
        ),
      ),
    );
  }
}
