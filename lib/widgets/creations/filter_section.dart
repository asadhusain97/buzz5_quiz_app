import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';

enum FilterType {
  search,
  dropdown,
  chips,
  textField,
}

class FilterSection extends StatelessWidget {
  final String title;
  final FilterType type;
  final Widget child;
  final bool showDivider;

  const FilterSection({
    super.key,
    required this.title,
    required this.type,
    required this.child,
    this.showDivider = true,
  });

  factory FilterSection.search({
    required String title,
    required TextEditingController controller,
    String? hintText,
    ValueChanged<String>? onChanged,
    bool showDivider = true,
  }) {
    return FilterSection(
      title: title,
      type: FilterType.search,
      showDivider: showDivider,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          hintStyle: AppTextStyles.hintText,
          prefixIcon: Icon(
            Icons.search,
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
    );
  }

  factory FilterSection.dropdown({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    ValueChanged<String?>? onChanged,
    bool showDivider = true,
  }) {
    return FilterSection(
      title: title,
      type: FilterType.dropdown,
      showDivider: showDivider,
      child: Builder(
        builder: (context) => DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
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
          dropdownColor: Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.darkCard
              : ColorConstants.surfaceColor,
        ),
      ),
    );
  }

  factory FilterSection.chips({
    required String title,
    required List<String> options,
    required Set<String> selectedOptions,
    required ValueChanged<Set<String>> onSelectionChanged,
    bool multiSelect = true,
    bool showDivider = true,
  }) {
    return FilterSection(
      title: title,
      type: FilterType.chips,
      showDivider: showDivider,
      child: Wrap(
        spacing: AppConstants.smallSpacing,
        runSpacing: AppConstants.smallSpacing,
        children: options.map((option) {
          final isSelected = selectedOptions.contains(option);
          return FilterChip(
            label: Text(
              option,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? ColorConstants.lightTextColor
                    : ColorConstants.hintGrey,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              final newSelection = Set<String>.from(selectedOptions);
              if (multiSelect) {
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
              } else {
                newSelection.clear();
                if (selected) {
                  newSelection.add(option);
                }
              }
              onSelectionChanged(newSelection);
            },
            backgroundColor: Colors.transparent,
            selectedColor: ColorConstants.primaryColor,
            checkmarkColor: ColorConstants.lightTextColor,
            side: BorderSide(
              color: isSelected
                  ? ColorConstants.primaryColor
                  : ColorConstants.hintGrey.withValues(alpha: 0.3),
            ),
            padding: AppConstants.extraSmallPadding,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? ColorConstants.lightTextColor
                : ColorConstants.darkTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        child,
        if (showDivider) ...[
          const SizedBox(height: AppConstants.defaultSpacing),
          Divider(
            color: ColorConstants.hintGrey.withValues(alpha: 0.2),
            thickness: 0.5,
          ),
          const SizedBox(height: AppConstants.defaultSpacing),
        ],
      ],
    );
  }
}