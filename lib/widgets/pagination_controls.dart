import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

/// A reusable widget for pagination controls.
///
/// Features:
/// - Previous/Next buttons
/// - Page X of Y display
/// - Consistent styling with the rest of the app
class PaginationControls extends StatelessWidget {
  /// Current page index (0-based)
  final int currentPage;

  /// Total number of pages
  final int totalPages;

  /// Callback when page changes (receives new 0-based page index)
  final Function(int) onPageChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          _buildPaginationButton(
            context,
            icon: Icons.chevron_left,
            label: 'Prev',
            isEnabled: currentPage > 0,
            onTap: () => onPageChanged(currentPage - 1),
            isDark: isDark,
          ),

          const SizedBox(width: 24),

          // Page Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${currentPage + 1} of $totalPages',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark
                        ? ColorConstants.lightTextColor
                        : ColorConstants.darkTextColor,
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Next Button
          _buildPaginationButton(
            context,
            icon: Icons.chevron_right,
            label: 'Next',
            isRightIcon: true,
            isEnabled: currentPage < totalPages - 1,
            onTap: () => onPageChanged(currentPage + 1),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    required bool isDark,
    bool isRightIcon = false,
  }) {
    final Color buttonColor =
        isEnabled
            ? ColorConstants.primaryColor
            : (isDark ? Colors.white30 : Colors.black26);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (!isRightIcon) ...[
              Icon(icon, size: 20, color: buttonColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: buttonColor,
              ),
            ),
            if (isRightIcon) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 20, color: buttonColor),
            ],
          ],
        ),
      ),
    );
  }
}
