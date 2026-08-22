import 'package:flutter/material.dart';
import 'package:crows_nest/models/block.dart';
import 'package:crows_nest/models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final List<Block> blocks;
  final int? initialBlockId;
  final Function(Task) onAdd;

  const AddTaskDialog({
    Key? key,
    required this.blocks,
    this.initialBlockId,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedBlockId;

  @override
  void initState() {
    super.initState();
    // Validate if the initialBlockId actually exists in today's blocks
    if (widget.initialBlockId != null && 
        widget.blocks.any((b) => b.id == widget.initialBlockId)) {
      _selectedBlockId = widget.initialBlockId;
    }
  }

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

      widget.onAdd(task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Write report, Walk the dog',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedBlockId,
                decoration: const InputDecoration(
                  labelText: 'Time Block',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None (Inbox / Standalone)'),
                  ),
                  ...widget.blocks.map((block) {
                    return DropdownMenuItem<int?>(
                      value: block.id,
                      child: Text(block.title),
                    );
                  }).toList(),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedBlockId = val;
                  });
                },
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
