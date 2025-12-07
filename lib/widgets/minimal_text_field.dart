import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';

/// A minimal styled text field used consistently across the app.
/// Provides a clean, outlined appearance matching the app's design language.
class MinimalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final bool isSmall;
  final TextInputType? keyboardType;
  final String? prefixText;
  final bool enabled;
  final String? Function(String?)? validator;

  const MinimalTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.isSmall = false,
    this.keyboardType,
    this.prefixText,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: ColorConstants.lightTextColor.withValues(alpha: 0.7),
            fontSize: isSmall ? 12 : 14,
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ColorConstants.lightTextColor.withValues(alpha: 0.4),
              fontSize: isSmall ? 10 : 16,
            ),
            prefixText: prefixText,
            prefixStyle: AppTextStyles.bodySmall,
            counterText: '', // Hide character counter
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: ColorConstants.lightTextColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: ColorConstants.lightTextColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: ColorConstants.primaryColor,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: ColorConstants.lightTextColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 14,
              vertical: isSmall ? 8 : (maxLines > 1 ? 14 : 16),
            ),
            isDense: true,
            filled: !enabled,
            fillColor: enabled
                ? null
                : ColorConstants.hintGrey.withValues(alpha: 0.1),
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: enabled
                ? ColorConstants.lightTextColor
                : ColorConstants.lightTextColor.withValues(alpha: 0.6),
            fontSize: isSmall ? 11 : 16,
          ),
        ),
      ],
    );
  }
}
