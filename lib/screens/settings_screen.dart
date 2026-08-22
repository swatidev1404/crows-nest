import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/weather_tag.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showAddEditDialog(BuildContext context, CalendarProvider provider, {WeatherTag? tag}) {
    showDialog(
      context: context,
      builder: (context) => _WeatherTagDialog(provider: provider, tag: tag),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weather Tags', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddEditDialog(context, provider),
                  ),
                ],
              ),
              const Divider(),
              if (provider.weatherTags.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No weather tags defined. Add some to chart your days!', style: TextStyle(color: Colors.grey)),
                ),
              ...provider.weatherTags.map((tag) {
                return ListTile(
                  leading: const Icon(Icons.label),
                  title: Text(tag.name),
                  subtitle: Text('Icon: ${tag.icon}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(context, provider, tag: tag),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => provider.deleteWeatherTag(tag.id!),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _WeatherTagDialog extends StatefulWidget {
  final CalendarProvider provider;
  final WeatherTag? tag;

  const _WeatherTagDialog({Key? key, required this.provider, this.tag}) : super(key: key);

  @override
  State<_WeatherTagDialog> createState() => _WeatherTagDialogState();
}

class _WeatherTagDialogState extends State<_WeatherTagDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedIcon;

  final List<String> _iconOptions = ['sunny', 'cloudy', 'rain', 'snow', 'wind', 'star', 'tag'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _selectedIcon = _iconOptions.contains(widget.tag?.icon) ? widget.tag!.icon : 'tag';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final tag = WeatherTag(
        id: widget.tag?.id,
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        recurrenceRule: widget.tag?.recurrenceRule ?? '{}',
      );

      if (widget.tag == null) {
        widget.provider.addWeatherTag(tag);
      } else {
        widget.provider.updateWeatherTag(tag);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'Add Weather Tag' : 'Edit Weather Tag'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tag Name', hintText: 'e.g. Weekend, Sick Day'),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedIcon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: _iconOptions.map((iconStr) {
                return DropdownMenuItem(value: iconStr, child: Text(iconStr));
              }).toList(),
              onChanged: (val) => setState(() => _selectedIcon = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
