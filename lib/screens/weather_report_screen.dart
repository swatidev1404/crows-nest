import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/services/database_service.dart';

class WeatherReportScreen extends StatefulWidget {
  final bool isDialog;
  const WeatherReportScreen({Key? key, this.isDialog = false}) : super(key: key);

  @override
  State<WeatherReportScreen> createState() => _WeatherReportScreenState();
}

class _WeatherReportScreenState extends State<WeatherReportScreen> {
  bool _isLoading = true;
  List<WeatherTag> _allTags = [];
  Set<int> _activeTagIds = {};

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final db = DatabaseService();
    final tags = await db.getWeatherTags();
    if (!mounted) return;
    
    // Pre-populate if already charted
    if (provider.currentDayWeather != null) {
      _activeTagIds = provider.currentDayWeather!.activeTagIds.toSet();
    }
    
    setState(() {
      _allTags = tags;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    final content = _isLoading
        ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.primary.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sailing_rounded, size: 40, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Morning Briefing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Calibrate conditions for ${provider.currentDate.month}/${provider.currentDate.day}/${provider.currentDate.year}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_allTags.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny_outlined, size: 36, color: colorScheme.primary),
                        const SizedBox(height: 8),
                        const Text(
                          'No weather tags defined yet',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can set sail right now with clear skies!',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'Select Today\'s Conditions:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allTags.map((tag) {
                      final isActive = _activeTagIds.contains(tag.id);
                      return FilterChip(
                        selected: isActive,
                        showCheckmark: true,
                        checkmarkColor: colorScheme.onPrimary,
                        avatar: Icon(
                          isActive ? Icons.check_circle_rounded : Icons.label_outline_rounded,
                          size: 16,
                          color: isActive ? colorScheme.onPrimary : colorScheme.primary,
                        ),
                        label: Text(tag.name),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
                        ),
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isActive ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _activeTagIds.add(tag.id!);
                            } else {
                              _activeTagIds.remove(tag.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.explore_rounded, size: 20),
                  label: const Text(
                    'Set Sail & Apply Blueprints',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    await provider.chartTheCourse(_activeTagIds.toList());
                    if (mounted && widget.isDialog) {
                      Navigator.pop(context);
                    }
                  },
                ),
                if (widget.isDialog)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
              ],
            ),
          );

    if (widget.isDialog) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Briefing'),
        centerTitle: true,
      ),
      body: SafeArea(child: content),
    );
  }
}

