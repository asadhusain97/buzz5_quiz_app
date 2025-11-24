import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/config/app_config.dart';
import 'package:buzz5_quiz_app/config/dev_config.dart';
import 'package:buzz5_quiz_app/config/theme.dart';
import 'package:buzz5_quiz_app/providers/question_done.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/widgets/dev_auth_gate.dart';
import 'package:buzz5_quiz_app/pages/forgot_password_page.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/providers/room_provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your application configuration
  AppConfig.initialize();

  // Debug: Log all environment variable values (redacted for security)
  AppLogger.i(
    'Firebase API Key: ${AppConfig.firebaseApiKey.isNotEmpty ? '[CONFIGURED]' : '[MISSING]'}',
  );
  AppLogger.i(
    'Firebase Project ID: ${AppConfig.firebaseProjectId.isNotEmpty ? AppConfig.firebaseProjectId : '[MISSING]'}',
  );
  AppLogger.i(
    'Firebase Auth Domain: ${AppConfig.firebaseAuthDomain.isNotEmpty ? AppConfig.firebaseAuthDomain : '[MISSING]'}',
  );

  // Check Firebase configuration specifically
  if (!AppConfig.isFirebaseConfigValid) {
    AppLogger.e(
      'Missing Firebase environment variables: ${AppConfig.missingFirebaseVariables.join(', ')}',
    );
    AppLogger.e('Firebase initialization will likely fail!');
  } else {
    AppLogger.i('All Firebase environment variables are configured');
  }

  try {
    AppLogger.i('Attempting Firebase initialization...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('Firebase initialized successfully');

    // Initialize App Check after Firebase - only if ReCAPTCHA key is available
    final String recaptchaKey = AppConfig.recaptchaKey;
    if (recaptchaKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(recaptchaKey),
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      AppLogger.i('App Check initialized successfully');
    } else {
      AppLogger.w(
        'ReCAPTCHA site key not provided, skipping App Check initialization',
      );
    }
  } catch (e) {
    AppLogger.e('CRITICAL ERROR initializing Firebase/App Check: $e');
    AppLogger.e(
      'This is likely due to missing or invalid environment variables',
    );
    // Still run the app to show error message to user
  }

  // Log development configuration if enabled
  DevConfig.logConfig();

  // debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => AnsweredQuestionsProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider();
            // Ensure auth listener starts only after Firebase initialization
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, RoomProvider>(
          create: (_) => RoomProvider(),
          update: (context, authProvider, roomProvider) {
            roomProvider?.setAuthProvider(authProvider);
            return roomProvider ?? RoomProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Buzz5 Quiz App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildDarkTheme(), // App uses only dark theme
        themeMode: ThemeMode.dark, // Force dark theme always
        home: const DevAuthGate(), // Uses DevAuthGate for dev features
        routes: {'/forgot-password': (context) => const ForgotPasswordPage()},
      ),
    );
  }
}
