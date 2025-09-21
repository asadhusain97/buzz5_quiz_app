import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:buzz5_quiz_app/pages/create_questions_page.dart';
import 'package:buzz5_quiz_app/pages/marketplace_page.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';
import 'package:buzz5_quiz_app/widgets/auth_modal.dart';
import 'package:url_launcher/url_launcher.dart';

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
            child: Column(
              children: [
                Expanded(
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
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? ColorConstants.lightTextColor
                                      : ColorConstants.primaryContainerColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The jeopardy style ultimate quiz experience',
                            style: AppTextStyles.homeSubtitle.copyWith(
                              color: ColorConstants.hintGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 64),

                          // Show different buttons based on authentication status
                          if (authProvider.isAuthenticated) ...[
                            // Authenticated user - show 4 buttons in a 2x2 grid
                            Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                children: [
                                  // First row of buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
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
                                            minimumSize: Size(0, 56),
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
                                                style: AppTextStyles.homeButton,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
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
                                            minimumSize: Size(0, 56),
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
                                              Icon(Icons.group_add_rounded, size: 24),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Join Game',
                                                style: AppTextStyles.homeButton,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Second row of buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            AppLogger.i("Navigating to CreateQuestionsPage");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CreateQuestionsPage(),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(0, 56),
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
                                              Icon(Icons.quiz_outlined, size: 24),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Create Questions',
                                                style: AppTextStyles.homeButton,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            AppLogger.i("Navigating to MarketplacePage");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => MarketplacePage(),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(0, 56),
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
                                              Icon(Icons.store, size: 24),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Marketplace',
                                                style: AppTextStyles.homeButton,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
                                    style: AppTextStyles.homeButton,
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
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 24.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '© 2025 Asad Husain',
                        style: AppTextStyles.homeFooter.copyWith(
                          color: ColorConstants.hintGrey.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.hintGrey.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),

                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            AppLogger.i("Portfolio link tapped");

                            const portfolioUrl =
                                'https://asadhusain97.github.io/';

                            try {
                              if (await canLaunchUrl(Uri.parse(portfolioUrl))) {
                                await launchUrl(
                                  Uri.parse(portfolioUrl),
                                  mode:
                                      LaunchMode
                                          .externalApplication, // Opens in browser
                                );
                              } else {
                                AppLogger.e("Could not launch portfolio URL");
                                // Optional: Show snackbar to user
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Unable to open portfolio'),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              AppLogger.e("Error launching portfolio URL: $e");
                            }
                          },
                          child: Text(
                            'About the developer',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorConstants.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              decorationColor: ColorConstants.primaryColor
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
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
