import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/constants.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class HomePage extends StatelessWidget {
  final Function(bool) onThemeChanged;

  HomePage({required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    AppLogger.i("HomePage built");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buzz5 Quiz',
          style: TextStyle(color: ColorConstants.lightTextColor),
        ),
        backgroundColor: ColorConstants.primaryContainerColor,
        actions: [
          Row(
            children: [
              Text(
                'Dark Theme',
                style: TextStyle(color: ColorConstants.lightTextColor),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    AppLogger.i("Theme changed: ${value ? 'Dark' : 'Light'}");
                    onThemeChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to Buzz5!', style: AppTextStyles.headingBig),
            SizedBox(height: 120),
            Column(
              children: [
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
                  style: ElevatedButton.styleFrom(minimumSize: Size(300, 80)),
                  child: Text('Start game', style: AppTextStyles.buttonTextBig),
                ),
                SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () {
                    AppLogger.i("Navigating to JoinGamePage");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinGamePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(300, 80), // Width and height
                  ),
                  child: Text('Join Game', style: AppTextStyles.buttonTextBig),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
