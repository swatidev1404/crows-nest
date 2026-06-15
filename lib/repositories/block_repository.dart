import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block.dart';

class BlockRepository {
  final SharedPreferences _prefs;
  static const _key = 'blocks_v1';
  static const _inboxKey = 'inbox_tasks_v1';

  BlockRepository(this._prefs);

  List<Block> getBlocks() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Block.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBlocks(List<Block> blocks) async {
    await _prefs.setString(_key, jsonEncode(blocks.map((b) => b.toJson()).toList()));
  }

  Future<void> addBlock(Block block) async {
    final blocks = getBlocks()..add(block);
    await saveBlocks(blocks);
  }

  Future<void> updateBlock(Block updated) async {
    final blocks = getBlocks().map((b) => b.id == updated.id ? updated : b).toList();
    await saveBlocks(blocks);
  }

  Future<void> deleteBlock(String id) async {
    final blocks = getBlocks().where((b) => b.id != id).toList();
    await saveBlocks(blocks);
  }

  // --- INBOX METHODS ---

  List<Task> getInboxTasks() {
    final raw = _prefs.getString(_inboxKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveInboxTasks(List<Task> tasks) async {
    await _prefs.setString(_inboxKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> addInboxTask(Task task) async {
    final tasks = getInboxTasks()..add(task);
    await saveInboxTasks(tasks);
  }

  Future<void> removeInboxTask(String taskId) async {
    final tasks = getInboxTasks().where((t) => t.id != taskId).toList();
    await saveInboxTasks(tasks);
  }
}
