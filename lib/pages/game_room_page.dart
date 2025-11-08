import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  bool _isHelpExpanded = false;
  late DateTime _joinedTime;
  List<BuzzerEntry> _buzzerEntries = [];
  bool _hasPlayerBuzzed = false;
  StreamSubscription? _buzzerSubscription;
  StreamSubscription? _questionSubscription;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FocusNode _focusNode = FocusNode();

  // Question state variables
  bool _isQuestionActive = false;
  int? _questionStartTime;
  Map<String, dynamic>? _currentQuestionData;

  @override
  void initState() {
    super.initState();
    _joinedTime = DateTime.now();
    _setupBuzzerListener();
    AppLogger.i("GameRoomPage initialized");
  }

  @override
  void dispose() {
    _buzzerSubscription?.cancel();
    _questionSubscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          final bool canBuzz = _isQuestionActive && !_hasPlayerBuzzed;
          if (canBuzz) {
            _onBuzzerPressed();
          }
        }
      },
      child: BasePage(
        appBar: CustomAppBar(title: "Game Room", showBackButton: false),
        child: Consumer3<RoomProvider, PlayerProvider, AuthProvider>(
          builder: (context, roomProvider, playerProvider, authProvider, child) {
          // Set up playerProvider synchronization with roomProvider if not already set
          if (roomProvider.hasActiveRoom) {
            roomProvider.setPlayerProvider(playerProvider);
            // Start listening to buzzer entries if room is active
            if (roomProvider.currentRoom != null) {
              _startListeningToBuzzers(roomProvider.currentRoom!.roomId);
            }
          }
          final room = roomProvider.currentRoom;
          final roomPlayers = roomProvider.roomPlayers;
          final hostPlayer = roomPlayers.firstWhere(
            (player) => player.isHost,
            orElse:
                () =>
                    RoomPlayer(playerId: '', name: 'Unknown Host', joinedAt: 0),
          );

          // Determine if current user is the host
          final isHost = authProvider.user?.uid == room?.hostId;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 80 : 16,
              vertical: 16,
            ),
            child: Column(
              children: [
                // Conditional UI based on host status
                if (isHost)
                  ..._buildHostView(room, hostPlayer, roomPlayers)
                else
                  ..._buildPlayerView(room, hostPlayer, roomPlayers),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  // Build host view widgets
  List<Widget> _buildHostView(
    Room? room,
    RoomPlayer hostPlayer,
    List<RoomPlayer> roomPlayers,
  ) {
    return [
      // Host Control Panel Header
      _buildHostControlPanel(),
      SizedBox(height: 40),

      // Bottom: Connected Players List (excluding host)
      _buildPlayersList(roomPlayers.where((p) => !p.isHost).toList()),
    ];
  }

  // Build player view widgets (existing layout)
  List<Widget> _buildPlayerView(
    Room? room,
    RoomPlayer hostPlayer,
    List<RoomPlayer> roomPlayers,
  ) {
    return [
      // Collapsible Help Widget
      _buildHelpWidget(),
      SizedBox(height: 20),

      // Header Row: Left Info | Right Actions
      Row(
        children: [
          // Left third: Room info
          Expanded(child: _buildLeftInfoPanel(room, hostPlayer, roomPlayers)),
          // Center third: Empty space
          Expanded(child: SizedBox()),
          // Right third: Actions
          Expanded(child: _buildRightActionsPanel()),
        ],
      ),

      SizedBox(height: 40),

      // Center: Large Buzzer Button
      _buildBuzzerButton(),

      SizedBox(height: 40),

      // Bottom: Connected Players List (excluding host)
      _buildPlayersList(roomPlayers.where((p) => !p.isHost).toList()),
    ];
  }

  // Build the host control panel widget
  Widget _buildHostControlPanel() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.primaryContainerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Host Control Panel Header
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: ColorConstants.primaryContainerColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                "Host Control Panel",
                style: AppTextStyles.titleLarge.copyWith(
                  color: ColorConstants.primaryContainerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Current Question Information
          if (_currentQuestionData != null && _isQuestionActive) ...[
            _buildQuestionInfoSection(),
          ] else if (_currentQuestionData != null && !_isQuestionActive) ...[
            _buildLastQuestionSection(),
          ] else ...[
            _buildNoQuestionSection(),
          ],
        ],
      ),
    );
  }

  // Build the question info section when a question is active
  Widget _buildQuestionInfoSection() {
    final questionData = _currentQuestionData!;
    final setName = questionData['setName'] ?? 'Unknown Set';
    final questionText =
        questionData['question'] ?? 'No question text available';
    final answerText =
        questionData['answer']?.toString() ?? 'No answer available';
    final points = questionData['points'] ?? 0;
    final questionMedia = questionData['qstnMedia'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Left: Set Name and Points
        Row(
          children: [
            Expanded(
              child: _buildCompactInfoCard(
                setName,
                Icons.category,
                ColorConstants.secondaryContainerColor,
              ),
            ),
            SizedBox(width: 12),
            _buildPointsBadge(points),
          ],
        ),

        SizedBox(height: 24),

        // Current Question Text (only if not empty)
        if (questionText.isNotEmpty &&
            questionText != 'No question text available') ...[
          _buildQuestionSection(questionText),
          SizedBox(height: 16),
        ],

        // Question Media (if available)
        if (questionMedia != null && questionMedia.toString().isNotEmpty) ...[
          _buildMediaSection(questionMedia.toString()),
          SizedBox(height: 16),
        ],

        // PRIMARY: Answer Text (Biggest Element) - only if not empty
        if (answerText.isNotEmpty && answerText != 'No answer available') ...[
          _buildAnswerSection(answerText),
        ],
      ],
    );
  }

  // Build section when no question is active
  Widget _buildNoQuestionSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.overlayLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 48, color: ColorConstants.hintGrey),
          SizedBox(height: 12),
          Text(
            "No Active Question",
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.hintGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Waiting for the quiz to begin...",
            style: AppTextStyles.body.copyWith(color: ColorConstants.hintGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build media section for question images
  Widget _buildMediaSection(String mediaUrl) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.overlayLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: ColorConstants.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                "Question Media",
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              mediaUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.overlayMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: ColorConstants.hintGrey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Failed to load media",
                        style: AppTextStyles.body.copyWith(
                          color: ColorConstants.hintGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.overlayMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.primaryColor,
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build section when showing the last question (inactive)
  Widget _buildLastQuestionSection() {
    final questionData = _currentQuestionData!;
    final setName = questionData['setName'] ?? 'Unknown Set';
    final questionText =
        questionData['question'] ?? 'No question text available';
    final answerText =
        questionData['answer']?.toString() ?? 'No answer available';
    final points = questionData['points'] ?? 0;
    final questionMedia = questionData['qstnMedia'];

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Muted/discolored background for inactive state
        color: ColorConstants.hintGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last Question Header with indicator
          Row(
            children: [
              Icon(Icons.history, color: ColorConstants.hintGrey, size: 24),
              SizedBox(width: 12),
              Text(
                "LAST QUESTION",
                style: AppTextStyles.titleMedium.copyWith(
                  color: ColorConstants.hintGrey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Top Row: Set Name and Points (muted)
          Row(
            children: [
              Expanded(
                child: _buildMutedCompactInfoCard(
                  setName,
                  Icons.category,
                  ColorConstants.hintGrey,
                ),
              ),
              SizedBox(width: 12),
              _buildMutedPointsBadge(points),
            ],
          ),

          SizedBox(height: 24),

          // Current Question Text (only if not empty)
          if (questionText.isNotEmpty &&
              questionText != 'No question text available') ...[
            _buildMutedQuestionSection(questionText),
            SizedBox(height: 16),
          ],

          // Question Media (if available)
          if (questionMedia != null && questionMedia.toString().isNotEmpty) ...[
            _buildMutedMediaSection(questionMedia.toString()),
            SizedBox(height: 16),
          ],

          // Answer Text (only if not empty)
          if (answerText.isNotEmpty && answerText != 'No answer available') ...[
            _buildMutedAnswerSection(answerText),
          ],
        ],
      ),
    );
  }

  // Build compact info card for set name
  Widget _buildCompactInfoCard(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build points badge
  Widget _buildPointsBadge(int points) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.secondaryContainerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.secondaryContainerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            color: ColorConstants.secondaryContainerColor,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            "$points",
            style: AppTextStyles.titleSmall.copyWith(
              color: ColorConstants.secondaryContainerColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Build answer section - The biggest and most prominent element
  Widget _buildAnswerSection(String answerText) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.connected.withValues(alpha: 0.15),
            ColorConstants.connected.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.connected.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.connected.withValues(alpha: 0.1),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: ColorConstants.connected, size: 24),
              SizedBox(width: 12),
              Text(
                "Answer",
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.connected,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            answerText,
            style: AppTextStyles.titleLarge.copyWith(
              color: ColorConstants.lightTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 24,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Build question section
  Widget _buildQuestionSection(String questionText) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primaryContainerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primaryContainerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: ColorConstants.primaryContainerColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Question",
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.primaryContainerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            questionText,
            style: AppTextStyles.body.copyWith(
              color: ColorConstants.lightTextColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Muted versions for "Last Question" display
  Widget _buildMutedCompactInfoCard(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.hintGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorConstants.hintGrey, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.titleSmall.copyWith(
                color: ColorConstants.hintGrey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutedPointsBadge(int points) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.hintGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, color: ColorConstants.hintGrey, size: 16),
          SizedBox(width: 4),
          Text(
            "$points",
            style: AppTextStyles.titleSmall.copyWith(
              color: ColorConstants.hintGrey,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutedQuestionSection(String questionText) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.hintGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: ColorConstants.hintGrey,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Question",
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.hintGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            questionText,
            style: AppTextStyles.body.copyWith(
              color: ColorConstants.hintGrey,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutedAnswerSection(String answerText) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.hintGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: ColorConstants.hintGrey,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                "Answer",
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.hintGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            answerText,
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.hintGrey,
              fontWeight: FontWeight.w500,
              fontSize: 18,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutedMediaSection(String mediaUrl) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.hintGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                color: ColorConstants.hintGrey,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Question Media",
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.hintGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Opacity(
                opacity: 0.6,
                child: Image.network(
                  mediaUrl,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ColorConstants.hintGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: ColorConstants.hintGrey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Media unavailable",
                            style: AppTextStyles.body.copyWith(
                              color: ColorConstants.hintGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpWidget() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isHelpExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isHelpExpanded = expanded;
            });
          },
          leading: Icon(
            Icons.info_outline,
            color: ColorConstants.primaryContainerColor,
            size: 20,
          ),
          title: Text(
            "What happens next?",
            style: AppTextStyles.titleSmall.copyWith(
              color: ColorConstants.primaryContainerColor,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                "• The Quiz Emcee will read and display the questions and answers\n"
                "• You'll be able to buzz in when questions are active\n"
                "• Closing the tab/browser will not affect your connection or points\n"
                "• Leaving the game will forfeit your points\n",
                style: AppTextStyles.body.copyWith(
                  color: ColorConstants.lightTextColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftInfoPanel(
    Room? room,
    RoomPlayer hostPlayer,
    List<RoomPlayer> roomPlayers,
  ) {
    if (room == null) return SizedBox();

    final connectedCount =
        roomPlayers.where((p) => p.isConnected && !p.isHost).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game Code
        Text(
          "Game Code",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          room.formattedRoomCode,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: ColorConstants.primaryContainerColor,
          ),
        ),
        SizedBox(height: 16),

        // Connected Players Count
        Text(
          "Connected",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "$connectedCount players",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.secondaryContainerColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),

        // Host Name (get display name from Firebase Auth if available)
        Text(
          "Host",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Consumer2<RoomProvider, AuthProvider>(
          builder: (context, roomProvider, authProvider, child) {
            // If the current user is the host, show their display name from auth
            final isCurrentUserHost = authProvider.user?.uid == room.hostId;
            String hostDisplayName = hostPlayer.name;

            if (isCurrentUserHost && authProvider.user != null) {
              hostDisplayName = authProvider.user!.displayNameOrEmail;
            }

            return Text(
              hostDisplayName,
              style: AppTextStyles.titleSmall.copyWith(
                color: ColorConstants.lightTextColor,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRightActionsPanel() {
    final timeSinceJoined = DateTime.now().difference(_joinedTime).inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Time Since Joined
        Text(
          "Connected",
          style: AppTextStyles.body.copyWith(
            color: ColorConstants.hintGrey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "${timeSinceJoined}m ago",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.lightTextColor,
          ),
        ),
        SizedBox(height: 16),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Leave Room Button
            ElevatedButton(
              onPressed: () => _showLeaveRoomDialog(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(120, 40),
                backgroundColor: ColorConstants.danger,
                foregroundColor: ColorConstants.lightTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.exit_to_app, size: 14),
                  SizedBox(width: 4),
                  Text("Leave", style: AppTextStyles.buttonTextSmall),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuzzerButton() {
    final bool canBuzz = _isQuestionActive && !_hasPlayerBuzzed;
    return GestureDetector(
      onTap: canBuzz ? _onBuzzerPressed : null,
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: _getBuzzerGradientColors(),
            stops: [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            // Outer shadow for depth
            BoxShadow(
              color: ColorConstants.overlayMedium,
              offset: Offset(0, 8),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            // Inner shadow for 3D effect
            BoxShadow(
              color: ColorConstants.danger.withValues(alpha: 0.6),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: -2,
            ),
            // Top highlight
            BoxShadow(
              color: ColorConstants.danger.withValues(alpha: 0.4),
              offset: Offset(0, -2),
              blurRadius: 8,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _getBuzzerBorderColor(), width: 3),
          ),
          child: Center(
            child: Text(
              _getBuzzerText(),
              style: TextStyle(
                color: _getBuzzerTextColor(),
                fontSize: _getBuzzerFontSize(),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: ColorConstants.overlayDark,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList(List<RoomPlayer> roomPlayers) {
    if (roomPlayers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Text(
          "No other players have joined yet",
          style: AppTextStyles.body.copyWith(color: ColorConstants.hintGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final connectedPlayers = roomPlayers.where((p) => p.isConnected).length;

    // Sort players: buzzed players first (by buzz position), then un-buzzed players
    final sortedPlayers = _getSortedPlayerList(roomPlayers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "All Players ($connectedPlayers)",
          style: AppTextStyles.titleSmall.copyWith(
            color: ColorConstants.primaryContainerColor,
          ),
        ),
        SizedBox(height: 12),
        ...sortedPlayers.map((player) => _buildPlayerTile(player)),
      ],
    );
  }

  Widget _buildPlayerTile(RoomPlayer player) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorConstants.darkCardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Connection status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  player.isConnected
                      ? ColorConstants.connected
                      : ColorConstants.disconnected,
            ),
          ),
          SizedBox(width: 12),

          // Player name
          Expanded(
            child: Text(
              player.name,
              style: AppTextStyles.body.copyWith(
                color: ColorConstants.lightTextColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

          // Buzzer timing (right side) - only show when question is active
          if (_getBuzzerEntryForPlayer(player.playerId) != null &&
              _isQuestionActive)
            _buildBuzzerTiming(_getBuzzerEntryForPlayer(player.playerId)!),
        ],
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ColorConstants.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Leave Room?',
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.lightTextColor,
            ),
          ),
          content: Text(
            'Are you sure you want to leave this game room?\n'
            'Your score will be lost forever.',
            style: AppTextStyles.body.copyWith(
              color: ColorConstants.lightTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: ColorConstants.primaryContainerColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _leaveRoom();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(120, 40),
                backgroundColor: ColorConstants.danger,
                foregroundColor: ColorConstants.lightTextColor,
              ),
              child: Text('Leave Room'),
            ),
          ],
        );
      },
    );
  }

  void _setupBuzzerListener() {
    // We'll set up the listener when we have an active room
    // This will be called from the Consumer2 widget when room is available
  }

  void _startListeningToBuzzers(String roomId) {
    _buzzerSubscription?.cancel();
    _questionSubscription?.cancel();

    // Listen to current question state
    _startListeningToQuestionState(roomId);

    final buzzersRef = _database
        .child('rooms')
        .child(roomId)
        .child('currentQuestionBuzzes')
        .orderByChild('timestamp');

    AppLogger.i("Starting to listen for buzzer entries in room: $roomId");

    _buzzerSubscription = buzzersRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      final newBuzzerEntries = <BuzzerEntry>[];

      if (data != null && data is Map) {
        final buzzersMap = Map<String, dynamic>.from(data);
        for (final entry in buzzersMap.entries) {
          // OPTIMIZATION: Read playerId from the key (path), not from data value
          final playerId = entry.key;
          final buzzerData = Map<String, dynamic>.from(entry.value);

          // OPTIMIZATION: Simplified data structure - only playerName and timestamp in value
          final buzzerEntry = BuzzerEntry(
            playerId: playerId,
            playerName: buzzerData['playerName'] ?? 'Unknown',
            timestamp: buzzerData['timestamp'] ?? 0,
            questionNumber: 1, // Default question number
            position: 0, // Position will be calculated below after sorting
          );
          newBuzzerEntries.add(buzzerEntry);
        }
      } else {
        // Data is null - buzzer entries have been cleared
        AppLogger.i(
          "BUZZER FLOW [PLAYER]: Buzzer entries CLEARED from Firebase (received null/empty data)",
        );
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

      // Check if current player has buzzed
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      final hasPlayerBuzzed =
          currentUser != null &&
          newBuzzerEntries.any((entry) => entry.playerId == currentUser.uid);

      // Detect if buzzer state was reset (went from having entries to empty)
      final oldEntriesCount = _buzzerEntries.length;
      final wasReset = oldEntriesCount > 0 && newBuzzerEntries.isEmpty;

      setState(() {
        _buzzerEntries = newBuzzerEntries;
        _hasPlayerBuzzed = hasPlayerBuzzed;
      });

      if (wasReset) {
        AppLogger.i(
          "BUZZER FLOW [PLAYER]: ✓ Buzzer state RESET! Cleared $oldEntriesCount previous entries. Ready for new question.",
        );
      } else if (newBuzzerEntries.isNotEmpty) {
        final topBuzzers = newBuzzerEntries
            .take(3)
            .map((e) => "${e.playerName} (#${e.position})")
            .join(", ");
        AppLogger.i(
          "BUZZER FLOW [PLAYER]: Buzzer rankings updated. Total: ${newBuzzerEntries.length}. Top 3: $topBuzzers",
        );
      }
    });
  }

  void _startListeningToQuestionState(String roomId) {
    final questionRef = _database
        .child('rooms')
        .child(roomId)
        .child('currentQuestion');

    AppLogger.i(
      "BUZZER FLOW [PLAYER]: Starting to listen for question state in room: $roomId",
    );

    _questionSubscription = questionRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      bool isActive = false;
      int? startTime;
      Map<String, dynamic>? questionData;

      if (data != null && data is Map) {
        questionData = Map<String, dynamic>.from(data);
        isActive = questionData['isActive'] ?? false;
        startTime = questionData['startTime'];
      }

      // Check if this is a NEW question (different startTime)
      final isNewQuestion = startTime != null && startTime != _questionStartTime;

      if (mounted) {
        setState(() {
          // Reset buzzer state when:
          // 1. Question becomes inactive (!isActive)
          // 2. OR a new question starts (different startTime and isActive)
          if (!isActive || (isActive && isNewQuestion)) {
            _hasPlayerBuzzed = false;
            _buzzerEntries.clear();

            if (isNewQuestion && isActive) {
              AppLogger.i(
                "BUZZER FLOW [PLAYER]: NEW question detected! Resetting buzzer state. New startTime=$startTime",
              );
            }
          }

          _isQuestionActive = isActive;
          _questionStartTime = startTime;
          _currentQuestionData = questionData;
        });
      }

      if (isActive) {
        AppLogger.i(
          "BUZZER FLOW [PLAYER]: Question ACTIVATED! isActive=true, startTime=$startTime. Buzzer is now ENABLED.",
        );
      } else {
        AppLogger.i(
          "BUZZER FLOW [PLAYER]: Question DEACTIVATED! isActive=false. Buzzer is now DISABLED.",
        );
      }
    });
  }

  Future<void> _onBuzzerPressed() async {
    if (!_isQuestionActive) {
      AppLogger.i("BUZZER FLOW [PLAYER]: Cannot buzz - no question active");
      return;
    }

    if (_hasPlayerBuzzed) {
      AppLogger.i("BUZZER FLOW [PLAYER]: Already buzzed - ignoring");
      return;
    }

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentRoom = roomProvider.currentRoom;
    final currentUser = authProvider.user;

    if (currentRoom == null || currentUser == null) {
      AppLogger.e("BUZZER FLOW [PLAYER]: Cannot buzz - no active room or user");
      return;
    }

    // OPTIMIZATION 3: Optimistic UI update - set flag immediately for instant feedback
    setState(() {
      _hasPlayerBuzzed = true;
    });

    try {
      final roomPlayer = roomProvider.roomPlayers.firstWhere(
        (p) => p.playerId == currentUser.uid,
        orElse:
            () => RoomPlayer(
              playerId: currentUser.uid,
              name: currentUser.displayName,
              joinedAt: DateTime.now().millisecondsSinceEpoch,
            ),
      );
      final playerName = roomPlayer.name;

      AppLogger.i(
        "BUZZER FLOW [PLAYER]: Attempting to record buzz for $playerName (using server timestamp)",
      );
      AppLogger.i(
        "BUZZER FLOW [PLAYER]: Player auth.uid: ${currentUser.uid}",
      );
      AppLogger.i(
        "BUZZER FLOW [PLAYER]: Writing to path: rooms/${currentRoom.roomId}/currentQuestionBuzzes/${currentUser.uid}",
      );

      // Check if the player exists in Firebase
      final playerSnapshot = await _database
          .child('rooms')
          .child(currentRoom.roomId)
          .child('players')
          .child(currentUser.uid)
          .get();

      if (!playerSnapshot.exists) {
        AppLogger.w(
          "BUZZER FLOW [PLAYER]: WARNING - Player does not exist in Firebase players list yet. "
          "This might cause permission issues.",
        );
      } else {
        AppLogger.i("BUZZER FLOW [PLAYER]: Player exists in Firebase players list");
      }

      // OPTIMIZATION 1 & 2: Save optimized payload with server-side timestamp
      // Removed: playerId (redundant - already in key), position (calculated by host)
      // Changed: timestamp now uses ServerValue.timestamp instead of client time
      await _database
          .child('rooms')
          .child(currentRoom.roomId)
          .child('currentQuestionBuzzes')
          .child(currentUser.uid)
          .set({
            'playerName': playerName,
            'timestamp': ServerValue.timestamp,
          });

      AppLogger.i(
        "BUZZER FLOW [PLAYER]: SUCCESS! Buzzer press recorded for $playerName with server timestamp",
      );

      // Update player's buzz count
      final playerRef = _database
          .child('rooms')
          .child(currentRoom.roomId)
          .child('players')
          .child(currentUser.uid);

      final currentPlayerSnapshot = await playerRef.get();
      if (currentPlayerSnapshot.exists) {
        final playerData = Map<String, dynamic>.from(
          currentPlayerSnapshot.value as Map,
        );
        final currentBuzzCount = playerData['buzzCount'] ?? 0;
        await playerRef.child('buzzCount').set(currentBuzzCount + 1);
        AppLogger.i(
          "BUZZER FLOW [PLAYER]: Updated buzz count for $playerName: ${currentBuzzCount + 1}",
        );
      }
    } catch (e, stackTrace) {
      // Revert optimistic update on error
      setState(() {
        _hasPlayerBuzzed = false;
      });

      AppLogger.e("BUZZER FLOW [PLAYER]: ERROR recording buzzer press: $e");
      AppLogger.e("BUZZER FLOW [PLAYER]: Stack trace: $stackTrace");

      // Check if it's a permission error
      if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        AppLogger.e(
          "BUZZER FLOW [PLAYER]: This is a Firebase security rules issue. "
          "Make sure the host has deployed the updated database.rules.json with: "
          "'firebase deploy --only database'",
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error recording buzz: ${e.toString().split(':').last}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Format absolute time for first player (no '+' prefix)
  String _formatAbsoluteTimeForFirst(int timestamp) {
    if (_questionStartTime == null) {
      return "--:--";
    }

    final diffMs = timestamp - _questionStartTime!;
    final diffSeconds = diffMs / 1000.0;

    if (diffSeconds < 60) {
      return "${diffSeconds.toStringAsFixed(3)}s";
    } else {
      final minutes = (diffSeconds / 60).floor();
      final remainingSeconds = diffSeconds % 60;
      return "$minutes:${remainingSeconds.toStringAsFixed(3).padLeft(6, '0')}";
    }
  }

  // Format relative time from first player (with '+' prefix and 3 decimals)
  String _formatRelativeTimeFromFirst(
    int currentTimestamp,
    int firstTimestamp,
  ) {
    final diffMs = currentTimestamp - firstTimestamp;
    final diffSeconds = diffMs / 1000.0;
    return "+${diffSeconds.toStringAsFixed(3)}s";
  }

  BuzzerEntry? _getBuzzerEntryForPlayer(String playerId) {
    try {
      return _buzzerEntries.firstWhere((entry) => entry.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildBuzzerTiming(BuzzerEntry entry) {
    final position = _buzzerEntries.indexOf(entry) + 1;
    final isFirstPlayer = position == 1;

    // For first player: show absolute time without '+'
    // For others: show relative time from first player
    String timeDisplay;
    if (isFirstPlayer) {
      timeDisplay = _formatAbsoluteTimeForFirst(entry.timestamp);
    } else {
      final firstEntry = _buzzerEntries.first;
      timeDisplay = _formatRelativeTimeFromFirst(
        entry.timestamp,
        firstEntry.timestamp,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Position badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _getRankingColor(position),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "#$position",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 4),
        // Time display (absolute for first, relative for others)
        Text(
          timeDisplay,
          style: TextStyle(
            color: ColorConstants.secondaryContainerColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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

  // Buzzer visual state helpers
  List<Color> _getBuzzerGradientColors() {
    if (!_isQuestionActive) {
      // Inactive - grey
      return [Colors.grey.shade300, Colors.grey.shade500, Colors.grey.shade700];
    } else if (_hasPlayerBuzzed) {
      // Buzzed - darker grey
      return [Colors.grey.shade400, Colors.grey.shade600, Colors.grey.shade800];
    } else {
      // Active - red
      return [Colors.red.shade400, Colors.red.shade600, Colors.red.shade800];
    }
  }

  String _getBuzzerText() {
    if (!_isQuestionActive) {
      return "Wait...";
    } else if (_hasPlayerBuzzed) {
      return "Buzzed";
    } else {
      return "BUZZER";
    }
  }

  Color _getBuzzerTextColor() {
    if (!_isQuestionActive) {
      return Colors.grey.shade600;
    } else if (_hasPlayerBuzzed) {
      return Colors.grey.shade400;
    } else {
      return Colors.white;
    }
  }

  double _getBuzzerFontSize() {
    if (!_isQuestionActive) {
      return 18;
    } else if (_hasPlayerBuzzed) {
      return 20;
    } else {
      return 24;
    }
  }

  Color _getBuzzerBorderColor() {
    if (!_isQuestionActive) {
      return Colors.grey.shade400.withValues(alpha: 0.8);
    } else if (_hasPlayerBuzzed) {
      return Colors.grey.shade500.withValues(alpha: 0.8);
    } else {
      return Colors.red.shade300.withValues(alpha: 0.8);
    }
  }

  // Sort players: buzzed players first (by buzz position), then un-buzzed players
  List<RoomPlayer> _getSortedPlayerList(List<RoomPlayer> players) {
    if (!_isQuestionActive || _buzzerEntries.isEmpty) {
      // Default sorting when no question is active or no buzzes yet
      return players;
    }

    final buzzedPlayerIds = _buzzerEntries.map((e) => e.playerId).toSet();
    final buzzedPlayers = <RoomPlayer>[];
    final unbuzzedPlayers = <RoomPlayer>[];

    // Separate buzzed and un-buzzed players
    for (final player in players) {
      if (buzzedPlayerIds.contains(player.playerId)) {
        buzzedPlayers.add(player);
      } else {
        unbuzzedPlayers.add(player);
      }
    }

    // Sort buzzed players by their buzz order (position)
    buzzedPlayers.sort((a, b) {
      final aEntry = _buzzerEntries.firstWhere((e) => e.playerId == a.playerId);
      final bEntry = _buzzerEntries.firstWhere((e) => e.playerId == b.playerId);
      return aEntry.position.compareTo(bEntry.position);
    });

    // Return buzzed players first, then un-buzzed players
    return [...buzzedPlayers, ...unbuzzedPlayers];
  }

  void _leaveRoom() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    // Properly leave the room (removes from Firebase)
    await roomProvider.leaveRoom();
    playerProvider.setPlayerList([]);

    AppLogger.i("Left the room");

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
