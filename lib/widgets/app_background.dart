import 'package:flutter/material.dart';
import 'dart:ui';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                Theme.of(context).brightness == Brightness.light
                    ? 'assets/images/light_background.png'
                    : 'assets/images/dark_background.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Blur layer
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX:
                7.0, // Horizontal blur amount (adjust for desired blur level)
            sigmaY: 7.0, // Vertical blur amount (adjust for desired blur level)
          ),
          child: Container(
            color: Colors.transparent, // Important to keep transparent
          ),
        ),
        // Content layer
        child,
      ],
    );
  }
}
