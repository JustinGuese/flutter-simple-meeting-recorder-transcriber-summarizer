import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/app_controller.dart';
import '../../models/meeting.dart';
import '../dialogs/rename_dialog.dart';

class MeetingListTile extends StatelessWidget {
  const MeetingListTile({
    super.key,
    required this.meeting,
    required this.isSelected,
    required this.isRecording,
    required this.controller,
  });

  final Meeting meeting;
  final bool isSelected;
  final bool isRecording;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, y · HH:mm').format(meeting.createdAt);

    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      leading: _buildStatusIcon(theme),
      title: Text(
        meeting.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(dateStr, style: theme.textTheme.bodySmall),
      trailing: isRecording
          ? SizedBox(
              width: 12,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.error,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            )
          : null,
      onTap: () => controller.selectMeeting(meeting),
      onLongPress: () => _handleRename(context),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (meeting.transcriptionStatus) {
      case TranscriptionStatus.none:
        return Icon(Icons.article_outlined, color: theme.colorScheme.outline);
      case TranscriptionStatus.inProgress:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        );
      case TranscriptionStatus.completed:
        return Icon(Icons.check_circle_outline, color: theme.colorScheme.tertiary);
      case TranscriptionStatus.failed:
        return Icon(Icons.error_outline, color: theme.colorScheme.error);
    }
  }

  Future<void> _handleRename(BuildContext context) async {
    final newTitle = await showRenameDialog(context, meeting);
    if (newTitle != null && newTitle.isNotEmpty) {
      await controller.renameMeeting(meeting, newTitle);
    }
  }
}
