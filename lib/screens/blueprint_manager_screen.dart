import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/blueprint.dart';

class BlueprintManagerScreen extends StatelessWidget {
  const BlueprintManagerScreen({Key? key}) : super(key: key);

  void _showAddEditBlockDialog(BuildContext context, CalendarProvider provider, {BlockBlueprint? blueprint}) {
    showDialog(
      context: context,
      builder: (context) => _BlockBlueprintDialog(provider: provider, blueprint: blueprint),
    );
  }

  void _showAddEditTaskDialog(BuildContext context, CalendarProvider provider, {TaskBlueprint? blueprint}) {
    showDialog(
      context: context,
      builder: (context) => _TaskBlueprintDialog(provider: provider, blueprint: blueprint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blueprints Manager'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Blocks'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: Consumer<CalendarProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              children: [
                _buildBlocksTab(context, provider),
                _buildTasksTab(context, provider),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<CalendarProvider>(
          builder: (context, provider, child) {
            return Builder(
              builder: (BuildContext context) {
                return FloatingActionButton(
                  onPressed: () {
                    final tabIndex = DefaultTabController.of(context).index;
                    if (tabIndex == 0) {
                      _showAddEditBlockDialog(context, provider);
                    } else {
                      _showAddEditTaskDialog(context, provider);
                    }
                  },
                  child: const Icon(Icons.add),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlocksTab(BuildContext context, CalendarProvider provider) {
    if (provider.blockBlueprints.isEmpty) {
      return const Center(child: Text('No block blueprints defined.'));
    }
    return ListView.builder(
      itemCount: provider.blockBlueprints.length,
      itemBuilder: (context, index) {
        final bp = provider.blockBlueprints[index];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Color(bp.colorValue)),
          title: Text(bp.title),
          subtitle: Text('${bp.category} • ${bp.startHour}:${bp.startMinute.toString().padLeft(2, '0')} - ${bp.endHour}:${bp.endMinute.toString().padLeft(2, '0')}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showAddEditBlockDialog(context, provider, blueprint: bp),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => provider.deleteBlockBlueprint(bp.id!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(BuildContext context, CalendarProvider provider) {
    if (provider.taskBlueprints.isEmpty) {
      return const Center(child: Text('No task blueprints defined.'));
    }
    return ListView.builder(
      itemCount: provider.taskBlueprints.length,
      itemBuilder: (context, index) {
        final bp = provider.taskBlueprints[index];
        String blockName = 'Standalone';
        if (bp.blockBlueprintId != null) {
          final parent = provider.blockBlueprints.where((b) => b.id == bp.blockBlueprintId).firstOrNull;
          if (parent != null) blockName = parent.title;
        }
        return ListTile(
          leading: const Icon(Icons.task),
          title: Text(bp.title),
          subtitle: Text('Associated Block: $blockName'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showAddEditTaskDialog(context, provider, blueprint: bp),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => provider.deleteTaskBlueprint(bp.id!),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlockBlueprintDialog extends StatefulWidget {
  final CalendarProvider provider;
  final BlockBlueprint? blueprint;

  const _BlockBlueprintDialog({Key? key, required this.provider, this.blueprint}) : super(key: key);

  @override
  State<_BlockBlueprintDialog> createState() => _BlockBlueprintDialogState();
}

class _BlockBlueprintDialogState extends State<_BlockBlueprintDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late String _selectedCategory;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  late List<int> _requiredTagIds;
  late List<int> _excludedTagIds;

  static const List<Color> _palette = [
    Colors.blue, Colors.red, Colors.green, Colors.amber, 
    Colors.purple, Colors.teal, Colors.cyan, Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    final bp = widget.blueprint;
    _titleController = TextEditingController(text: bp?.title ?? '');
    _selectedCategory = bp?.category ?? 'Work';
    final now = TimeOfDay.now();
    _startTime = bp != null ? TimeOfDay(hour: bp.startHour, minute: bp.startMinute) : now;
    _endTime = bp != null ? TimeOfDay(hour: bp.endHour, minute: bp.endMinute) : TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
    _selectedColor = bp != null ? Color(bp.colorValue) : _palette.first;
    _requiredTagIds = bp?.requiredTagIds.toList() ?? [];
    _excludedTagIds = bp?.excludedTagIds.toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final bp = BlockBlueprint(
        id: widget.blueprint?.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        colorValue: _selectedColor.value,
        requiredTagIds: _requiredTagIds,
        excludedTagIds: _excludedTagIds,
      );

      if (widget.blueprint == null) {
        widget.provider.addBlockBlueprint(bp);
      } else {
        widget.provider.updateBlockBlueprint(bp);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.blueprint == null ? 'Add Block Blueprint' : 'Edit Block Blueprint'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start: ${_startTime.format(context)}'),
                  ElevatedButton(onPressed: () => _selectTime(context, true), child: const Text('Pick')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('End: ${_endTime.format(context)}'),
                  ElevatedButton(onPressed: () => _selectTime(context, false), child: const Text('Pick')),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _palette.map((c) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: CircleAvatar(
                    backgroundColor: c,
                    radius: 16,
                    child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Required Weather Tags:', style: TextStyle(fontWeight: FontWeight.bold))),
              _buildTagSelectors(true),
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: Text('Excluded Weather Tags:', style: TextStyle(fontWeight: FontWeight.bold))),
              _buildTagSelectors(false),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  Widget _buildTagSelectors(bool isRequired) {
    final tags = widget.provider.weatherTags;
    if (tags.isEmpty) return const Text('No tags defined.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
    
    return Wrap(
      spacing: 4,
      children: tags.map((tag) {
        final list = isRequired ? _requiredTagIds : _excludedTagIds;
        final isSelected = list.contains(tag.id);
        return FilterChip(
          label: Text(tag.name, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              if (val) {
                list.add(tag.id!);
                if (isRequired) {
                  _excludedTagIds.remove(tag.id);
                } else {
                  _requiredTagIds.remove(tag.id);
                }
              } else {
                list.remove(tag.id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}

class _TaskBlueprintDialog extends StatefulWidget {
  final CalendarProvider provider;
  final TaskBlueprint? blueprint;

  const _TaskBlueprintDialog({Key? key, required this.provider, this.blueprint}) : super(key: key);

  @override
  State<_TaskBlueprintDialog> createState() => _TaskBlueprintDialogState();
}

class _TaskBlueprintDialogState extends State<_TaskBlueprintDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  int? _selectedBlockBlueprintId;
  late List<int> _requiredTagIds;
  late List<int> _excludedTagIds;

  @override
  void initState() {
    super.initState();
    final bp = widget.blueprint;
    _titleController = TextEditingController(text: bp?.title ?? '');
    _selectedBlockBlueprintId = bp?.blockBlueprintId;
    _requiredTagIds = bp?.requiredTagIds.toList() ?? [];
    _excludedTagIds = bp?.excludedTagIds.toList() ?? [];
    
    if (_selectedBlockBlueprintId != null && 
        !widget.provider.blockBlueprints.any((b) => b.id == _selectedBlockBlueprintId)) {
      _selectedBlockBlueprintId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final bp = TaskBlueprint(
        id: widget.blueprint?.id,
        blockBlueprintId: _selectedBlockBlueprintId,
        title: _titleController.text.trim(),
        requiredTagIds: _requiredTagIds,
        excludedTagIds: _excludedTagIds,
      );

      if (widget.blueprint == null) {
        widget.provider.addTaskBlueprint(bp);
      } else {
        widget.provider.updateTaskBlueprint(bp);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.blueprint == null ? 'Add Task Blueprint' : 'Edit Task Blueprint'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedBlockBlueprintId,
                decoration: const InputDecoration(labelText: 'Associated Block'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('None (Standalone)')),
                  ...widget.provider.blockBlueprints.map((b) {
                    return DropdownMenuItem<int?>(value: b.id, child: Text(b.title));
                  }),
                ],
                onChanged: (val) => setState(() => _selectedBlockBlueprintId = val),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Required Weather Tags:', style: TextStyle(fontWeight: FontWeight.bold))),
              _buildTagSelectors(true),
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: Text('Excluded Weather Tags:', style: TextStyle(fontWeight: FontWeight.bold))),
              _buildTagSelectors(false),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  Widget _buildTagSelectors(bool isRequired) {
    final tags = widget.provider.weatherTags;
    if (tags.isEmpty) return const Text('No tags defined.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
    
    return Wrap(
      spacing: 4,
      children: tags.map((tag) {
        final list = isRequired ? _requiredTagIds : _excludedTagIds;
        final isSelected = list.contains(tag.id);
        return FilterChip(
          label: Text(tag.name, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              if (val) {
                list.add(tag.id!);
                if (isRequired) {
                  _excludedTagIds.remove(tag.id);
                } else {
                  _requiredTagIds.remove(tag.id);
                }
              } else {
                list.remove(tag.id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
