import 'package:buzz5_quiz_app/config/app_theme.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/questionDone.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/widgets/auth_gate.dart';
// import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/playerProvider.dart';
import 'package:buzz5_quiz_app/models/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('Firebase initialized successfully');

    // Initialize App Check after Firebase
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(
        '6Lf8UIIrAAAAAC7EmBoC6IwdoAwoEZAjkeAYm62V',
      ),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    AppLogger.i('App Check initialized successfully');
  } catch (e) {
    AppLogger.e('CRITICAL ERROR initializing Firebase/App Check: $e');
    // Still run the app to show error message to user
  }

  // debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => AnsweredQuestionsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ...other providers
      ],
      child: MaterialApp(
        title: 'Buzz5 Quiz App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const AuthGate(),
      ),
    );
  }
}
