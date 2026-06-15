import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block.dart';
import '../repositories/block_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final blockRepositoryProvider = Provider((ref) {
  return BlockRepository(ref.watch(sharedPreferencesProvider));
});

class BlocksState {
  final List<Block> blocks;
  final List<Task> inboxTasks;
  BlocksState({required this.blocks, required this.inboxTasks});
}

class BlocksNotifier extends Notifier<BlocksState> {
  late final BlockRepository _repo;

  @override
  BlocksState build() {
    _repo = ref.watch(blockRepositoryProvider);
    return _loadState();
  }

  BlocksState _loadState() {
    return BlocksState(
      blocks: _repo.getBlocks(),
      inboxTasks: _repo.getInboxTasks(),
    );
  }

  void reload() {
    state = _loadState();
  }

  // Block Methods
  void addBlock(Block block) async {
    await _repo.addBlock(block);
    reload();
  }

  void updateBlock(Block block) async {
    await _repo.updateBlock(block);
    reload();
  }

  void deleteBlock(String id) async {
    await _repo.deleteBlock(id);
    reload();
  }

  // Inbox Methods
  void addInboxTask(String title) async {
    final task = Task(blockId: 'inbox', title: title);
    await _repo.addInboxTask(task);
    reload();
  }

  void removeInboxTask(String taskId) async {
    await _repo.removeInboxTask(taskId);
    reload();
  }

  void moveTaskToBlock(Task task, String targetBlockId) async {
    final block = state.blocks.firstWhere((b) => b.id == targetBlockId);
    final updatedTask = task.copyWith(blockId: targetBlockId);
    final newTasks = [...block.tasks, updatedTask];
    await _repo.updateBlock(block.copyWith(tasks: newTasks));
    await _repo.removeInboxTask(task.id);
    reload();
  }
}

final blocksProvider = NotifierProvider<BlocksNotifier, BlocksState>(() {
  return BlocksNotifier();
});
