import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

class AppTextStyles {
  static const TextStyle headingBig = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headingSmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle titleBig = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle buttonTextBig = TextStyle(fontSize: 24);
  static const TextStyle buttonTextSmall = TextStyle(fontSize: 16);
  static const TextStyle bodyBig = TextStyle(fontSize: 18);
  static const TextStyle body = TextStyle(fontSize: 16);
  static const TextStyle bodySmall = TextStyle(fontSize: 14);
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
  static TextStyle hintText = TextStyle(
    fontSize: 14,
    color: ColorConstants.hintGrey,
    fontWeight: FontWeight.w200,
    fontStyle: FontStyle.italic,
  );
  static TextStyle scoreSubtitle = TextStyle(
    fontSize: 12,
    color: ColorConstants.surfaceColor,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );
  static TextStyle scoreCard = TextStyle(
    fontSize: 18,
    color: ColorConstants.cardColor,
    fontWeight: FontWeight.w600,
  );
  static TextStyle gameStatTitles = TextStyle(
    fontSize: 20,
    color: ColorConstants.primaryColor,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w700,
  );
}
