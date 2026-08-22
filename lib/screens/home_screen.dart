import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/providers/calendar_provider.dart';
import 'package:crows_nest/models/block.dart' as model;
import 'package:crows_nest/models/task.dart';
import 'package:crows_nest/models/execution_session.dart';
import 'package:crows_nest/screens/add_entry_dialog.dart';
import 'package:crows_nest/screens/add_task_dialog.dart';
import 'package:crows_nest/screens/weather_report_screen.dart';
import 'package:crows_nest/screens/block_details_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:async';

const double hourHeight = 80.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Calculate initial scroll position immediately so it's ready when the calendar renders
    final now = DateTime.now();
    final offset = (now.hour * hourHeight) + (now.minute / 60 * hourHeight);
    
    // Set target to 2.5 hours before current time to center it lower on the screen
    double initialTarget = offset - (2.5 * hourHeight);
    if (initialTarget < 0) initialTarget = 0;
    
    _scrollController = ScrollController(initialScrollOffset: initialTarget);

    // Redraw every minute so active execution blocks expand
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final offset = (now.hour * hourHeight) + (now.minute / 60 * hourHeight);
    
    // Scroll so that the top of the view is 2.5 hours before the current time
    double target = offset - (2.5 * hourHeight);
    
    // Prevent scrolling past midnight (top of the calendar)
    if (target < 0) target = 0;

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showAddEntryDialog(BuildContext context, CalendarProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEntryDialog(
          provider: provider,
          currentDate: provider.currentDate,
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, CalendarProvider provider, {int? initialBlockId}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          blocks: provider.blocks,
          initialBlockId: initialBlockId,
          onAdd: (task) {
            provider.addTask(task);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        if (!provider.isDayCharted) {
          return const WeatherReportScreen();
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: 24 * hourHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeGutter(),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: _buildColumn(provider, true)),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: _buildColumn(provider, false)),
                      ],
                    ),
                  ),
                ),
              ),
              _buildInbox(provider),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEntryDialog(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildTimeGutter() {
    return SizedBox(
      width: 60,
      child: Stack(
        children: List.generate(24, (index) {
          final time = DateTime(2020, 1, 1, index);
          return Positioned(
            top: index * hourHeight,
            left: 0,
            right: 0,
            child: Container(
              height: hourHeight,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: Text(
                DateFormat('ha').format(time).toLowerCase(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildColumn(CalendarProvider provider, bool isPlan) {
    return Stack(
      children: [
        // Background grid lines
        ...List.generate(24, (index) {
          return Positioned(
            top: index * hourHeight,
            left: 0,
            right: 0,
            child: Container(
              height: hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
            ),
          );
        }),
        // Column header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.white.withOpacity(0.8),
            child: Text(
              isPlan ? 'Plan' : 'Execution',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
        ),
        // Render blocks
        if (isPlan)
          ...provider.blocks.map((block) {
            final startHour = block.startTime.hour + (block.startTime.minute / 60.0);
            final endHour = block.endTime.hour + (block.endTime.minute / 60.0);
            final duration = endHour - startHour;
            return Positioned(
              top: startHour * hourHeight,
              left: 4,
              right: 4,
              height: duration * hourHeight,
              child: _buildPlanBlockWidget(block, provider),
            );
          }).toList()
        else
          ...provider.executionSessions.map((session) {
            final block = provider.blocks.firstWhere(
              (b) => b.id == session.blockId,
              orElse: () => model.Block(
                title: 'Unknown',
                category: 'unknown',
                date: DateTime.now(),
                startTime: DateTime.now(),
                endTime: DateTime.now(),
                colorValue: Colors.grey.value,
              ),
            );
            final startHour = session.startTime.hour + (session.startTime.minute / 60.0);
            final end = session.endTime ?? DateTime.now();
            final endHour = end.hour + (end.minute / 60.0);
            double duration = endHour - startHour;
            if (duration < 0.25) duration = 0.25; // min height for visibility
            
            return Positioned(
              top: startHour * hourHeight,
              left: 4,
              right: 4,
              height: duration * hourHeight,
              child: _buildExecutionSessionWidget(session, block),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildPlanBlockWidget(model.Block block, CalendarProvider provider) {
    final isActive = provider.isBlockActive(block.id!);
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BlockDetailsDialog(block: block, provider: provider),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: Color(block.colorValue).withOpacity(0.2),
          border: Border(left: BorderSide(color: Color(block.colorValue), width: 4)),
          borderRadius: BorderRadius.circular(4),
        ),
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  block.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              InkResponse(
                radius: 16,
                onTap: () {
                  if (isActive) {
                    provider.stopBlock(block);
                  } else {
                    provider.startBlock(block);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isActive ? Icons.pause_circle : Icons.play_circle,
                    size: 20,
                    color: Color(block.colorValue),
                  ),
                ),
              )
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: block.tasks.where((t) => t.planned).map((task) {
                return Row(
                  children: [
                    InkWell(
                      onTap: () => provider.toggleTaskPlanCompletion(task),
                      child: Icon(
                        task.completedPlan ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 12,
                        color: Color(block.colorValue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 10,
                          decoration: task.completedPlan ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildExecutionSessionWidget(ExecutionSession session, model.Block block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Color(block.colorValue).withOpacity(0.4),
        border: Border(left: BorderSide(color: Color(block.colorValue), width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (session.endTime == null)
            const Text(
              "In Progress...",
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildInbox(CalendarProvider provider) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Inbox (Standalone Tasks)", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAddTaskDialog(context, provider),
                )
              ],
            ),
          ),
          Expanded(
            child: provider.standaloneTasks.isEmpty
                ? const Center(child: Text("No tasks in inbox.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: provider.standaloneTasks.length,
                    itemBuilder: (context, index) {
                      final task = provider.standaloneTasks[index];
                      return ListTile(
                        dense: true,
                        leading: InkWell(
                          onTap: () => provider.toggleTaskPlanCompletion(task),
                          child: Icon(
                            task.completedPlan ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completedPlan ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
