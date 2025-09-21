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

/// The main question board page where players can select and answer quiz questions.
///
/// This page displays a Jeopardy-style game board with:
/// - Question sets organized by categories
/// - Player leaderboard and room code (for multiplayer)
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

  /// Whether the game is using manual players (no room code needed)
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
      appBar: const CustomAppBar(
        title: "Question Board",
        showBackButton: true,
      ),
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
            )
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
/// - Game controls layout (leaderboard, room code, end game button)
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
              // Show room code only for multiplayer mode
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
      children: uniqueSetNames.map((setName) {
        final List<QRow> setData = _getQRowsForSetName(setName);

        // Convert QRow objects to Map format for QuestionSetWidget
        final List<Map<String, dynamic>> setDataMaps = setData
            .map((qrow) => _convertQRowToMap(qrow))
            .toList();

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
      'set_example_question': qrow.setExampleQuestion,
      'set_example_answer': qrow.setExampleAnswer,
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
          items: rounds.map((String value) {
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
    );
  }
}