// Create New Board Page
//
// This page handles creating new quiz boards.
// Currently a placeholder - implementation coming soon.
//
// Planned features:
// - Board name and description input
// - Select sets to include in board (max 5)
// - Configure board settings and difficulty

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';

class CreateNewBoardPage extends StatelessWidget {
  const CreateNewBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Board', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
      ),
      body: Center(
        child: Text(
          'Create New Board Page - Coming Soon',
          style: AppTextStyles.titleMedium.copyWith(
            color: ColorConstants.hintGrey,
          ),
        ),
      ),
    );
  }
}
