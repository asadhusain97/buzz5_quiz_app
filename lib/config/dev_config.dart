import 'package:flutter/foundation.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

/// Development Configuration for Testing
///
/// This file controls development-only features that help with testing.
/// All features are automatically disabled in release builds.
///
/// HOW TO USE:
/// 1. Set `bypassAuth` to true to skip authentication
/// 2. Set `testPage` to navigate directly to a specific page
/// 3. Set `useTestUser` to true to auto-login with mock credentials
class DevConfig {
  // ============================================================================
  // MAIN TOGGLES - Change these to control testing behavior
  // ============================================================================

  /// Skip authentication and go straight to the app
  /// - true: Bypass login screen entirely
  /// - false: Normal authentication flow
  static const bool bypassAuth = false;

  /// Which page to navigate to on startup (when bypassAuth is true)
  /// Options: 'home', 'profile', 'create', 'marketplace', 'joingame',
  ///          'gameroom', 'instructions', 'questionboard', 'question',
  ///          'final', 'gsheet', 'new_set'
  /// - null: Go to home page
  static const String? testPage = null; // Change to 'profile', 'create', etc.

  /// Auto-login with test user credentials (when bypassAuth is false)
  /// - true: Automatically attempt login with testUserEmail/testUserPassword
  /// - false: Show normal login screen
  static const bool useTestUser = false;

  // ============================================================================
  // TEST USER CREDENTIALS
  // ============================================================================

  /// Test user email for auto-login
  static const String testUserEmail = 'test@example.com';

  /// Test user password for auto-login
  static const String testUserPassword = 'testpassword123';

  /// Test user display name
  static const String testUserDisplayName = 'Test User';

  // ============================================================================
  // ADVANCED OPTIONS
  // ============================================================================

  /// Enable verbose debug logging
  static const bool verboseLogging = true;

  /// Simulate guest user (unauthenticated but can access app)
  /// Only applies when bypassAuth is true
  static const bool simulateGuest = false;

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if development features are enabled
  /// Returns false in release builds automatically
  static bool get isDevModeActive => kDebugMode && (bypassAuth || useTestUser);

  /// Get the configured test page name
  static String get targetPage => testPage ?? 'home';

  /// Log configuration on startup (debug only)
  static void logConfig() {
    if (!kDebugMode) return;

    AppLogger.d('═══════════════════════════════════════════════════════════');
    AppLogger.d('🔧 DEV CONFIG ACTIVE');
    AppLogger.d('═══════════════════════════════════════════════════════════');
    AppLogger.d('Bypass Auth:     $bypassAuth');
    AppLogger.d('Test Page:       ${testPage ?? "home (default)"}');
    AppLogger.d('Use Test User:   $useTestUser');
    AppLogger.d('Simulate Guest:  $simulateGuest');
    AppLogger.d('Verbose Logging: $verboseLogging');
    if (useTestUser) {
      AppLogger.d('Test Email:      $testUserEmail');
    }
    AppLogger.d('═══════════════════════════════════════════════════════════');
  }
}
