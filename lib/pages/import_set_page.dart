// Import Set Page
//
// This page handles importing quiz sets from external sources.
// Currently a placeholder - implementation coming soon.
//
// Planned features:
// - Import from file upload
// - Import from URL/link
// - Preview imported data before saving

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';

class ImportSetPage extends StatelessWidget {
  const ImportSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Set', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
      ),
      body: Center(
        child: Text(
          'Import Set Page - Coming Soon',
          style: AppTextStyles.titleMedium.copyWith(
            color: ColorConstants.hintGrey,
          ),
        ),
      ),
    );
  }
}
