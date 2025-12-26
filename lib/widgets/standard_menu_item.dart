import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

/// A standard menu item with consistent styling for icons and text.
/// Uses white/light grey colors as requested for dark mode consistency.
class StandardMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const StandardMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.color, // Optional override, but defaults to standard
  });

  @override
  Widget build(BuildContext context) {
    // Default to lightTextColor (white) if no color provided
    // or if the provided color was intended to be "standard"
    final effectiveColor = color ?? ColorConstants.lightTextColor;

    return Row(
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
