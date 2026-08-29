import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crows_nest/models/block.dart';
import 'package:crows_nest/models/task.dart';
import 'package:crows_nest/models/journal_note.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/providers/theme_provider.dart';

void main() {
  test('Block and Task models map serialization test', () {
    final date = DateTime(2026, 7, 4);
    final block = Block(
      id: 1,
      title: 'Deep Work',
      category: 'Work',
      date: date,
      startTime: date.add(const Duration(hours: 9)),
      endTime: date.add(const Duration(hours: 11)),
      colorValue: 4286088320,
    );

    final map = block.toMap();
    expect(map['id'], 1);
    expect(map['title'], 'Deep Work');
    expect(map['colorValue'], 4286088320);

    final fromMap = Block.fromMap(map);
    expect(fromMap.title, 'Deep Work');
    expect(fromMap.colorValue, 4286088320);

    final task = Task(
      id: 2,
      blockId: 1,
      title: 'Write code',
      planned: true,
    );

    final taskMap = task.toMap();
    expect(taskMap['id'], 2);
    expect(taskMap['blockId'], 1);
    expect(taskMap['title'], 'Write code');

    final taskFromMap = Task.fromMap(taskMap);
    expect(taskFromMap.title, 'Write code');
    expect(taskFromMap.blockId, 1);
  });

  test('JournalNote model map serialization test', () {
    final now = DateTime(2026, 8, 28, 17, 30);
    final note = JournalNote(
      id: 10,
      date: DateTime(2026, 8, 28),
      timestamp: now,
      content: 'Captain log entry test',
      tag: 'Thought',
    );

    final map = note.toMap();
    expect(map['id'], 10);
    expect(map['content'], 'Captain log entry test');
    expect(map['tag'], 'Thought');

    final fromMap = JournalNote.fromMap(map);
    expect(fromMap.id, 10);
    expect(fromMap.content, 'Captain log entry test');
    expect(fromMap.tag, 'Thought');
    expect(fromMap.timestamp, now);
  });

  test('WeatherTag model map serialization test', () {
    final tag = WeatherTag(
      id: 3,
      name: 'Remote Work',
      icon: 'laptop',
      recurrenceRule: 'daily',
    );

    final map = tag.toMap();
    expect(map['id'], 3);
    expect(map['name'], 'Remote Work');

    final fromMap = WeatherTag.fromMap(map);
    expect(fromMap.id, 3);
    expect(fromMap.name, 'Remote Work');
  });

  test('ThemeProvider handles all 6 themes and cyclic switching correctly', () {
    final themeProvider = ThemeProvider();

    // 1. Midnight Oceanic (Dark)
    expect(themeProvider.currentThemeMode, AppThemeMode.oceanicDark);
    expect(themeProvider.currentThemeName, 'Midnight Oceanic');
    expect(themeProvider.themeData.brightness, Brightness.dark);

    // 2. Switch to Cyber Horizon
    themeProvider.setTheme(AppThemeMode.cyberTwilight);
    expect(themeProvider.currentThemeMode, AppThemeMode.cyberTwilight);
    expect(themeProvider.currentThemeName, 'Cyber Horizon');
    expect(themeProvider.themeData.brightness, Brightness.dark);

    // 3. Switch to Nordic Sea Mist (Light)
    themeProvider.setTheme(AppThemeMode.nordicLight);
    expect(themeProvider.currentThemeMode, AppThemeMode.nordicLight);
    expect(themeProvider.currentThemeName, 'Nordic Sea Mist');
    expect(themeProvider.themeData.brightness, Brightness.light);

    // 4. Switch to Crimson Corsair (Dark)
    themeProvider.setTheme(AppThemeMode.crimsonCorsair);
    expect(themeProvider.currentThemeMode, AppThemeMode.crimsonCorsair);
    expect(themeProvider.currentThemeName, 'Crimson Corsair');
    expect(themeProvider.themeData.brightness, Brightness.dark);

    // 5. Switch to Emerald Abyss (Dark)
    themeProvider.setTheme(AppThemeMode.emeraldAbyss);
    expect(themeProvider.currentThemeMode, AppThemeMode.emeraldAbyss);
    expect(themeProvider.currentThemeName, 'Emerald Abyss');
    expect(themeProvider.themeData.brightness, Brightness.dark);

    // 6. Switch to Golden Dune (Light)
    themeProvider.setTheme(AppThemeMode.goldenDune);
    expect(themeProvider.currentThemeMode, AppThemeMode.goldenDune);
    expect(themeProvider.currentThemeName, 'Golden Dune');
    expect(themeProvider.themeData.brightness, Brightness.light);

    // 7. Switch to Chronometer Shift (Auto 2h)
    themeProvider.setTheme(AppThemeMode.autoChronometer);
    expect(themeProvider.currentThemeMode, AppThemeMode.autoChronometer);
    expect(themeProvider.currentThemeName.contains('Chronometer Shift'), isTrue);

    // Verify 2-hour time calculation slots
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 0, 30)), AppThemeMode.oceanicDark);
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 2, 15)), AppThemeMode.emeraldAbyss);
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 4, 0)), AppThemeMode.cyberTwilight);
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 6, 45)), AppThemeMode.goldenDune);
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 8, 10)), AppThemeMode.nordicLight);
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 10, 0)), AppThemeMode.crimsonCorsair);
    // And afternoon cycles
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 18, 30)), AppThemeMode.goldenDune);
    expect(themeProvider.getAutoThemeForTime(DateTime(2026, 8, 28, 22, 15)), AppThemeMode.crimsonCorsair);

    // Test cyclic toggle through all themes including autoChronometer
    themeProvider.setTheme(AppThemeMode.oceanicDark);
    themeProvider.toggleNextTheme(); // -> cyberTwilight
    expect(themeProvider.currentThemeMode, AppThemeMode.cyberTwilight);
    themeProvider.toggleNextTheme(); // -> nordicLight
    expect(themeProvider.currentThemeMode, AppThemeMode.nordicLight);
    themeProvider.toggleNextTheme(); // -> crimsonCorsair
    expect(themeProvider.currentThemeMode, AppThemeMode.crimsonCorsair);
    themeProvider.toggleNextTheme(); // -> emeraldAbyss
    expect(themeProvider.currentThemeMode, AppThemeMode.emeraldAbyss);
    themeProvider.toggleNextTheme(); // -> goldenDune
    expect(themeProvider.currentThemeMode, AppThemeMode.goldenDune);
    themeProvider.toggleNextTheme(); // -> autoChronometer
    expect(themeProvider.currentThemeMode, AppThemeMode.autoChronometer);
    themeProvider.toggleNextTheme(); // -> oceanicDark
    expect(themeProvider.currentThemeMode, AppThemeMode.oceanicDark);
  });

  test('JSON backup structure and validation test', () {
    final sampleBackup = {
      'app': 'crows_nest',
      'version': 1,
      'exported_at': '2026-08-29T10:00:00.000Z',
      'data': {
        'blocks': [
          {
            'id': 1,
            'title': 'Deep Work Session',
            'category': 'Work',
            'date': '2026-08-29T00:00:00.000',
            'startTime': '2026-08-29T09:00:00.000',
            'endTime': '2026-08-29T11:00:00.000',
            'colorValue': 4286088320,
          }
        ],
        'tasks': [
          {
            'id': 1,
            'blockId': 1,
            'title': 'Implement Export/Import',
            'planned': 1,
            'executed': 0,
          }
        ],
        'journal_notes': [
          {
            'id': 1,
            'date': '2026-08-29T00:00:00.000',
            'timestamp': '2026-08-29T09:15:00.000',
            'content': 'Smooth sailing with JSON backup feature',
            'tag': 'Log',
          }
        ],
      },
    };

    final jsonString = jsonEncode(sampleBackup);
    expect(jsonString.contains('crows_nest'), isTrue);

    final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    expect(decoded['app'], 'crows_nest');
    expect(decoded['version'], 1);

    final data = decoded['data'] as Map<String, dynamic>;
    expect((data['blocks'] as List).length, 1);
    expect((data['tasks'] as List).length, 1);
    expect((data['journal_notes'] as List).length, 1);
  });
}
