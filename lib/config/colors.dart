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
  // Primary purple shades
  static Color primaryColor = hexToColor('#6C63FF'); // Vibrant purple
  static Color primaryContainerColor = hexToColor('#4A3F9F'); // Deeper purple

  // Secondary blue shades
  static Color secondaryColor = hexToColor('#7BB5FF'); // Soft blue
  static Color secondaryContainerColor = hexToColor('#3A83E0'); // Deeper blue

  // Tertiary accents
  static Color tertiaryColor = hexToColor('#E0E4FF'); // Light lilac
  static Color tertiaryContainerColor = hexToColor('#8A8EDA'); // Muted purple

  // Feedback colors
  static Color errorColor = hexToColor('#FF7C9C'); // Soft red
  static Color errorContainerColor = hexToColor('#CF3868'); // Deeper red
  static Color successColor = hexToColor('#6BCB77'); // Mint green

  // Text colors
  static Color lightTextColor = hexToColor('#FFFFFF'); // Pure white
  static Color darkTextColor = hexToColor('#1A1A2E'); // Deep navy
  static Color hintGrey = hexToColor('#717C98'); // Soft grey

  // Button colors
  static Color correctAnsBtn = hexToColor('#6BCB77'); // Mint green
  static Color wrongAnsBtn = hexToColor('#FF7C9C'); // Soft red
  static Color ansBtn = hexToColor('#6C63FF'); // Primary purple

  // Background colors
  static Color backgroundColor = hexToColor('#FAFAFA'); // Off-white
  static Color surfaceColor = hexToColor('#FFFFFF'); // Pure white
  static Color cardColor = hexToColor('#F5F5FF'); // Very soft purple
  static Color darkCardColor = hexToColor('#240264'); // Persian Indigo

  // Ranking colors - Temperature-based system (hot to cool)
  static Color rank1Color = hexToColor('#DC2626'); // Hot red - 1st place
  static Color rank2Color = hexToColor('#F59E0B'); // Orange - 2nd place
  static Color rank3Color = hexToColor('#EAB308'); // Yellow - 3rd place
  static Color championTierColor = hexToColor(
    '#84CC16',
  ); // Light green - ranks 4-10
  static Color veteranTierColor = hexToColor('#06B6D4'); // Cyan - ranks 11-25
  static Color challengerTierColor = hexToColor(
    '#3B82F6',
  ); // Cool blue - ranks 26-50
}
