import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              Theme.of(context).brightness == Brightness.light
                  ? [
                    ColorConstants.backgroundColor,
                    ColorConstants.darkTextColor,
                  ] // Light theme gradient (white to dark)
                  : [
                    ColorConstants.darkTextColor,
                    ColorConstants.backgroundColor,
                  ], // Dark theme gradient
        ),
      ),
      child: child,
    );
  }
}
