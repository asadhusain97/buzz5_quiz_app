import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/base_page.dart';
import 'package:buzz5_quiz_app/models/room_provider.dart';
import 'package:buzz5_quiz_app/models/player_provider.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.i("GameRoomPage initialized");
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      appBar: CustomAppBar(
        title: "Game Room", 
        showBackButton: true,
      ),
      child: Consumer2<RoomProvider, PlayerProvider>(
        builder: (context, roomProvider, playerProvider, child) {
          final room = roomProvider.currentRoom;
          final players = playerProvider.playerList;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Room Status Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ColorConstants.darkCardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ColorConstants.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.meeting_room,
                              size: 48,
                              color: ColorConstants.primaryContainerColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Connected to Room",
                              style: AppTextStyles.headingBig,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            if (room != null) ...[
                              Text(
                                room.formattedRoomCode,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: ColorConstants.primaryContainerColor,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(room.status).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getStatusColor(room.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(room.status),
                                  style: TextStyle(
                                    color: _getStatusColor(room.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Player Info
                      if (players.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ColorConstants.darkCardColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Your Player Info",
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: ColorConstants.primaryContainerColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: ColorConstants.lightTextColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    players.first.name,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: ColorConstants.lightTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                      ],
                      
                      // Waiting Message
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              color: Colors.blue,
                              size: 32,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Waiting for Game to Start",
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "The game host will start the game when ready.\nYou'll be able to participate in the quiz once it begins!",
                              style: AppTextStyles.body.copyWith(
                                color: ColorConstants.lightTextColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Leave Room Button
                          ElevatedButton(
                            onPressed: () => _showLeaveRoomDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.exit_to_app, size: 20),
                                SizedBox(width: 8),
                                Text("Leave Room"),
                              ],
                            ),
                          ),
                          
                          // Refresh Status Button
                          ElevatedButton(
                            onPressed: () {
                              // Refresh room status
                              AppLogger.i("Refreshing room status");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Room status refreshed"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primaryColor,
                              foregroundColor: ColorConstants.lightTextColor,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text("Refresh"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Help Information
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorConstants.darkCardColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: ColorConstants.primaryContainerColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "What happens next?",
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: ColorConstants.primaryContainerColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "• The game host will select questions and start the game\n"
                              "• You'll be able to buzz in when questions are active\n"
                              "• Your score will be tracked throughout the game\n"
                              "• Stay connected to participate in the full experience!",
                              style: AppTextStyles.body.copyWith(
                                color: ColorConstants.lightTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'RoomStatus.waiting':
        return Colors.orange;
      case 'RoomStatus.active':
        return Colors.green;
      case 'RoomStatus.questionActive':
        return Colors.blue;
      case 'RoomStatus.ended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(dynamic status) {
    switch (status.toString()) {
      case 'RoomStatus.waiting':
        return 'Waiting for Players';
      case 'RoomStatus.active':
        return 'Game Active';
      case 'RoomStatus.questionActive':
        return 'Question in Progress';
      case 'RoomStatus.ended':
        return 'Game Ended';
      default:
        return 'Unknown Status';
    }
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
            'Are you sure you want to leave this game room? You won\'t be able to participate in the current game.',
            style: AppTextStyles.body.copyWith(
              color: ColorConstants.lightTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Leave Room'),
            ),
          ],
        );
      },
    );
  }

  void _leaveRoom() {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    // Clear room and player data
    roomProvider.clearRoom();
    playerProvider.setPlayerList([]);
    
    AppLogger.i("Left the room");
    
    // Navigate back to home page
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (Route<dynamic> route) => false,
    );
  }
}