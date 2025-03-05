import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/constants.dart';
import 'package:buzz5_quiz_app/pages/instructions_page.dart';
import 'package:buzz5_quiz_app/pages/joingame_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Function(bool) onThemeChanged;

  HomePage({required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InstructionsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(300, 80), // Width and height
                  ),
                  child: Text('Start game', style: AppTextStyles.buttonTextBig),
                ),
                SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () {
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
