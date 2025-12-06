// Board List Item Tile Component
//
// This component displays a single board item in a list view, used primarily
// on the Create page's Boards tab. It shows:
// - Board name with status badge (Complete/Draft)
// - Description (truncated to 2 lines)
// - Metadata: set count and last modified time
// - Action menu (edit, duplicate, delete)
//
// The component supports selection state for bulk operations.

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';

/// A tile widget that displays a board item with its metadata and actions.
///
/// This widget is designed for use in list views where boards are displayed
/// with selection capability and action menus.
class BoardListItemTile extends StatelessWidget {
  final BoardModel board;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const BoardListItemTile({
    super.key,
    required this.board,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  /// Converts a DateTime to a human-readable relative time string.
  /// Examples: "just now", "5m ago", "2h ago", "3d ago", "2mo ago"
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.darkCard
              : ColorConstants.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to board detail/edit page
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opening ${board.name}...')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Board name and status badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            board.name,
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
                        const SizedBox(width: 8),
                        // Status badge (Complete = green, Draft = orange)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                board.status == BoardStatus.complete
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            board.status == BoardStatus.complete
                                ? 'Complete'
                                : 'Draft',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  board.status == BoardStatus.complete
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description (truncated)
                    Text(
                      board.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorConstants.hintGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Metadata row: set count and last modified
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sets count indicator
                        Icon(
                          Icons.layers,
                          size: 14,
                          color: ColorConstants.hintGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${board.setCount}/5 sets',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        // Last modified indicator
                        Icon(
                          Icons.edit_calendar,
                          size: 14,
                          color: ColorConstants.hintGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Modified ${_getRelativeTime(board.modifiedDate)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: ColorConstants.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy,
                              size: 20,
                              color: ColorConstants.secondaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: ColorConstants.errorColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: ColorConstants.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                onSelected: (String value) {
                  // TODO: Implement board actions
                  AppLogger.i('Selected: $value for board: ${board.name}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value: ${board.name}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
