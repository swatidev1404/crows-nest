import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_entry.dart';
import '../models/block.dart';
import '../providers/block_provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dual_timeline.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Crow\'s Nest', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildHeader(context, ref, theme),
          _buildColumnLabels(theme),
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DualTimeline(
                entries: entries,
                onEntryTap: (entry) => _showEntryDetailsDialog(context, ref, entry),
                onEmptyTap: () => _showScheduleBlockDialog(context, ref),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateStr = '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';
    final dayStr = weekdays[selectedDate.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(dayStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildToggleButton('◀ Past', isActive: !isToday && selectedDate.isBefore(now), theme: theme, onTap: () {
                  ref.read(selectedDateProvider.notifier).updateDate(selectedDate.subtract(const Duration(days: 1)));
                }),
                _buildToggleButton('Today', isActive: isToday, theme: theme, onTap: () {
                  ref.read(selectedDateProvider.notifier).updateDate(DateTime.now());
                }),
                _buildToggleButton('Next ▶', isActive: !isToday && selectedDate.isAfter(now), theme: theme, onTap: () {
                  ref.read(selectedDateProvider.notifier).updateDate(selectedDate.add(const Duration(days: 1)));
                }),
                _buildToggleButton('Full Day', isActive: false, theme: theme, onTap: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, {required bool isActive, required ThemeData theme, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey[700],
          fontSize: 10,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ));
  }

  Widget _buildColumnLabels(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('PLANNED', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)))),
          const SizedBox(width: 60, child: Center(child: Text('TIME', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)))),
          const Expanded(child: Center(child: Text('EXECUTED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)))),
        ],
      ),
    );
  }

  void _showEntryDetailsDialog(BuildContext context, WidgetRef ref, CalendarEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final currentEntry = ref.watch(calendarProvider).firstWhere((e) => e.id == entry.id, orElse: () => entry);
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentEntry.blockName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: currentEntry.taskCompletions.map((tc) {
                        final taskTitle = _getTaskTitle(ref, currentEntry.blockId, tc.taskId);
                        return CheckboxListTile(
                          title: Text(taskTitle, style: TextStyle(
                            decoration: tc.isCompleted ? TextDecoration.lineThrough : null,
                            color: tc.isCompleted ? Colors.grey : null,
                          )),
                          value: tc.isCompleted,
                          onChanged: (val) {
                            final newTcs = currentEntry.taskCompletions.map((t) => t.taskId == tc.taskId ? t.copyWith(isCompleted: val) : t).toList();
                            ref.read(calendarProvider.notifier).updateEntry(currentEntry.copyWith(taskCompletions: newTcs));
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, ref, currentEntry),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, CalendarEntry entry) {
    if (entry.status == EntryStatus.notStarted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            final now = DateTime.now();
            ref.read(calendarProvider.notifier).updateEntry(entry.copyWith(
              status: EntryStatus.inProgress,
              actualStartMinutes: now.hour * 60 + now.minute,
            ));
            Navigator.pop(context);
          },
          child: const Text('Start Block Now'),
        ),
      );
    }
    
    if (entry.status == EntryStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () {
            final now = DateTime.now();
            ref.read(calendarProvider.notifier).updateEntry(entry.copyWith(
              status: EntryStatus.completed,
              actualEndMinutes: now.hour * 60 + now.minute,
            ));
            Navigator.pop(context);
          },
          child: const Text('Complete Block'),
        ),
      );
    }
    
    return Row(
      children: [
        const Text('Completed 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        const Spacer(),
        TextButton(
          onPressed: () {
            ref.read(calendarProvider.notifier).deleteEntry(entry.id);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        )
      ],
    );
  }

  String _getTaskTitle(WidgetRef ref, String blockId, String taskId) {
    final blocks = ref.read(blocksProvider).blocks;
    final block = blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return 'Unknown Task';
    final task = block.tasks.where((t) => t.id == taskId).firstOrNull;
    return task?.title ?? 'Unknown Task';
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
              title: const Text('Schedule a Block'),
              subtitle: const Text('Add a block to today\'s timeline'),
              onTap: () {
                Navigator.pop(context);
                _showScheduleBlockDialog(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.add_task, color: Theme.of(context).colorScheme.primary),
              title: const Text('Add Task'),
              subtitle: const Text('Quickly save a task to your Inbox'),
              onTap: () {
                Navigator.pop(context);
                _showQuickCaptureDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCaptureDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Capture'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          autofocus: true,
          onSubmitted: (title) {
            if (title.trim().isNotEmpty) {
              ref.read(blocksProvider.notifier).addInboxTask(title.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Inbox')));
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                ref.read(blocksProvider.notifier).addInboxTask(title);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Inbox')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showScheduleBlockDialog(BuildContext context, WidgetRef ref) {
    final blocks = ref.read(blocksProvider).blocks;
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a Block in the library first!')));
      return;
    }

    Block? selectedBlock = blocks.first;
    TimeOfDay selectedTime = TimeOfDay.now();
    int durationMinutes = 60;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Schedule Block'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Block>(
                  initialValue: selectedBlock,
                  items: blocks.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                  onChanged: (b) => setState(() => selectedBlock = b),
                  decoration: const InputDecoration(labelText: 'Select Block'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Time'),
                  trailing: Text(selectedTime.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: selectedTime);
                    if (t != null) setState(() => selectedTime = t);
                  },
                ),
                TextFormField(
                  initialValue: durationMinutes.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  onChanged: (val) => durationMinutes = int.tryParse(val) ?? 60,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedBlock != null) {
                    final tcs = selectedBlock!.tasks.map((t) => TaskCompletion(taskId: t.id)).toList();
                    final entry = CalendarEntry(
                      blockId: selectedBlock!.id,
                      blockName: selectedBlock!.name,
                      date: ref.read(selectedDateStringProvider),
                      plannedStartMinutes: selectedTime.hour * 60 + selectedTime.minute,
                      plannedDurationMinutes: durationMinutes,
                      taskCompletions: tcs,
                    );
                    ref.read(calendarProvider.notifier).addEntry(entry);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Schedule'),
              ),
            ],
          ),
        );
      }
    );
  }
}
