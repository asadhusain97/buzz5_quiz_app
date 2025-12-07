import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';

/// A widget that handles common content states: loading, error, and empty.
/// Displays appropriate UI for each state, or the [content] when data is available.
class ContentStateBuilder extends StatelessWidget {
  /// Whether data is currently loading
  final bool isLoading;

  /// Error message if an error occurred (null if no error)
  final String? errorMessage;

  /// Whether the data list is empty
  final bool isEmpty;

  /// Icon to show in empty state
  final IconData emptyIcon;

  /// Title for empty state
  final String emptyTitle;

  /// Subtitle for empty state
  final String emptySubtitle;

  /// Title for error state (defaults to "Error loading data")
  final String? errorTitle;

  /// Callback when retry button is pressed
  final VoidCallback? onRetry;

  /// The actual content to display when data is available
  final Widget content;

  const ContentStateBuilder({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.errorTitle,
    this.onRetry,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: ColorConstants.primaryColor),
      );
    }

    // Error state
    if (errorMessage != null) {
      return _buildErrorState();
    }

    // Empty state
    if (isEmpty) {
      return _buildEmptyState();
    }

    // Content
    return content;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: ColorConstants.errorColor,
          ),
          SizedBox(height: 16),
          Text(
            errorTitle ?? 'Error loading data',
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.errorColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(
              color: ColorConstants.hintGrey,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: 64,
            color: ColorConstants.hintGrey,
          ),
          SizedBox(height: 16),
          Text(
            emptyTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.hintGrey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            emptySubtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: ColorConstants.hintGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
