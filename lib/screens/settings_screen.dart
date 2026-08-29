import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/providers/theme_provider.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/screens/export_import_dialog.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme Section
              Row(
                children: [
                  Icon(Icons.palette_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Appearance & Themes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.oceanicDark,
                title: 'Midnight Oceanic',
                subtitle: 'Deep nautical navy with gold & cyan accents',
                icon: Icons.nights_stay_rounded,
                colors: const [Color(0xFF0A1128), Color(0xFF38B6FF), Color(0xFFF6AE2D)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.oceanicDark,
                onTap: () => themeProvider.setTheme(AppThemeMode.oceanicDark),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.cyberTwilight,
                title: 'Cyber Horizon',
                subtitle: 'Synthwave twilight obsidian with neon purple & electric cyan',
                icon: Icons.auto_awesome_rounded,
                colors: const [Color(0xFF0F0E17), Color(0xFF8C52FF), Color(0xFF00E5FF)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.cyberTwilight,
                onTap: () => themeProvider.setTheme(AppThemeMode.cyberTwilight),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.nordicLight,
                title: 'Nordic Sea Mist',
                subtitle: 'Crisp sea mist alabaster with marine teal & ocean slate',
                icon: Icons.wb_sunny_rounded,
                colors: const [Color(0xFFF4F7FB), Color(0xFF0D9488), Color(0xFF0284C7)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.nordicLight,
                onTap: () => themeProvider.setTheme(AppThemeMode.nordicLight),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.crimsonCorsair,
                title: 'Crimson Corsair',
                subtitle: 'Bold obsidian with pirate crimson red & burnished gold accents',
                icon: Icons.local_fire_department_rounded,
                colors: const [Color(0xFF140D0F), Color(0xFFFF3366), Color(0xFFFFB703)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.crimsonCorsair,
                onTap: () => themeProvider.setTheme(AppThemeMode.crimsonCorsair),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.emeraldAbyss,
                title: 'Emerald Abyss',
                subtitle: 'Deep sea abyss with bioluminescent emerald & mint neon glow',
                icon: Icons.water_drop_rounded,
                colors: const [Color(0xFF071411), Color(0xFF00F5D4), Color(0xFF70E000)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.emeraldAbyss,
                onTap: () => themeProvider.setTheme(AppThemeMode.emeraldAbyss),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.goldenDune,
                title: 'Golden Dune',
                subtitle: 'Warm sunlit ivory with desert sand & terracotta sunset accents',
                icon: Icons.wb_twilight_rounded,
                colors: const [Color(0xFFFAF6EE), Color(0xFFD97706), Color(0xFFEA580C)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.goldenDune,
                onTap: () => themeProvider.setTheme(AppThemeMode.goldenDune),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.autoChronometer,
                title: 'Chronometer Shift ⏱️ (Auto 2h)',
                subtitle: 'Automatically cycles through all 6 themes every 2 hours with the nautical watch',
                icon: Icons.timelapse_rounded,
                colors: const [Color(0xFF38B6FF), Color(0xFF8C52FF), Color(0xFFFF3366), Color(0xFF00F5D4), Color(0xFFD97706)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.autoChronometer,
                onTap: () => themeProvider.setTheme(AppThemeMode.autoChronometer),
              ),
              const SizedBox(height: 8),
              _buildThemeOptionCard(
                context: context,
                mode: AppThemeMode.solarCircadian,
                title: 'Solar Tides ☀️ (Natural Time of Day)',
                subtitle: 'Nordic (Morning) ➔ Golden (Midday) ➔ Midnight Oceanic (Afternoon) ➔ Cyber (Twilight) ➔ Crimson (Late Night) ➔ Emerald (Abyss)',
                icon: Icons.wb_sunny_outlined,
                colors: const [Color(0xFF0D9488), Color(0xFFD97706), Color(0xFF0F1E36), Color(0xFF8C52FF), Color(0xFFFF3366), Color(0xFF00F5D4)],
                isSelected: themeProvider.currentThemeMode == AppThemeMode.solarCircadian,
                onTap: () => themeProvider.setTheme(AppThemeMode.solarCircadian),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Weather Tags Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_cloudy_rounded, color: colorScheme.secondary, size: 22),
                      const SizedBox(width: 8),
                      Text('Weather Tags', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddEditDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.weatherTags.isEmpty)
                Card(
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No weather tags defined. Add some to chart your days!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ...provider.weatherTags.map((tag) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(_getIconData(tag.icon), color: colorScheme.onPrimaryContainer, size: 20),
                    ),
                    title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Icon: ${tag.icon}', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showAddEditDialog(context, provider, tag: tag),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => provider.deleteWeatherTag(tag.id!),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Data & Backup Section
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Captain\'s Logbook & Data', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export or restore all time blocks, tasks, weather logs, blueprints, and notes in JSON format.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const ExportImportDialog(),
                                );
                              },
                              icon: const Icon(Icons.import_export_rounded),
                              label: const Text('Export / Import JSON'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required BuildContext context,
    required AppThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.4),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary.withOpacity(0.15) : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Swatch circles
              Row(
                mainAxisSize: MainAxisSize.min,
                children: colors.map((c) {
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
        return Icons.wb_cloudy_rounded;
      case 'rain':
        return Icons.water_drop_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'wind':
        return Icons.air_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.label_rounded;
    }
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
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                hintText: 'e.g. Weekend, Sick Day',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedIcon,
              decoration: const InputDecoration(
                labelText: 'Icon',
                border: OutlineInputBorder(),
              ),
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
