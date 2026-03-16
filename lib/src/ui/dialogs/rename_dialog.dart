import 'package:flutter/material.dart';

import '../../models/meeting.dart';

Future<String?> showRenameDialog(BuildContext context, Meeting meeting) {
  final controller = TextEditingController(text: meeting.title);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename meeting'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Meeting title',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
