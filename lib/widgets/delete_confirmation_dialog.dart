import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';

/// Shows a confirmation dialog for delete operations.
/// Returns `true` if the user confirmed, `false` or `null` otherwise.
///
/// [context] The build context
/// [itemType] The type of item being deleted (e.g., "set", "board")
/// [itemName] The name of the item being deleted
/// [additionalMessage] Optional additional warning message
Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String itemType,
  required String itemName,
  String? additionalMessage,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete ${itemType[0].toUpperCase()}${itemType.substring(1)}'),
      content: Text(
        'Are you sure you want to delete "$itemName"?${additionalMessage != null ? ' $additionalMessage' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.errorColor,
            foregroundColor: Colors.white,
          ),
          child: Text('Delete'),
        ),
      ],
    ),
  );
}
