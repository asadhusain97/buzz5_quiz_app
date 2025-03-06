import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/constants.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

const String howToPlayMD = """
  ## How to Play
  - Enter **unique** player names
  - **Choose a round** on the next page, and the **question board** will load accordingly
  - The board has **5 sets** of **5 questions**, each with varying difficulty and points
  - A **random** player starts _(yellow border indicates the player in control of the board)_  
  - The selected player/ player in control **chooses a question from a set**  
  - **Be quick** to buzz to answer and earn points, but beware of **negative points** for wrong answers  
  - The player **retains control** to pick the next question until another player scores
  """;
const String aboutThisGameMD = """
  ## About This Game
  This game is inspired by the **[Buzzing with Kvizzing](https://youtu.be/Tku6Mk5zMjE?si=_zex3Ixa9kQFhGNO)** video series by *Kumar Varun*.

  All **questions and answers** are stored and updated from [**this sheet**](https://docs.google.com/spreadsheets/d/149cG62dE_5H9JYmNYoJ_h0w5exYSFNY-HvX8Yq-HZrI/edit?usp=sharing).
  """;

class InstructionsPage extends StatelessWidget {
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Instructions", showBackButton: true),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 40,
              bottom: 10,
              right: 10,
              top: 10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: howToPlayMD,
                  selectable: false,
                  styleSheet: MarkdownStyleSheet(
                    h2: AppTextStyles.titleBig,
                    p: AppTextStyles.bodySmall,
                  ),
                ),
                SizedBox(height: 60),
                MarkdownBody(
                  data: aboutThisGameMD,
                  selectable: false,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      _launchURL(href);
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    h2: AppTextStyles.titleBig,
                    p: AppTextStyles.bodySmall,
                  ),
                ),
                SizedBox(height: 60),
                Text(
                  "Get ready, think fast, and have fun! 🎉",
                  style: AppTextStyles.titleBig,
                ),
              ],
            ),
          ),
          Flexible(child: const PlayerNameForm()),
        ],
      ),
    );
  }
}

class PlayerNameForm extends StatelessWidget {
  const PlayerNameForm({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600.0,
      height: 800.0,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          bottom: 150,
          right: 40,
          top: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 0,
                bottom: 0,
                right: 0,
                top: 0,
              ),
              child: Text("Enter player names"),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const PlayerTextField(),
                    SizedBox(height: 10),
                    const PlayerTextField(),
                    SizedBox(height: 10),
                    const PlayerTextField(),
                    SizedBox(height: 10),
                    const PlayerTextField(),
                  ],
                ),
                Column(
                  children: [
                    const PlayerTextField(),
                    SizedBox(height: 10),
                    const PlayerTextField(),
                    SizedBox(height: 10),
                    const PlayerTextField(),
                    SizedBox(height: 10),
                    const PlayerTextField(),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(
                left: 0,
                bottom: 0,
                right: 0,
                top: 0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Add your onPressed code here!
                },
                style: ElevatedButton.styleFrom(minimumSize: Size(150, 40)),
                child: Text("Lets Go!", style: AppTextStyles.buttonTextSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerTextField extends StatelessWidget {
  const PlayerTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.0, // Set your desired width
      height: 50.0, // Set your desired height
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Enter player name',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: ColorConstants.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: ColorConstants.secondaryColor),
          ),
          hintStyle: TextStyle(color: ColorConstants.lightTextColor),
        ),
      ),
    );
  }
}
