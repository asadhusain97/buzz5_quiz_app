import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:buzz5_quiz_app/pages/game_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({super.key});

  @override
  State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  final _playerNameController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _roomCodeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _joinRoom() async {
    _clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      // Format game code (remove dashes and convert to uppercase)
      final gameCode =
          _roomCodeController.text.replaceAll('-', '').toUpperCase().trim();
      final playerName = _playerNameController.text.trim();

      AppLogger.i(
        "Attempting to join room: $gameCode with player name: $playerName",
      );

      // Get room details first to validate
      final room = await roomProvider.getRoomByCode(gameCode);
      if (room == null) {
        setState(() {
          _errorMessage = "Game not found. Please check the game code.";
          _isJoining = false;
        });
        return;
      }

      if (!room.isActive || room.isExpired) {
        setState(() {
          _errorMessage = "This room is no longer active.";
          _isJoining = false;
        });
        return;
      }

      // Attempt to join the room with player name validation
      final success = await roomProvider.joinRoom(
        gameCode,
        playerName: playerName,
      );

      if (success && mounted) {
        // Player has been added to Firebase roomPlayers via joinRoom()
        // The playerList will be automatically synchronized via RoomProvider listener
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          AppLogger.i(
            "Successfully joined game: $gameCode as logged-in user: ${user.uid}",
          );
        } else {
          AppLogger.i("Successfully joined game: $gameCode as guest player");
        }

        // Navigate to game room page
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => GameRoomPage()),
        );
      } else {
        setState(() {
          _errorMessage =
              roomProvider.error ?? "Failed to join room. Please try again.";
        });
      }
    } catch (e) {
      AppLogger.e("Error joining room: $e");
      setState(() {
        _errorMessage = "An error occurred while joining the room.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: CustomAppBar(title: "Join a Game", showBackButton: true),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.group_add,
                      size: 80,
                      color: ColorConstants.primaryContainerColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Enter the game code and your display name for the quiz to join the game.",
                      style: AppTextStyles.body.copyWith(
                        color: ColorConstants.hintGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),

                    // Game Code Input
                    TextFormField(
                      controller: _roomCodeController,
                      decoration: InputDecoration(
                        labelText: "Game Code",
                        counterText: "",
                        prefixIcon: Icon(Icons.meeting_room),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: ColorConstants.darkCardColor,
                      ),
                      maxLength: 7,
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9-]'),
                        ),
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          ),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a game code';
                        }
                        final cleanCode = value.replaceAll('-', '');
                        if (cleanCode.length != 6) {
                          return 'Game code must be 6 characters';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _clearError();
                        // Auto-format with dash
                        if (value.length == 4 && !value.contains('-')) {
                          _roomCodeController.text =
                              '${value.substring(0, 3)}-${value.substring(3)}';
                          _roomCodeController
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _roomCodeController.text.length,
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 20),

                    // Player Name Input
                    TextFormField(
                      controller: _playerNameController,
                      decoration: InputDecoration(
                        labelText: "Your Name",
                        hintText: "Enter your display name",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: ColorConstants.darkCardColor,
                      ),
                      style: TextStyle(fontSize: 16),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _clearError();
                      },
                    ),
                    SizedBox(height: 30),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: ColorConstants.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ColorConstants.danger,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: ColorConstants.danger,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: ColorConstants.danger,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Join Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isJoining ? null : _joinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isJoining
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ColorConstants.lightTextColor,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Joining Room...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Join Room',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
