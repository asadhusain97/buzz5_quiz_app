import 'package:buzz5_quiz_app/config/app_theme.dart';
import 'package:buzz5_quiz_app/models/questionDone.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/pages/home_page.dart';
import 'package:buzz5_quiz_app/pages/gsheet_check.dart';
// import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/playerProvider.dart';

void main() {
  // debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark theme

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => AnsweredQuestionsProvider()),
        // ...other providers
      ],
      child: MaterialApp(
        title: 'Buzz5 Quiz App',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        darkTheme: AppTheme.dark,
        theme: AppTheme.light,
        home: HomePage(onThemeChanged: _toggleTheme),
        // home: GSheetCheckPage(),
      ),
    );
  }
}
