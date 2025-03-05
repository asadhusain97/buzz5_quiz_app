import 'package:buzz5_quiz_app/config/constants.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';

class InstructionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Instructions", showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("How to Play", style: AppTextStyles.headingBig),
                SizedBox(height: 20),
                Text(
                  "1. Create or join a game.",
                  style: AppTextStyles.titleSmall,
                ),
                Text(
                  "2. Answer the questions as quickly as possible.",
                  style: AppTextStyles.titleSmall,
                ),
              ],
            ),
            SizedBox(width: 40),
            Column(mainAxisAlignment: MainAxisAlignment.center),
          ],
        ),
      ),
    );
  }
}
