import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block.dart';
import '../providers/block_provider.dart';
import '../widgets/app_drawer.dart';

class BlocksScreen extends ConsumerStatefulWidget {
  const BlocksScreen({super.key});

  @override
  ConsumerState<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends ConsumerState<BlocksScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blocks & Inbox'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Library'),
              Tab(text: 'Inbox'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: const TabBarView(
          children: [
            _LibraryTab(),
            _InboxTab(),
          ],
        ),
      ),
    );
  }
}

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(blocksProvider).blocks;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: blocks.isEmpty
          ? const Center(child: Text('No blocks yet. Create your first reusable block!'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(block.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${block.tasks.length} tasks'),
                    children: [
                      ...block.tasks.map((task) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_box_outline_blank, size: 18),
                        title: Text(task.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            final newTasks = block.tasks.where((t) => t.id != task.id).toList();
                            ref.read(blocksProvider.notifier).updateBlock(block.copyWith(tasks: newTasks));
                          },
                        ),
                      )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Task'),
                              onPressed: () => _addTaskDialog(context, ref, block),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete Block', style: TextStyle(color: Colors.red)),
                              onPressed: () => ref.read(blocksProvider.notifier).deleteBlock(block.id),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBlockDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Block'),
      ),
    );
  }

  void _addBlockDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Block'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Morning Routine'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(blocksProvider.notifier).addBlock(Block(name: name));
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _addTaskDialog(BuildContext context, WidgetRef ref, Block block) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Make bed'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                final task = Task(blockId: block.id, title: title);
                ref.read(blocksProvider.notifier).updateBlock(block.copyWith(tasks: [...block.tasks, task]));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InboxTab extends ConsumerWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxTasks = ref.watch(blocksProvider).inboxTasks;
    final blocks = ref.watch(blocksProvider).blocks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Add to Inbox...',
              prefixIcon: const Icon(Icons.add),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                ref.read(blocksProvider.notifier).addInboxTask(val.trim());
              }
            },
          ),
        ),
        Expanded(
          child: inboxTasks.isEmpty
              ? const Center(child: Text('Inbox is empty. Quick capture ideas here!'))
              : ListView.builder(
                  itemCount: inboxTasks.length,
                  itemBuilder: (context, index) {
                    final task = inboxTasks[index];
                    return ListTile(
                      leading: const Icon(Icons.inbox),
                      title: Text(task.title),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.drive_file_move_outline),
                            tooltip: 'Move to Block',
                            onPressed: () => _showMoveDialog(context, ref, task, blocks),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => ref.read(blocksProvider.notifier).removeInboxTask(task.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showMoveDialog(BuildContext context, WidgetRef ref, Task task, List<Block> blocks) {
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a Block in Library first!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Move to Block', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...blocks.map((block) => ListTile(
                title: Text(block.name),
                onTap: () {
                  ref.read(blocksProvider.notifier).moveTaskToBlock(task, block.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved to ${block.name}')));
                },
              )),
            ],
          ),
        );
      }
    );
  }
}
