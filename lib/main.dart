import 'package:buzz5_quiz_app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
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
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,
      home: HomePage(onThemeChanged: _toggleTheme),
    );
  }
}
