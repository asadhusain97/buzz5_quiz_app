import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameInstructionsDialog extends StatelessWidget {
  final String? gameCode;

  const GameInstructionsDialog({super.key, this.gameCode});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorConstants.darkCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome to the Game!',
                  style: AppTextStyles.headlineSmall,
                ),
                // Close button removed as per request
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Instructions & Rules
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('How to Join'),
                          const SizedBox(height: 8),
                          Text(
                            '1. Scan the QR code or go to buzz5quiz.web.app\n'
                            '2. Login/signup or play as a guest\n'
                            '3. Enter the game code and your name\n'
                            '4. Wait for the game to start!',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle('Game Rules'),
                          const SizedBox(height: 8),
                          Text(
                            '- 25 questions in total.\n'
                            '- Points increase with difficulty (10 to 50).\n'
                            '- All players may buzz; Buzzer order decides who answers.\n'
                            '- Player has 5 seconds to answer after buzzing/their chance.\n'
                            '- Correct answer: +Points & Control.\n'
                            '- Wrong answer: -Points.\n'
                            '- Quiz Emcee is god',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),
                  // Vertical Divider
                  Container(
                    width: 1,
                    color: ColorConstants.primaryContainerColor.withOpacity(
                      0.3,
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Side: QR Code
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Scan to Join', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                          // Placeholder for QR Image
                          // In real implementation, this would be a generated QR or asset.
                          Image.asset(
                            'assets/images/join_qr.png',
                            width: 200,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                alignment: Alignment.center,
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'QR Code Placeholder',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (gameCode != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Enter the Game Code:',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: ColorConstants.lightTextColor.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(gameCode!, style: AppTextStyles.headlineMedium),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Start Button
            ElevatedButton(
              onPressed: () {
                // Start the game clock
                Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                ).setGameStartTime(DateTime.now());
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'START GAME',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: ColorConstants.secondaryContainerColor,
      ),
    );
  }
}
