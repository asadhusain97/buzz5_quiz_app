// Discover Set Tile Component
//
// This component displays a set item in the Discover/Marketplace page.
// It shows:
// - Set name and author
// - Rating and download statistics
// - Description (truncated to 2 lines)
// - Difficulty badge and tag chips
// - "Add to Collection" button (hidden for user's own sets)

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/stat_displays.dart';

/// A tile widget that displays a set item in the marketplace/discover page.
class DiscoverSetTile extends StatelessWidget {
  final SetModel set;
  final bool isOwnSet;
  final bool isAdded;
  final VoidCallback? onAddToCollection;

  const DiscoverSetTile({
    super.key,
    required this.set,
    required this.isOwnSet,
    this.isAdded = false,
    this.onAddToCollection,
  });

  /// Formats a PredefinedTags enum value to a human-readable string.
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.darkCard
              : ColorConstants.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Name, Author, Stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set name and author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Set name
                      Text(
                        set.name,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? ColorConstants.lightTextColor
                                  : ColorConstants.darkTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      // Author name with "by" prefix
                      Row(
                        children: [
                          Text(
                            'by ',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: ColorConstants.hintGrey),
                          ),
                          Text(
                            set.authorName,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: ColorConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isOwnSet) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstants.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Your Set',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Stats: Rating and Downloads
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingDisplay(rating: set.rating),
                    SizedBox(width: 12),
                    DownloadDisplay(downloads: set.downloads),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              set.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ColorConstants.hintGrey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Bottom row: Difficulty, Tags, and Action Button
            Row(
              children: [
                // Difficulty chip
                if (set.difficulty != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ColorConstants.hintGrey.withValues(alpha: 0.5),
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
                  // Vertical divider
                  Container(
                    width: 1,
                    height: 24,
                    color: ColorConstants.hintGrey.withValues(alpha: 0.2),
                  ),
                  SizedBox(width: 12),
                ],

                // Tag chips (show up to 2, then "+N")
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ...set.tags
                          .take(2)
                          .map(
                            (tag) => Chip(
                              label: Text(
                                _formatTagName(tag),
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              backgroundColor: ColorConstants.primaryColor
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
                      if (set.tags.length > 2)
                        Chip(
                          label: Text(
                            '+${set.tags.length - 2}',
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

                // "Add to Collection" button or "Added" state
                if (!isOwnSet) ...[
                  if (isAdded)
                    // Show "Added" state with checkmark
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Added',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (onAddToCollection != null)
                    // Show "Add to your collection" button
                    ElevatedButton.icon(
                      onPressed: onAddToCollection,
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add to your collection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: ColorConstants.lightTextColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size(80, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
