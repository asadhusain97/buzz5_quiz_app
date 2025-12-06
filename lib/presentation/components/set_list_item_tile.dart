// Set List Item Tile Component
//
// This component displays a single set item in a list view, used primarily
// on the Create page's Sets tab. It shows:
// - Set name with draft indicator (vertical orange bar when draft)
// - Rating and download statistics
// - Description (truncated to 2 lines)
// - Difficulty badge and tag chips
// - Action menu (edit, duplicate, delete)
//
// The component supports selection state for bulk operations.

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/stat_displays.dart';
import 'package:buzz5_quiz_app/widgets/standard_menu_item.dart';

/// A tile widget that displays a set item with its metadata and actions.
///
/// This widget is designed for use in list views where sets are displayed
/// with selection capability and action menus.
class SetListItemTile extends StatelessWidget {
  final SetModel set;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const SetListItemTile({
    super.key,
    required this.set,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  /// Formats a PredefinedTags enum value to a human-readable string.
  /// Handles special cases like 'foodAndDrinks' -> 'Food & Drinks'.
  String _formatTagName(PredefinedTags tag) {
    final name = tag.toString().split('.').last;
    final specialCases = {
      'foodAndDrinks': 'Food & Drinks',
      'popCulture': 'Pop Culture',
      'videoGames': 'Video Games',
      'us': 'US',
    };
    if (specialCases.containsKey(name)) {
      return specialCases[name]!;
    }
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Converts a DifficultyLevel enum to a display label.
  String _getDifficultyLabel(DifficultyLevel? difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if set is in draft status for visual indicator
    final isDraft = set.status == SetStatus.draft;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.darkCard
              : ColorConstants.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // Vertical draft indicator on the left edge
          if (isDraft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 17,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'DRAFT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Main content with adjusted padding for draft indicator
          Padding(
            padding: EdgeInsets.only(
              left: isDraft ? 29.0 : 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Selection checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged(value ?? false),
                  activeColor: ColorConstants.primaryColor,
                ),

                const SizedBox(width: 12),

                // Main content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Set name with rating and downloads in same row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              set.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? ColorConstants.lightTextColor
                                        : ColorConstants.darkTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Rating display
                          RatingDisplay(rating: set.rating),

                          SizedBox(width: 12),

                          // Downloads display
                          DownloadDisplay(downloads: set.downloads),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Description (truncated)
                      Text(
                        set.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorConstants.hintGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Difficulty badge and tags row
                      Row(
                        children: [
                          // Difficulty chip (outlined style)
                          if (set.difficulty != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: ColorConstants.hintGrey.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getDifficultyLabel(set.difficulty),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstants.lightTextColor,
                                ),
                              ),
                            ),

                            SizedBox(width: 12),

                            // Vertical divider between difficulty and tags
                            Container(
                              width: 1,
                              height: 24,
                              color: ColorConstants.hintGrey.withValues(
                                alpha: 0.2,
                              ),
                            ),

                            SizedBox(width: 12),
                          ],

                          // Tag chips (show up to 3, then "+N" for more)
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                ...set.tags
                                    .take(3)
                                    .map(
                                      (tag) => Chip(
                                        label: Text(
                                          _formatTagName(tag),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(fontSize: 11),
                                        ),
                                        backgroundColor: ColorConstants
                                            .primaryColor
                                            .withValues(alpha: 0.2),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 0,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                // Overflow indicator for additional tags
                                if (set.tags.length > 3)
                                  Chip(
                                    label: Text(
                                      '+${set.tags.length - 3}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        fontSize: 11,
                                        color: ColorConstants.primaryColor,
                                      ),
                                    ),
                                    backgroundColor: ColorConstants.primaryColor
                                        .withValues(alpha: 0.1),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 0,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Actions popup menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? ColorConstants.lightTextColor
                            : ColorConstants.darkTextColor,
                  ),
                  itemBuilder:
                      (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: StandardMenuItem(
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'duplicate',
                          child: StandardMenuItem(
                            icon: Icons.copy,
                            label: 'Duplicate',
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: StandardMenuItem(
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ),
                      ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'duplicate':
                        onDuplicate?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
