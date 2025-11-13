import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/dev_config.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/widgets/auth_gate.dart';

// Import all pages for direct navigation
import 'package:buzz5_quiz_app/pages/home_page.dart';
import 'package:buzz5_quiz_app/pages/profile_page.dart';
import 'package:buzz5_quiz_app/pages/create_page.dart';
import 'package:buzz5_quiz_app/pages/marketplace_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/final_page.dart';
import 'package:buzz5_quiz_app/pages/gsheet_check.dart';

/// Development-aware AuthGate
///
/// In debug mode with DevConfig enabled, this bypasses authentication
/// and navigates directly to the configured test page.
///
/// In release mode or when DevConfig is disabled, this behaves exactly
/// like the normal AuthGate.
class DevAuthGate extends StatelessWidget {
  const DevAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // In release builds, always use normal AuthGate
    if (!kDebugMode) {
      return const AuthGate();
    }

    // In debug mode, check if dev features are enabled
    if (DevConfig.bypassAuth) {
      if (DevConfig.verboseLogging) {
        AppLogger.d('🔧 DEV MODE: Bypassing authentication');
        AppLogger.d('🔧 DEV MODE: Navigating to ${DevConfig.targetPage}');
      }

      // Navigate directly to the configured test page
      return _getTestPage(DevConfig.targetPage);
    }

    // Use normal auth flow
    return const AuthGate();
  }

  /// Get the widget for the specified page name
  Widget _getTestPage(String pageName) {
    switch (pageName.toLowerCase()) {
      case 'home':
        return const HomePage();
      case 'profile':
        return const ProfilePage();
      case 'create':
        return const CreatePage();
      case 'marketplace':
        return const MarketplacePage();
      case 'joingame':
        return const JoinGamePage();
      case 'gameroom':
        // Note: GameRoomPage requires parameters, you may need to provide mock data
        return const _DevGameRoomWrapper();
      case 'instructions':
        return const InstructionsPage();
      case 'questionboard':
        // Note: QuestionBoardPage may require parameters
        return const _DevQuestionBoardWrapper();
      case 'question':
        // Note: QuestionPage requires parameters
        return const _DevQuestionPageWrapper();
      case 'final':
        return const FinalPage();
      case 'gsheet':
        return const GSheetCheckPage();
      default:
        // Fallback to home page if invalid page name
        return const HomePage();
    }
  }
}

// Wrappers for pages that require parameters
// These provide sensible defaults for testing

class _DevGameRoomWrapper extends StatelessWidget {
  const _DevGameRoomWrapper();

  @override
  Widget build(BuildContext context) {
    // Update with actual required parameters for GameRoomPage when needed
    // For now, fall back to home page
    if (DevConfig.verboseLogging) {
      AppLogger.w(
        '⚠️  GameRoomPage requires parameters. Showing HomePage instead.',
      );
      AppLogger.w(
        '   Update _DevGameRoomWrapper if you need to test GameRoomPage.',
      );
    }
    return const HomePage();
  }
}

class _DevQuestionBoardWrapper extends StatelessWidget {
  const _DevQuestionBoardWrapper();

  @override
  Widget build(BuildContext context) {
    // Update with actual required parameters for QuestionBoardPage when needed
    if (DevConfig.verboseLogging) {
      AppLogger.w(
        '⚠️  QuestionBoardPage may require parameters. Showing HomePage instead.',
      );
      AppLogger.w(
        '   Update _DevQuestionBoardWrapper if you need to test this page.',
      );
    }
    return const HomePage();
  }
}

class _DevQuestionPageWrapper extends StatelessWidget {
  const _DevQuestionPageWrapper();

  @override
  Widget build(BuildContext context) {
    // Update with actual required parameters for QuestionPage when needed
    if (DevConfig.verboseLogging) {
      AppLogger.w(
        '⚠️  QuestionPage requires parameters. Showing HomePage instead.',
      );
      AppLogger.w(
        '   Update _DevQuestionPageWrapper if you need to test this page.',
      );
    }
    return const HomePage();
  }
}
