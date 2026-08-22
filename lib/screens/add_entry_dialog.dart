import 'package:flutter/material.dart';
import 'package:crows_nest/models/block.dart' as model;
import 'package:crows_nest/models/task.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:intl/intl.dart';

class AddEntryDialog extends StatelessWidget {
  final CalendarProvider provider;
  final DateTime currentDate;

  const AddEntryDialog({
    Key? key,
    required this.provider,
    required this.currentDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DefaultTabController(
        length: 2,
        child: Container(
          width: 400,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'New Block'),
                  Tab(text: 'New Task'),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: TabBarView(
                  children: [
                    _BlockForm(provider: provider, currentDate: currentDate),
                    _TaskForm(provider: provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockForm extends StatefulWidget {
  final CalendarProvider provider;
  final DateTime currentDate;

  const _BlockForm({Key? key, required this.provider, required this.currentDate}) : super(key: key);

  @override
  State<_BlockForm> createState() => _BlockFormState();
}

class _BlockFormState extends State<_BlockForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String _selectedCategory = 'Work';
  String? _selectedRecurrence;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  
  static const List<Color> _palette = [
    Colors.blue, Colors.red, Colors.green, Colors.amber,
    Colors.purple, Colors.teal, Colors.cyan, Colors.indigo,
  ];
  Color _selectedColor = _palette.first;

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
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      final startDateTime = DateTime(
        widget.currentDate.year, widget.currentDate.month, widget.currentDate.day,
        _startTime.hour, _startTime.minute,
      );

      final endDateTime = DateTime(
        widget.currentDate.year, widget.currentDate.month, widget.currentDate.day,
        _endTime.hour, _endTime.minute,
      );

      final block = model.Block(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        date: widget.currentDate,
        startTime: startDateTime,
        endTime: endDateTime,
        colorValue: _selectedColor.value,
        recurrence: _selectedRecurrence,
      );

      widget.provider.addBlock(block);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Deep Work, Workout'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
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
                    onChanged: (val) => setState(() => _selectedCategory = val!),
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
                    onChanged: (val) => setState(() => _selectedRecurrence = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Start: ${_startTime.format(context)}'),
                      ElevatedButton(onPressed: () => _selectTime(context, true), child: const Text('Pick Start')),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('End: ${_endTime.format(context)}'),
                      ElevatedButton(onPressed: () => _selectTime(context, false), child: const Text('Pick End')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('Color', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _palette.map((color) {
                      final isSelected = _selectedColor == color;
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: _submit, child: const Text('Add Block')),
          ],
        )
      ],
    );
  }
}

class _TaskForm extends StatefulWidget {
  final CalendarProvider provider;

  const _TaskForm({Key? key, required this.provider}) : super(key: key);

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedBlockId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        title: _titleController.text.trim(),
        blockId: _selectedBlockId,
        planned: true,
        executed: false,
      );

      widget.provider.addTask(task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Task Title', hintText: 'e.g. Write report, Walk the dog'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a task title' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _selectedBlockId,
                    decoration: const InputDecoration(labelText: 'Time Block'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None (Inbox / Standalone)')),
                      ...widget.provider.blocks.map((block) {
                        return DropdownMenuItem<int?>(value: block.id, child: Text(block.title));
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedBlockId = val),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: _submit, child: const Text('Add Task')),
          ],
        )
      ],
    );
  }
}
