import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';
import 'package:buzz5_quiz_app/widgets/creations/filter_section.dart';

class FilterState {
  String searchQuery;
  String selectedCategory;
  String tagsQuery;
  Set<String> selectedStatuses;

  FilterState({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.tagsQuery = '',
    this.selectedStatuses = const {'All'},
  });

  FilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    String? tagsQuery,
    Set<String>? selectedStatuses,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      tagsQuery: tagsQuery ?? this.tagsQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterState &&
        other.searchQuery == searchQuery &&
        other.selectedCategory == selectedCategory &&
        other.tagsQuery == tagsQuery &&
        other.selectedStatuses.toString() == selectedStatuses.toString();
  }

  @override
  int get hashCode {
    return Object.hash(
      searchQuery,
      selectedCategory,
      tagsQuery,
      selectedStatuses.toString(),
    );
  }
}

class FilterPanel extends StatefulWidget {
  final FilterState initialState;
  final ValueChanged<FilterState> onFiltersChanged;
  final List<String> categories;

  const FilterPanel({
    super.key,
    required this.initialState,
    required this.onFiltersChanged,
    this.categories = const ['All', 'Science', 'History', 'Sports', 'Technology', 'Art'],
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late TextEditingController _searchController;
  late TextEditingController _tagsController;
  late FilterState _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    _searchController = TextEditingController(text: _currentState.searchQuery);
    _tagsController = TextEditingController(text: _currentState.tagsQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _updateFilters(FilterState newState) {
    setState(() {
      _currentState = newState;
    });
    widget.onFiltersChanged(newState);
  }

  void _clearFilters() {
    final clearedState = FilterState();
    _searchController.text = clearedState.searchQuery;
    _tagsController.text = clearedState.tagsQuery;
    _updateFilters(clearedState);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ColorConstants.darkCard
            : ColorConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(
          color: ColorConstants.hintGrey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorConstants.lightTextColor
                      : ColorConstants.darkTextColor,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Search Filter
          FilterSection.search(
            title: 'Search',
            controller: _searchController,
            hintText: 'Search items...',
            onChanged: (value) {
              _updateFilters(_currentState.copyWith(searchQuery: value));
            },
          ),

          // Category Filter
          FilterSection.dropdown(
            title: 'Category',
            value: _currentState.selectedCategory,
            items: widget.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateFilters(_currentState.copyWith(selectedCategory: value));
              }
            },
          ),

          // Tags Filter
          FilterSection(
            title: 'Tags',
            type: FilterType.textField,
            child: TextFormField(
              controller: _tagsController,
              onChanged: (value) {
                _updateFilters(_currentState.copyWith(tagsQuery: value));
              },
              decoration: InputDecoration(
                hintText: 'Enter tags...',
                hintStyle: AppTextStyles.hintText,
                prefixIcon: Icon(
                  Icons.tag,
                  color: ColorConstants.hintGrey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                  borderSide: BorderSide(
                    color: ColorConstants.hintGrey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                  borderSide: BorderSide(
                    color: ColorConstants.hintGrey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                  borderSide: BorderSide(
                    color: ColorConstants.primaryColor,
                  ),
                ),
                contentPadding: AppConstants.smallPadding,
                isDense: true,
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ),

          // Status Filter
          FilterSection.chips(
            title: 'Status',
            options: const ['All', 'Complete', 'Drafts'],
            selectedOptions: _currentState.selectedStatuses,
            onSelectionChanged: (selectedStatuses) {
              _updateFilters(_currentState.copyWith(
                selectedStatuses: selectedStatuses,
              ));
            },
            multiSelect: false,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}