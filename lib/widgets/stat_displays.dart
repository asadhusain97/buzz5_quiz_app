import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

/// A consistent widget for displaying ratings with a star icon
/// Used across the app for set cards, boards, etc.
class RatingDisplay extends StatelessWidget {
  final double rating;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.iconSize = 16,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_border_rounded, size: iconSize, color: Colors.amber),
        SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: ColorConstants.lightTextColor,
          ),
        ),
      ],
    );
  }
}

/// A consistent widget for displaying download counts
/// Used across the app for set cards, boards, etc.
class DownloadDisplay extends StatelessWidget {
  final int downloads;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;

  const DownloadDisplay({
    super.key,
    required this.downloads,
    this.iconSize = 16,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.file_download_outlined,
          size: iconSize,
          color: ColorConstants.lightTextColor,
        ),
        SizedBox(width: 4),
        Text(
          _formatDownloads(downloads),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: ColorConstants.lightTextColor,
          ),
        ),
      ],
    );
  }

  /// Format download numbers for display
  /// e.g., 1234 -> "1.2K", 1000000 -> "1M"
  String _formatDownloads(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
