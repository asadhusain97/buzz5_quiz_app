import 'dart:ui';
import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  assert(
    RegExp(r'^#([0-9a-fA-F]{6})|([0-9a-fA-F]{8})$').hasMatch(hex),
    'hex color must be #rrggbb or #rrggbbaa',
  );

  return Color(
    int.parse(hex.substring(1), radix: 16) +
        (hex.length == 7 ? 0xff000000 : 0x00000000),
  );
}

class ColorConstants {
  static Color primaryContainerColor = Color(0xFF293CA0);
  static Color primaryColor = Color(0xFFBAC3FF);
  static Color secondaryColor = Color(0xFFAEC6FF);
  static Color secondaryContainerColor = Color(0xFF14448D);
  static Color tertiaryColor = Color(0xFFA9CDCF);
  static Color tertiaryContainerColor = Color(0xFF2A4C4E);
  static Color errorColor = Color(0xFFFFB4AB);
  static Color errorContainerColor = Color(0xFF93000A);
  static Color lightTextColor = hexToColor('#F6F7EB');
  static Color darkTextColor = hexToColor('#0D1931');
}
