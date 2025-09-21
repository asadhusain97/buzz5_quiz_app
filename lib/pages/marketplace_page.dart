import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.i("MarketplacePage built");

    return Scaffold(
      appBar: CustomAppBar(title: "Marketplace", showBackButton: true),
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store,
                  size: 80,
                  color: ColorConstants.primaryColor,
                ),
                const SizedBox(height: 32),
                Text(
                  'Marketplace',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ColorConstants.lightTextColor
                        : ColorConstants.primaryContainerColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This feature is coming soon!\nBrowse and purchase quiz question sets.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: ColorConstants.hintGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}