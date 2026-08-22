import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/services/database_service.dart';

class WeatherReportScreen extends StatefulWidget {
  const WeatherReportScreen({Key? key}) : super(key: key);

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
    final db = DatabaseService();
    _allTags = await db.getWeatherTags();
    
    // For the prototype, we default all to OFF since we don't have the rule engine built yet.
    // In the future, evaluate _allTags against the currentDate to pre-fill _activeTagIds.
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = Provider.of<CalendarProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('Morning Briefing'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.sailing, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              'Chart the Course for ${provider.currentDate.month}/${provider.currentDate.day}/${provider.currentDate.year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the weather conditions for today to stamp your blueprints.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _allTags.isEmpty 
                ? const Center(
                    child: Text('No weather tags defined yet.\nSet sail with a clear sky!', textAlign: TextAlign.center,),
                  )
                : ListView.builder(
                    itemCount: _allTags.length,
                    itemBuilder: (context, index) {
                      final tag = _allTags[index];
                      final isActive = _activeTagIds.contains(tag.id);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: SwitchListTile(
                          title: Text(tag.name),
                          value: isActive,
                          onChanged: (val) {
                            setState(() {
                              if (val) {
                                _activeTagIds.add(tag.id!);
                              } else {
                                _activeTagIds.remove(tag.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.explore),
                label: const Text('Set Sail', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await provider.chartTheCourse(_activeTagIds.toList());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
