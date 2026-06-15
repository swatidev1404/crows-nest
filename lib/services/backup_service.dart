import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/block_provider.dart';
import '../providers/calendar_provider.dart';

final backupServiceProvider = Provider((ref) => BackupService(ref));

class BackupService {
  final Ref _ref;

  BackupService(this._ref);

  Future<void> exportBackup() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final allKeys = prefs.getKeys();
    
    final Map<String, dynamic> data = {};
    for (final key in allKeys) {
      if (key == 'blocks_v1' || key == 'inbox_tasks_v1' || key.startsWith('calendar_v1_')) {
        data[key] = prefs.getString(key);
      }
    }
    
    final jsonString = jsonEncode(data);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/crows_nest_v1_backup.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Crow\'s Nest V1 Backup'),
    );
  }

  Future<void> importFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final prefs = _ref.read(sharedPreferencesProvider);
    
    for (final entry in data.entries) {
      if (entry.key == 'blocks_v1' || entry.key == 'inbox_tasks_v1' || entry.key.startsWith('calendar_v1_')) {
         await prefs.setString(entry.key, entry.value as String);
      }
    }

    _ref.read(blocksProvider.notifier).reload();
    _ref.read(calendarProvider.notifier).reload();
  }
}
