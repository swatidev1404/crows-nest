import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crows_nest/models/journal_note.dart';
import 'package:crows_nest/providers/calendar_provider.dart';

class AddNoteDialog extends StatefulWidget {
  final CalendarProvider provider;
  final JournalNote? initialNote;
  final DateTime? defaultTime;

  const AddNoteDialog({
    Key? key,
    required this.provider,
    this.initialNote,
    this.defaultTime,
  }) : super(key: key);

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late TextEditingController _contentController;
  late DateTime _selectedTimestamp;
  String _selectedTag = 'Log';

  final List<Map<String, dynamic>> _tags = [
    {'name': 'Log', 'icon': Icons.notes_rounded, 'color': Colors.blue},
    {'name': 'Thought', 'icon': Icons.lightbulb_outline_rounded, 'color': Colors.amber},
    {'name': 'Focus', 'icon': Icons.bolt_rounded, 'color': Colors.purple},
    {'name': 'Win', 'icon': Icons.star_rounded, 'color': Colors.green},
    {'name': 'Break', 'icon': Icons.coffee_rounded, 'color': Colors.orange},
    {'name': 'Blocker', 'icon': Icons.warning_amber_rounded, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialNote?.content ?? '');
    _selectedTimestamp = widget.initialNote?.timestamp ?? widget.defaultTime ?? DateTime.now();
    _selectedTag = widget.initialNote?.tag ?? 'Log';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTimestamp),
    );
    if (time != null) {
      setState(() {
        _selectedTimestamp = DateTime(
          _selectedTimestamp.year,
          _selectedTimestamp.month,
          _selectedTimestamp.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _save() {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    if (widget.initialNote != null) {
      final updated = widget.initialNote!.copyWith(
        content: text,
        timestamp: _selectedTimestamp,
        tag: _selectedTag,
      );
      widget.provider.updateJournalNote(updated);
    } else {
      widget.provider.addJournalNote(
        text,
        timestamp: _selectedTimestamp,
        tag: _selectedTag,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.initialNote != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_comment_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? "Edit Journal Entry" : "Captain's Log Entry",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 13, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(_selectedTimestamp),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down, size: 14, color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Delete Note',
                    onPressed: () {
                      widget.provider.deleteJournalNote(widget.initialNote!.id!);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Tag selectors
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tags.map((t) {
                  final isSelected = _selectedTag == t['name'];
                  final Color tagColor = t['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        t['icon'] as IconData,
                        size: 14,
                        color: isSelected ? Colors.white : tagColor,
                      ),
                      label: Text(t['name'] as String),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : colorScheme.onSurface,
                      ),
                      selectedColor: tagColor,
                      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      onSelected: (val) {
                        if (val) setState(() => _selectedTag = t['name'] as String);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                hintText: "What's happening right now? Ideas, blockers, reflections...",
                hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(isEditing ? 'Save' : 'Log Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
