import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/auth_provider.dart';
import 'package:buzz5_quiz_app/widgets/auth_modal.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showAuthModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AuthModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("HomePage built");

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: CustomAppBar(title: "Buzz5 quiz", showBackButton: false),
          body: AppBackground(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: ColorConstants.primaryContainerColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.primaryColor,
                            spreadRadius: 5,
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/bolt_transparent_simple.png',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      authProvider.isAuthenticated
                          ? 'Welcome back, ${authProvider.user?.displayNameOrEmail ?? 'Player'}!'
                          : 'Welcome to Buzz5!',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? ColorConstants.lightTextColor
                                : ColorConstants.primaryContainerColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The jeopardy style ultimate quiz experience',
                      style: TextStyle(
                        fontSize: 18,
                        color: ColorConstants.hintGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 64),

                    // Show different buttons based on authentication status
                    if (authProvider.isAuthenticated) ...[
                      // Authenticated user - show game buttons
                      ElevatedButton(
                        onPressed: () {
                          AppLogger.i("Navigating to InstructionsPage");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InstructionsPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(280, 56),
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Start Game',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          AppLogger.i("Navigating to JoinGamePage");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinGamePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(280, 56),
                          backgroundColor:
                              ColorConstants.secondaryContainerColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_add_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Join Game',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Non-authenticated user - show login button
                      ElevatedButton(
                        onPressed: () => _showAuthModal(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(280, 56),
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Login to Play',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Please login to access game features',
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorConstants.hintGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
