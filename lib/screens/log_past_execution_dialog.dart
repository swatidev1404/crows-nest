import 'package:flutter/material.dart';
import 'package:crows_nest/models/block.dart' as model;
import 'package:crows_nest/providers/calendar_provider.dart';

class LogPastExecutionDialog extends StatefulWidget {
  final CalendarProvider provider;
  final model.Block block;

  const LogPastExecutionDialog({
    Key? key,
    required this.provider,
    required this.block,
  }) : super(key: key);

  @override
  State<LogPastExecutionDialog> createState() => _LogPastExecutionDialogState();
}

class _LogPastExecutionDialogState extends State<LogPastExecutionDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    // Default to the block's planned times, but ensure end > start
    _startTime = TimeOfDay(hour: widget.block.startTime.hour, minute: widget.block.startTime.minute);
    _endTime = TimeOfDay(hour: widget.block.endTime.hour, minute: widget.block.endTime.minute);
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final startDateTime = DateTime(
      widget.block.date.year, widget.block.date.month, widget.block.date.day,
      _startTime.hour, _startTime.minute,
    );

    final endDateTime = DateTime(
      widget.block.date.year, widget.block.date.month, widget.block.date.day,
      _endTime.hour, _endTime.minute,
    );

    widget.provider.addPastExecutionSession(widget.block.id!, startDateTime, endDateTime);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Past Execution'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Log a retroactive session for "${widget.block.title}".', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Start: ${_startTime.format(context)}'),
              ElevatedButton(onPressed: () => _selectTime(context, true), child: const Text('Pick')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('End: ${_endTime.format(context)}'),
              ElevatedButton(onPressed: () => _selectTime(context, false), child: const Text('Pick')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Log Execution')),
      ],
    );
  }
}
