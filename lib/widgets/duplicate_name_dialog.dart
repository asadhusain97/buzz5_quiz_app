import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';

/// Shows a dialog indicating that a name already exists.
/// Used for both sets and boards to maintain consistent UX.
///
/// [context] The build context for showing the dialog
/// [itemType] The type of item (e.g., "set", "board")
/// [name] The duplicate name that was attempted
Future<void> showDuplicateNameDialog({
  required BuildContext context,
  required String itemType,
  required String name,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: ColorConstants.errorColor,
            size: 28,
          ),
          SizedBox(width: 12),
          Text('Duplicate Name'),
        ],
      ),
      content: Text(
        'A $itemType with the name "$name" already exists. Please choose a different name.',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: TextStyle(color: ColorConstants.primaryColor),
          ),
        ),
      ],
    ),
  );
}
