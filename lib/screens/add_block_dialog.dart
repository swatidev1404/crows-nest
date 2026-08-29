import 'package:flutter/material.dart';
import 'package:crows_nest/models/block.dart';
import 'package:intl/intl.dart';

class AddBlockDialog extends StatefulWidget {
  final DateTime currentDate;
  final Function(Block) onAdd;

  const AddBlockDialog({
    Key? key,
    required this.currentDate,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddBlockDialog> createState() => _AddBlockDialogState();
}

class _AddBlockDialogState extends State<AddBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String _selectedCategory = 'Work';
  String? _selectedRecurrence;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  static const List<Color> _palette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
  ];
  Color _selectedColor = _palette.first;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _startTime = now;
    _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
          // Auto adjust end time to start + 1 hour if it is before start
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
    if (_formKey.currentState!.validate()) {
      // Validate time order
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      final startDateTime = DateTime(
        widget.currentDate.year,
        widget.currentDate.month,
        widget.currentDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        widget.currentDate.year,
        widget.currentDate.month,
        widget.currentDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final block = Block(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        date: widget.currentDate,
        startTime: startDateTime,
        endTime: endDateTime,
        colorValue: _selectedColor.value,
        recurrence: _selectedRecurrence,
      );

      widget.onAdd(block);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Time Block'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Deep Work, Workout',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Work', child: Text('Work')),
                  DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'Health', child: Text('Health')),
                  DropdownMenuItem(value: 'Hobby', child: Text('Hobby')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedRecurrence,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None (Just this once)')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedRecurrence = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start: ${_startTime.format(context)}'),
                  ElevatedButton(
                    onPressed: () => _selectTime(context, true),
                    child: const Text('Pick Start'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('End: ${_endTime.format(context)}'),
                  ElevatedButton(
                    onPressed: () => _selectTime(context, false),
                    child: const Text('Pick End'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _palette.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected 
                          ? Border.all(color: Colors.black, width: 2) 
                          : null,
                      ),
                      child: isSelected 
                        ? const Icon(Icons.check, color: Colors.white, size: 16) 
                        : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
