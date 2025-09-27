import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';
import 'package:buzz5_quiz_app/models/question.dart';

class QuestionListItem extends StatelessWidget {
  final Question question;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const QuestionListItem({
    super.key,
    required this.question,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question.questionName,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: AppConstants.smallSpacing),

              // Question text
              Text(
                question.questionText,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.smallSpacing),

              // Metadata row
              Row(
                children: [
                  _buildCategoryChip(),
                  const SizedBox(width: AppConstants.smallSpacing),
                  _buildPointsText(),
                  const Spacer(),
                  _buildDifficultyText(),
                ],
              ),
              const SizedBox(height: AppConstants.defaultSpacing),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        padding: AppConstants.smallButtonPadding,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Edit'),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: AppConstants.smallSpacing),
                  if (onDelete != null)
                    OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        padding: AppConstants.smallButtonPadding,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: ColorConstants.errorColor,
                        side: BorderSide(
                          color: ColorConstants.errorColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = question.isActive;
    return Container(
      padding: AppConstants.extraSmallPadding.copyWith(
        left: AppConstants.smallSpacing,
        right: AppConstants.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? ColorConstants.success.withValues(alpha: 0.1)
            : ColorConstants.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
      ),
      child: Text(
        isActive ? 'Active' : 'Draft',
        style: AppTextStyles.labelSmall.copyWith(
          color: isActive ? ColorConstants.success : ColorConstants.warning,
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: AppConstants.extraSmallPadding.copyWith(
        left: AppConstants.smallSpacing,
        right: AppConstants.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
      ),
      child: Text(
        question.category,
        style: AppTextStyles.labelSmall.copyWith(
          color: ColorConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildPointsText() {
    return Text(
      '${question.points} points',
      style: AppTextStyles.bodySmall.copyWith(
        color: ColorConstants.hintGrey,
      ),
    );
  }

  Widget _buildDifficultyText() {
    return Text(
      question.difficulty.name.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: _getDifficultyColor(question.difficulty),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return ColorConstants.success;
      case Difficulty.medium:
        return ColorConstants.warning;
      case Difficulty.hard:
        return ColorConstants.errorColor;
    }
  }
}