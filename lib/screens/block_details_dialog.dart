import 'package:flutter/material.dart';
import 'package:crows_nest/models/block.dart' as model;
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/screens/add_task_dialog.dart';
import 'package:intl/intl.dart';

class BlockDetailsDialog extends StatefulWidget {
  final model.Block block;
  final CalendarProvider provider;

  const BlockDetailsDialog({
    Key? key,
    required this.block,
    required this.provider,
  }) : super(key: key);

  @override
  State<BlockDetailsDialog> createState() => _BlockDetailsDialogState();
}

class _BlockDetailsDialogState extends State<BlockDetailsDialog> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  void _showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          blocks: widget.provider.blocks,
          initialBlockId: widget.block.id,
          onAdd: (task) {
            widget.provider.addTask(task);
          },
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _handleSessionAction(bool isActive) {
    if (isActive) {
      widget.provider.stopBlock(widget.block, endTime: _selectedDateTime);
    } else {
      widget.provider.startBlock(widget.block, startTime: _selectedDateTime);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('jm');
    final DateFormat dateTimeFormat = DateFormat('MMM d, jm');
    final String timeRange = '${timeFormat.format(widget.block.startTime)} - ${timeFormat.format(widget.block.endTime)}';
    
    final isActive = widget.provider.isBlockActive(widget.block.id!);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(widget.block.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Icon(Icons.circle, color: Color(widget.block.colorValue), size: 16),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: $timeRange', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Category: ${widget.block.category}'),
            if (widget.block.recurrence != null) ...[
              const SizedBox(height: 4),
              Text('Recurrence: ${widget.block.recurrence}'),
            ],
            const Divider(height: 16),
            
            // Session Controls
            const Text('Session', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(isActive ? Icons.stop_circle : Icons.play_circle, color: isActive ? Colors.red : Colors.green),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dateTimeFormat.format(_selectedDateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _handleSessionAction(isActive),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.red.shade100 : Colors.green.shade100,
                      foregroundColor: isActive ? Colors.red.shade900 : Colors.green.shade900,
                    ),
                    child: Text(isActive ? 'Stop' : 'Start'),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),
            const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.block.tasks.isEmpty)
              const Text('No tasks scheduled for this block.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            if (widget.block.tasks.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.block.tasks.length,
                  itemBuilder: (context, index) {
                    final task = widget.block.tasks[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        task.completedPlan ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: Color(widget.block.colorValue),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completedPlan ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      onTap: () => widget.provider.toggleTaskPlanCompletion(task),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddTask(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
        ),
      ],
    );
  }
}
