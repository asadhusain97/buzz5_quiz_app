import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';

class QuestionSet {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final int questionCount;
  final String category;
  final bool isPublic;

  QuestionSet({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.questionCount,
    required this.category,
    required this.isPublic,
  });
}

class SetListItem extends StatelessWidget {
  final QuestionSet questionSet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SetListItem({
    super.key,
    required this.questionSet,
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
              // Header row with title, icon and visibility badge
              Row(
                children: [
                  Icon(
                    Icons.collections_outlined,
                    color: ColorConstants.primaryColor,
                    size: AppConstants.defaultIconSize,
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Expanded(
                    child: Text(
                      questionSet.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  _buildVisibilityBadge(),
                ],
              ),
              const SizedBox(height: AppConstants.smallSpacing),

              // Description
              Text(
                questionSet.description,
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
                  _buildQuestionCountText(),
                  const Spacer(),
                  _buildDateText(),
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

  Widget _buildVisibilityBadge() {
    return Container(
      padding: AppConstants.extraSmallPadding.copyWith(
        left: AppConstants.smallSpacing,
        right: AppConstants.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: questionSet.isPublic
            ? ColorConstants.info.withValues(alpha: 0.1)
            : ColorConstants.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            questionSet.isPublic ? Icons.public : Icons.lock_outline,
            size: AppConstants.smallIconSize,
            color: questionSet.isPublic
                ? ColorConstants.info
                : ColorConstants.warning,
          ),
          const SizedBox(width: 2),
          Text(
            questionSet.isPublic ? 'Public' : 'Private',
            style: AppTextStyles.labelSmall.copyWith(
              color: questionSet.isPublic
                  ? ColorConstants.info
                  : ColorConstants.warning,
            ),
          ),
        ],
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
        questionSet.category,
        style: AppTextStyles.labelSmall.copyWith(
          color: ColorConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildQuestionCountText() {
    return Text(
      '${questionSet.questionCount} questions',
      style: AppTextStyles.bodySmall.copyWith(
        color: ColorConstants.hintGrey,
      ),
    );
  }

  Widget _buildDateText() {
    return Text(
      _formatDate(questionSet.createdAt),
      style: AppTextStyles.labelSmall.copyWith(
        color: ColorConstants.hintGrey,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}