// Board List Item Tile Component
//
// This component displays a single board item in a list view, used primarily
// on the Create page's Boards tab. It shows:
// - Board name with draft indicator (vertical teal bar when draft)
// - Description (truncated to 2 lines)
// - Action menu (edit, duplicate, delete)
//
// The component supports selection state for bulk operations.
// Design matches SetListItemTile for consistency.

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/widgets/standard_menu_item.dart';

/// Draft indicator color for boards (teal - different from orange for sets)
const Color kBoardDraftColor = Color(0xFF00897B); // Teal 600

/// A tile widget that displays a board item with its metadata and actions.
///
/// This widget is designed for use in list views where boards are displayed
/// with selection capability and action menus.
class BoardListItemTile extends StatelessWidget {
  final BoardModel board;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const BoardListItemTile({
    super.key,
    required this.board,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if board is in draft status for visual indicator
    final isDraft = board.status == BoardStatus.draft;

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
                  color: kBoardDraftColor,
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
              left: 29.0,
              right: 16.0,
              top: 16.0,
              bottom: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Selection checkbox (vertically centered)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged(value ?? false),
                  activeColor: ColorConstants.primaryColor,
                ),

                const SizedBox(width: 12),

                // Main content area - name and description only
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Board name
                      Text(
                        board.name,
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

                      // Description (truncated)
                      Text(
                        board.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorConstants.hintGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
