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
import 'package:buzz5_quiz_app/models/qrow.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

const String howToPlayMD = """
  YOU are the reader/ Quiz Emcee. You will conduct the quiz and 'read' the questions.
  Once you are ready, click the button to start the game.
  - When you reach the next page, select a question board to play from the dropdown
  - Ask players to join the room using the game code from the 'Join Game' page
  - Each Board has 5 sets of 5 questions; each with increasing difficulty from 10 to 50 points
  - Click on the set name to learn about what the set means and see example question (if available)
  - A random player starts the game (Green border indicates the player in control of the board)
  - The player in control chooses a question tile. (All questions are open for everyone for answering)
  - A player retains control to pick the next question, until another player scores
  - Wrong answers get negative points
  - The reader/Quiz Emcee can grant part points to players by clicking on their name during a specific question
  """;

class InstructionsPage extends StatefulWidget {
  const InstructionsPage({super.key});

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  bool _showBuzzerSection = false;
  bool _showInstructionsSection = false;

  // API loading state
  List<QRow> _allQRows = [];
  List<String> _uniqueRounds = [];
  String? _selectedRound;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  late Future<List<QRow>> _qrowsFuture;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppLogger.e('Could not launch $url');
      throw 'Could not launch $url';
    }
    AppLogger.i('Launched URL: $url');
  }

  Future<void> _fetchQRows() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      AppLogger.i("Starting to fetch QRows from API");
      _qrowsFuture = QRow.fetchAll();
      await _loadData();
    } catch (e) {
      AppLogger.e("Error in _fetchQRows: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Failed to load question data: ${e.toString()}";
      });
    }
  }

  Future<void> _loadData() async {
    try {
      _allQRows = await _qrowsFuture;

      AppLogger.i("Loaded ${_allQRows.length} QRows from API");

      final uniqueRoundsResult = QRow.getUniqueRounds(_allQRows);

      AppLogger.i(
        "Found ${uniqueRoundsResult.length} unique rounds: $uniqueRoundsResult",
      );

      setState(() {
        _uniqueRounds = uniqueRoundsResult;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      AppLogger.e("Error in _loadData: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Failed to process question data: ${e.toString()}";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Start loading boards immediately when page loads
    _fetchQRows();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("InstructionsPage built");
    return BasePage(
      appBar: CustomAppBar(title: "Set up", showBackButton: true),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopSection(context),
            SizedBox(height: 24),
            _buildCollapsibleBuzzerSection(context),
            SizedBox(height: 16),
            _buildCollapsibleInstructionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor,

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
        children: [
          // Title Section
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: ColorConstants.surfaceColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Select a Board",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.surfaceColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Dropdown and Button Section
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth > 600;

              if (isWideScreen) {
                return Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: _buildDropdownContainer(context),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 150,
                      child: _buildCompactLetsGoButton(context),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDropdownContainer(context),
                    SizedBox(height: 16),
                    _buildCompactLetsGoButton(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorConstants.primaryContainerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorConstants.primaryColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Loading boards...",
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstants.surfaceColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red[900]?.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Error loading boards",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
            InkWell(
              onTap: _fetchQRows,
              child: Icon(Icons.refresh, color: Colors.red, size: 20),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRound,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ColorConstants.primaryContainerColor.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ColorConstants.primaryContainerColor.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ColorConstants.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[800],
          prefixIcon: Icon(
            Icons.dashboard,
            color: ColorConstants.surfaceColor.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
        hint: Text(
          "Choose a board",
          style: TextStyle(
            fontSize: 16,
            color: ColorConstants.surfaceColor.withValues(alpha: 0.7),
          ),
        ),
        items:
            _uniqueRounds.map((String round) {
              return DropdownMenuItem<String>(
                value: round,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    round,
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorConstants.surfaceColor,
                    ),
                  ),
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedRound = newValue;
          });
        },
        dropdownColor: ColorConstants.darkCardColor,
        menuMaxHeight: 300,
        isDense: false,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
      ),
    );
  }

  Widget _buildCollapsibleBuzzerSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryContainerColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showBuzzerSection = !_showBuzzerSection;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_button,
                    color: ColorConstants.surfaceColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Using an external buzzer setup",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.surfaceColor,
                      ),
                    ),
                  ),
                  Icon(
                    _showBuzzerSection ? Icons.expand_less : Icons.expand_more,
                    color: ColorConstants.surfaceColor,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showBuzzerSection ? null : 0,
            child:
                _showBuzzerSection
                    ? Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          Text(
                            "Great! You can use your own buzzer system and we will handle scoring and question management.",
                            style: AppTextStyles.body,
                            textAlign: TextAlign.justify,
                          ),
                          Text(
                            "Add the player names below.",
                            style: AppTextStyles.body,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleInstructionsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryContainerColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showInstructionsSection = !_showInstructionsSection;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: ColorConstants.surfaceColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Instructions for the Reader",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.surfaceColor,
                      ),
                    ),
                  ),
                  Icon(
                    _showInstructionsSection
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: ColorConstants.surfaceColor,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showInstructionsSection ? null : 0,
            child:
                _showInstructionsSection
                    ? Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: MarkdownBody(
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
                            color: ColorConstants.lightTextColor,
                          ),
                          a: TextStyle(
                            color: ColorConstants.secondaryContainerColor,
                            decoration: TextDecoration.underline,
                          ),
                          strong: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLetsGoButton(BuildContext context) {
    // Button is enabled only when a round is selected and there's no error
    bool canProceed = _selectedRound != null && !_hasError;

    // Determine background color based on state
    Color backgroundColor;
    if (_hasError) {
      backgroundColor = Colors.red;
    } else if (canProceed) {
      backgroundColor = ColorConstants.primaryColor;
    } else {
      backgroundColor = Colors.grey;
    }

    return ElevatedButton(
      onPressed:
          canProceed
              ? () async {
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
                AppLogger.i(
                  "Game state reset - starting with empty player list",
                );

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
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  );
                  return;
                }

                // Set game start time
                playerProvider.setGameStartTime(DateTime.now());

                // Navigate to question board with preloaded data
                navigator.push(
                  MaterialPageRoute(
                    builder:
                        (context) => QuestionBoardPage(
                          selectedRound: _selectedRound!,
                          allQRows: _allQRows,
                        ),
                  ),
                );
              }
              : (_hasError ? _fetchQRows : null),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: ColorConstants.lightTextColor,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: canProceed ? 3 : 1,
        disabledBackgroundColor: Colors.grey,
        disabledForegroundColor: ColorConstants.lightTextColor.withValues(
          alpha: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_hasError ? Icons.refresh : Icons.play_circle_filled, size: 24),
          SizedBox(width: 8),
          Text(
            "Let's Go!",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
