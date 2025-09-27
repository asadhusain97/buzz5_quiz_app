import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';

class FilteredContentList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyStateWidget;
  final bool isLoading;
  final String? loadingText;
  final EdgeInsets? padding;
  final ScrollController? scrollController;

  const FilteredContentList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.emptyStateWidget,
    this.isLoading = false,
    this.loadingText,
    this.padding,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (items.isEmpty) {
      return emptyStateWidget ?? _buildDefaultEmptyState();
    }

    return ListView.separated(
      controller: scrollController,
      padding: padding ?? AppConstants.defaultPadding,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: AppConstants.cardSpacing,
      ),
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorConstants.primaryColor,
          ),
          if (loadingText != null) ...[
            const SizedBox(height: AppConstants.defaultSpacing),
            Text(
              loadingText!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorConstants.hintGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: AppConstants.extraLargeIconSize + 16,
            color: ColorConstants.hintGrey,
          ),
          const SizedBox(height: AppConstants.defaultSpacing),
          Text(
            'No items found',
            style: AppTextStyles.titleLarge.copyWith(
              color: ColorConstants.hintGrey,
            ),
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Text(
            'Try adjusting your filters',
            style: AppTextStyles.bodyMedium.copyWith(
              color: ColorConstants.hintGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.largePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppConstants.extraLargeIconSize + 16,
              color: ColorConstants.hintGrey,
            ),
            const SizedBox(height: AppConstants.defaultSpacing),
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              subtitle,
              style: AppTextStyles.bodyLarge.copyWith(
                color: ColorConstants.hintGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: AppConstants.defaultSpacing),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}