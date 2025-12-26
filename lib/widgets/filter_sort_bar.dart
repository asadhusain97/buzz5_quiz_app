// Filter and Sort Bar Widgets
//
// This file contains reusable widgets for filtering and sorting lists.
// These widgets are designed to be used across multiple pages like
// CreatePage, NewBoardPage, etc.
//
// Components:
// - FilterChip: Button that opens a dropdown dialog (for Tags, Status)
// - SearchChip: Button that opens a search dialog (for Name, Creator)
// - SortDropdown: Popup menu for sorting options
// - FilterSortBar: Complete bar combining all filter/sort controls

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';

// ============================================================
// FILTER CHIP WIDGET
// ============================================================

/// A chip button that shows a label and optional value, with dropdown arrow.
/// Used for filters that open a dialog with multiple options (Status, Tags).
class FilterChipButton extends StatelessWidget {
  final String label;
  final String? value;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? ColorConstants.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? ColorConstants.primaryColor
                : ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive
                    ? ColorConstants.primaryColor
                    : ColorConstants.hintGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (value != null) ...[
              Text(
                ': $value',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive
                  ? ColorConstants.primaryColor
                  : ColorConstants.hintGrey,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SEARCH CHIP WIDGET
// ============================================================

/// A chip button with search icon for text search filters.
/// Used for Name and Creator search.
class SearchChipButton extends StatelessWidget {
  final String label;
  final String? value;
  final bool isActive;
  final VoidCallback onTap;

  const SearchChipButton({
    super.key,
    required this.label,
    this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? ColorConstants.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? ColorConstants.primaryColor
                : ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 16,
              color: isActive
                  ? ColorConstants.primaryColor
                  : ColorConstants.hintGrey,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive
                    ? ColorConstants.primaryColor
                    : ColorConstants.hintGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (value != null) ...[
              Text(
                ': $value',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SORT DROPDOWN WIDGET
// ============================================================

/// Sort options available for lists.
enum SortOption {
  nameAZ,
  nameZA,
  difficultyHighToLow,
  difficultyLowToHigh,
  dateNewest,
  dateOldest,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.nameAZ:
        return 'Name: A → Z';
      case SortOption.nameZA:
        return 'Name: Z → A';
      case SortOption.difficultyHighToLow:
        return 'Difficulty: High to Low';
      case SortOption.difficultyLowToHigh:
        return 'Difficulty: Low to High';
      case SortOption.dateNewest:
        return 'Creation Date: Newest first';
      case SortOption.dateOldest:
        return 'Creation Date: Oldest first';
    }
  }
}

/// A dropdown button for selecting sort order.
class SortDropdownButton extends StatelessWidget {
  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;
  final bool showDifficulty;

  const SortDropdownButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    this.showDifficulty = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      tooltip: 'Sort by',
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SortOption.nameAZ,
          child: Text(SortOption.nameAZ.displayName),
        ),
        PopupMenuItem(
          value: SortOption.nameZA,
          child: Text(SortOption.nameZA.displayName),
        ),
        if (showDifficulty) ...[
          PopupMenuDivider(),
          PopupMenuItem(
            value: SortOption.difficultyHighToLow,
            child: Text(SortOption.difficultyHighToLow.displayName),
          ),
          PopupMenuItem(
            value: SortOption.difficultyLowToHigh,
            child: Text(SortOption.difficultyLowToHigh.displayName),
          ),
        ],
        PopupMenuDivider(),
        PopupMenuItem(
          value: SortOption.dateNewest,
          child: Text(SortOption.dateNewest.displayName),
        ),
        PopupMenuItem(
          value: SortOption.dateOldest,
          child: Text(SortOption.dateOldest.displayName),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: ColorConstants.hintGrey),
            SizedBox(width: 6),
            Text(
              currentSort.displayName,
              style: TextStyle(fontSize: 13, color: ColorConstants.hintGrey),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FILTER DIALOGS
// ============================================================

/// Result wrapper for status filter dialog.
/// Needed to distinguish between "cancelled" and "All selected" (both return null status).
class StatusFilterResult {
  final SetStatus? status;
  final bool applied;

  StatusFilterResult({this.status, required this.applied});
}

/// Shows a dialog to filter by status (Complete/Draft).
/// Returns StatusFilterResult with applied=true if user clicked Apply, false if cancelled.
Future<StatusFilterResult?> showStatusFilterDialog({
  required BuildContext context,
  SetStatus? currentStatus,
}) async {
  SetStatus? selectedStatus = currentStatus;

  return showDialog<StatusFilterResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        Widget buildRadioOption(String label, SetStatus? value) {
          final isSelected = selectedStatus == value;
          return InkWell(
            onTap: () {
              setDialogState(() {
                selectedStatus = value;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? ColorConstants.primaryColor
                            : ColorConstants.hintGrey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorConstants.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? ColorConstants.primaryColor : null,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AlertDialog(
          title: Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildRadioOption('All', null),
              buildRadioOption('Complete', SetStatus.complete),
              buildRadioOption('Draft', SetStatus.draft),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                StatusFilterResult(status: selectedStatus, applied: true),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: ColorConstants.lightTextColor,
              ),
              child: Text('Apply'),
            ),
          ],
        );
      },
    ),
  );
}

/// Shows a dialog to filter by tags using checkboxes.
/// Returns the selected tags or null if cancelled.
Future<List<String>?> showTagsFilterDialog({
  required BuildContext context,
  required List<String> availableTags,
  required List<String> selectedTags,
}) async {
  final List<String> tempSelected = List.from(selectedTags);

  return showDialog<List<String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Select Tags'),
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableTags.map((tag) {
              return CheckboxListTile(
                title: Text(_formatTagName(tag)),
                value: tempSelected.contains(tag),
                onChanged: (checked) {
                  setDialogState(() {
                    if (checked == true) {
                      tempSelected.add(tag);
                    } else {
                      tempSelected.remove(tag);
                    }
                  });
                },
                activeColor: ColorConstants.primaryColor,
                dense: true,
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, tempSelected),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: ColorConstants.lightTextColor,
          ),
          child: Text('Apply'),
        ),
      ],
    ),
  );
}

/// Shows a dialog to search by name.
/// Returns the search text or null if cancelled.
Future<String?> showNameSearchDialog({
  required BuildContext context,
  required String currentValue,
  String title = 'Search by Name',
  String hint = 'Enter name',
}) async {
  final controller = TextEditingController(text: currentValue);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: Icon(Icons.search),
        ),
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: ColorConstants.lightTextColor,
          ),
          child: Text('Apply'),
        ),
      ],
    ),
  );
}

/// Shows a dialog to search by creator.
/// Returns the search text or null if cancelled.
Future<String?> showCreatorSearchDialog({
  required BuildContext context,
  required String currentValue,
}) async {
  return showNameSearchDialog(
    context: context,
    currentValue: currentValue,
    title: 'Search by Creator',
    hint: 'Enter creator name',
  );
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/// Formats a tag string to be more readable.
/// e.g., 'foodAndDrinks' -> 'Food & Drinks'
String _formatTagName(String tag) {
  final specialCases = {
    'foodAndDrinks': 'Food & Drinks',
    'popCulture': 'Pop Culture',
    'videoGames': 'Video Games',
    'us': 'US',
  };
  if (specialCases.containsKey(tag)) {
    return specialCases[tag]!;
  }
  // Capitalize first letter
  if (tag.isEmpty) return tag;
  return tag[0].toUpperCase() + tag.substring(1);
}

/// Get all available tag names from the PredefinedTags enum.
List<String> getAvailableTagNames() {
  return PredefinedTags.values.map((tag) {
    return tag.toString().split('.').last;
  }).toList();
}
