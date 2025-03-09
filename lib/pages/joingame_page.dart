import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';

class JoinGamePage extends StatelessWidget {
  const JoinGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Join a game", showBackButton: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Coming soon..", style: AppTextStyles.headingBig),
            SizedBox(height: 20),
            Text(
              "A buzzer app where players can join together and buzz",
              style: AppTextStyles.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
