// Dynamic Save Button Widget
//
// A reusable button widget that dynamically switches between "Save as Draft"
// and "Save" based on completion state. Used by both NewSetPage and NewBoardPage.
//
// Rules:
// - Shows "Save as Draft" when basic conditions met but not fully complete
// - Shows "Save" when all completion criteria are met
// - Both require name and description to be non-empty

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

/// A dynamic save button that switches between "Save as Draft" and "Save"
/// based on the completion state.
///
/// Usage:
/// ```dart
/// DynamicSaveButton(
///   nameNotifier: _nameNotifier,
///   descriptionNotifier: _descriptionNotifier,
///   completionCountNotifier: _slotCountNotifier, // or _completedQuestionsNotifier
///   requiredCount: 5,
///   onSaveDraft: () => _saveBoard(isDraft: true),
///   onSave: () => _saveBoard(isDraft: false),
///   isSaving: _isSaving,
/// )
/// ```
class DynamicSaveButton extends StatelessWidget {
  /// Notifier for the name field value
  final ValueNotifier<String> nameNotifier;

  /// Notifier for the description field value
  final ValueNotifier<String> descriptionNotifier;

  /// Notifier for the completion count (e.g., filled slots or completed questions)
  final ValueNotifier<int> completionCountNotifier;

  /// The count required to show "Save" instead of "Save as Draft" (default: 5)
  final int requiredCount;

  /// Callback when "Save as Draft" is pressed
  final VoidCallback onSaveDraft;

  /// Callback when "Save" is pressed
  final VoidCallback onSave;

  /// Whether a save operation is in progress
  final bool isSaving;

  /// Width of the button (default: 130)
  final double buttonWidth;

  /// Height of the button (default: 45)
  final double buttonHeight;

  const DynamicSaveButton({
    super.key,
    required this.nameNotifier,
    required this.descriptionNotifier,
    required this.completionCountNotifier,
    required this.onSaveDraft,
    required this.onSave,
    this.requiredCount = 5,
    this.isSaving = false,
    this.buttonWidth = 130,
    this.buttonHeight = 45,
  });

  /// Check if basic save conditions are met (name and description filled)
  bool _canSaveAsDraft(String name, String description) {
    return name.trim().isNotEmpty && description.trim().isNotEmpty;
  }

  /// Check if complete save conditions are met (basic + required count reached)
  bool _canSave(String name, String description, int completionCount) {
    return _canSaveAsDraft(name, description) &&
        completionCount >= requiredCount;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: nameNotifier,
      builder: (context, name, _) {
        return ValueListenableBuilder<String>(
          valueListenable: descriptionNotifier,
          builder: (context, description, _) {
            return ValueListenableBuilder<int>(
              valueListenable: completionCountNotifier,
              builder: (context, completionCount, _) {
                final canDraft = _canSaveAsDraft(name, description);
                final canSave = _canSave(name, description, completionCount);
                final showSave = completionCount >= requiredCount;

                return SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: showSave
                      ? _buildSaveButton(canSave)
                      : _buildDraftButton(canDraft),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Build the "Save as Draft" outlined button
  Widget _buildDraftButton(bool canDraft) {
    return OutlinedButton(
      onPressed: (canDraft && !isSaving) ? onSaveDraft : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorConstants.primaryColor,
        disabledForegroundColor: ColorConstants.hintGrey.withValues(alpha: 0.5),
        side: BorderSide(
          color: (canDraft && !isSaving)
              ? ColorConstants.primaryColor
              : ColorConstants.hintGrey.withValues(alpha: 0.3),
          width: 1.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: isSaving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorConstants.primaryColor,
                ),
              ),
            )
          : Text(
              'Save as Draft',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  /// Build the "Save" elevated button
  Widget _buildSaveButton(bool canSave) {
    return ElevatedButton(
      onPressed: (canSave && !isSaving) ? onSave : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: ColorConstants.lightTextColor,
        disabledBackgroundColor:
            ColorConstants.primaryColor.withValues(alpha: 0.3),
        disabledForegroundColor:
            ColorConstants.lightTextColor.withValues(alpha: 0.5),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: canSave ? 2 : 0,
      ),
      child: isSaving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorConstants.lightTextColor,
                ),
              ),
            )
          : Text(
              'Save',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
