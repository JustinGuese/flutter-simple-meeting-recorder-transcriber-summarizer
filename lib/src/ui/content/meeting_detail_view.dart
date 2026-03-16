import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/app_controller.dart';
import '../../models/meeting.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/rename_dialog.dart';
import '../widgets/transcription_status_chip.dart';

class MeetingDetailView extends StatefulWidget {
  const MeetingDetailView({
    super.key,
    required this.meeting,
    required this.controller,
    required this.isActive,
  });

  final Meeting meeting;
  final AppController controller;
  final bool isActive;

  @override
  State<MeetingDetailView> createState() => _MeetingDetailViewState();
}

class _MeetingDetailViewState extends State<MeetingDetailView> {
  late TextEditingController _notesController;
  late TextEditingController _transcriptController;
  Timer? _transcriptDebounce;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.meeting.notes);
    _transcriptController = TextEditingController(text: widget.meeting.transcription);
  }

  @override
  void didUpdateWidget(MeetingDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync when meeting changes OR when content updates (e.g. transcription arrives)
    if (_notesController.text != widget.meeting.notes) {
      _notesController.text = widget.meeting.notes;
    }
    if (_transcriptController.text != widget.meeting.transcription) {
      _transcriptController.text = widget.meeting.transcription;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _transcriptController.dispose();
    _transcriptDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: title, date, delete
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _handleRename(context),
                      child: Text(
                        widget.meeting.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM d, y · HH:mm:ss').format(widget.meeting.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        TranscriptionStatusChip(status: widget.meeting.transcriptionStatus),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _handleDelete(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content: notes + transcript
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: widget.isActive ? 80 : 24,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes section (always first)
                _buildNotesSection(theme),
                const SizedBox(height: 24),
                _buildSummarySection(theme),
                if (widget.meeting.transcription.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildTranscriptionSection(theme),
                ],
                if (widget.meeting.transcription.isEmpty &&
                    widget.meeting.transcriptionStatus == TranscriptionStatus.none &&
                    !widget.isActive) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'No transcription yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
                if (widget.isActive) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Recording in progress...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Notes', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: null,
          minLines: 3,
          enabled: widget.isActive || widget.meeting.transcriptionStatus != TranscriptionStatus.inProgress,
          decoration: InputDecoration(
            hintText: 'Add notes about this meeting...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (text) => widget.controller.updateNotes(text),
        ),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    final status = widget.meeting.summaryStatus;
    final hasSummary =
        widget.meeting.summary != null && widget.meeting.summary!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('AI Summary', style: theme.textTheme.titleMedium),
            const SizedBox(width: 12),
            if (status == SummaryStatus.inProgress)
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generating...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              )
            else if (status == SummaryStatus.failed)
              Text(
                'Summary failed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else if (status == SummaryStatus.completed && hasSummary)
              Text(
                'Ready',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasSummary)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              widget.meeting.summary!,
              style: theme.textTheme.bodyMedium,
            ),
          )
        else if (status == SummaryStatus.inProgress)
          Text(
            'We\'re generating a summary for this meeting...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else if (widget.meeting.transcriptionStatus ==
            TranscriptionStatus.completed)
          Text(
            'Generate a concise AI summary will appear here after processing.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Text(
            'Summary will be available after transcription completes.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
      ],
    );
  }

  Widget _buildTranscriptionSection(ThemeData theme) {
    final isEditable = widget.meeting.transcriptionStatus != TranscriptionStatus.inProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Transcript', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _transcriptController,
          maxLines: null,
          minLines: 6,
          enabled: isEditable,
          readOnly: !isEditable,
          decoration: InputDecoration(
            hintText: 'Transcript will appear here after transcription...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: theme.textTheme.bodyMedium,
          onChanged: (text) {
            widget.meeting.transcription = text;
            _transcriptDebounce?.cancel();
            _transcriptDebounce = Timer(const Duration(milliseconds: 500), () async {
              await widget.controller.repository.save(widget.meeting);
            });
          },
        ),
      ],
    );
  }

  Future<void> _handleRename(BuildContext context) async {
    final newTitle = await showRenameDialog(context, widget.meeting);
    if (newTitle != null && newTitle.isNotEmpty) {
      await widget.controller.renameMeeting(widget.meeting, newTitle);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete meeting?',
      content: 'This action cannot be undone.',
    );

    if (confirm == true) {
      await widget.controller.deleteMeeting(widget.meeting);
    }
  }
}
