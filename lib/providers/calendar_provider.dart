import 'package:flutter/material.dart';
import 'package:crows_nest/models/block.dart';
import 'package:crows_nest/models/task.dart';
import 'package:crows_nest/models/execution_session.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/models/day_weather.dart';
import 'package:crows_nest/models/blueprint.dart';
import 'package:crows_nest/services/database_service.dart';

class CalendarProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  DateTime _currentDate = DateTime.now();
  DateTime get currentDate => _currentDate;

  DayWeather? _currentDayWeather;
  DayWeather? get currentDayWeather => _currentDayWeather;
  bool get isDayCharted => _currentDayWeather != null;

  List<Block> _blocks = [];
  List<Block> get blocks => _blocks;

  List<Task> _standaloneTasks = [];
  List<Task> get standaloneTasks => _standaloneTasks;

  List<ExecutionSession> _executionSessions = [];
  List<ExecutionSession> get executionSessions => _executionSessions;

  List<WeatherTag> _weatherTags = [];
  List<WeatherTag> get weatherTags => _weatherTags;

  List<BlockBlueprint> _blockBlueprints = [];
  List<BlockBlueprint> get blockBlueprints => _blockBlueprints;

  List<TaskBlueprint> _taskBlueprints = [];
  List<TaskBlueprint> get taskBlueprints => _taskBlueprints;

  CalendarProvider() {
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _currentDayWeather = await _db.getDayWeather(_currentDate);
    _blocks = await _db.getBlocksForDate(_currentDate);
    _executionSessions = await _db.getExecutionSessionsForDate(_currentDate);
    _standaloneTasks = await _db.getStandaloneTasks();
    _weatherTags = await _db.getWeatherTags();
    _blockBlueprints = await _db.getBlockBlueprints();
    _taskBlueprints = await _db.getTaskBlueprints();
    notifyListeners();
  }

  void setDate(DateTime date) {
    _currentDate = date;
    _loadAllData();
  }

  Future<void> addBlock(Block block) async {
    await _db.insertBlock(block);
    await _loadAllData();
  }

  Future<void> chartTheCourse(List<int> activeTagIds) async {
    final dw = DayWeather(date: _currentDate, activeTagIds: activeTagIds);
    await _db.insertDayWeather(dw);
    _currentDayWeather = dw;

    final blockBlueprints = await _db.getBlockBlueprints();
    final taskBlueprints = await _db.getTaskBlueprints();
    Map<int, int> blueprintIdToConcreteBlockId = {};

    for (var bp in blockBlueprints) {
      bool meetsRequired = bp.requiredTagIds.isEmpty || bp.requiredTagIds.every((id) => activeTagIds.contains(id));
      bool avoidsExcluded = bp.excludedTagIds.isEmpty || bp.excludedTagIds.every((id) => !activeTagIds.contains(id));
      
      if (meetsRequired && avoidsExcluded) {
        final startTime = DateTime(_currentDate.year, _currentDate.month, _currentDate.day, bp.startHour, bp.startMinute);
        final endTime = DateTime(_currentDate.year, _currentDate.month, _currentDate.day, bp.endHour, bp.endMinute);
        
        final block = Block(
          title: bp.title,
          category: bp.category,
          date: _currentDate,
          startTime: startTime,
          endTime: endTime,
          colorValue: bp.colorValue,
        );
        int concreteBlockId = await _db.insertBlock(block);
        if (bp.id != null) {
          blueprintIdToConcreteBlockId[bp.id!] = concreteBlockId;
        }
      }
    }

    for (var tp in taskBlueprints) {
      bool meetsRequired = tp.requiredTagIds.isEmpty || tp.requiredTagIds.every((id) => activeTagIds.contains(id));
      bool avoidsExcluded = tp.excludedTagIds.isEmpty || tp.excludedTagIds.every((id) => !activeTagIds.contains(id));
      
      if (meetsRequired && avoidsExcluded) {
        int? concreteBlockId;
        if (tp.blockBlueprintId != null) {
          if (!blueprintIdToConcreteBlockId.containsKey(tp.blockBlueprintId!)) continue;
          concreteBlockId = blueprintIdToConcreteBlockId[tp.blockBlueprintId!];
        }
        
        final task = Task(
          blockId: concreteBlockId,
          title: tp.title,
          planned: true,
          executed: false,
        );
        await _db.insertTask(task);
      }
    }
    
    await _loadAllData();
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task);
    await _loadAllData();
  }

  Future<void> toggleTaskPlanCompletion(Task task) async {
    final updatedTask = task.copyWith(completedPlan: !task.completedPlan);
    await _db.updateTask(updatedTask);
    await _loadAllData();
  }
  
  Future<void> toggleTaskExecutionCompletion(Task task) async {
    final updatedTask = task.copyWith(completedExecution: !task.completedExecution);
    await _db.updateTask(updatedTask);
    await _loadAllData();
  }

  // Execution Session Controls
  Future<void> startBlock(Block block, {DateTime? startTime}) async {
    // Check if there is already an active session
    if (isBlockActive(block.id!)) return;

    final session = ExecutionSession(
      blockId: block.id!,
      startTime: startTime ?? DateTime.now(),
    );
    await _db.insertExecutionSession(session);
    await _loadAllData();
  }

  Future<void> stopBlock(Block block, {DateTime? endTime}) async {
    final activeSession = _executionSessions.firstWhere(
      (s) => s.blockId == block.id && s.endTime == null,
      orElse: () => throw Exception('No active session found'),
    );
    
    final updatedSession = activeSession.copyWith(endTime: endTime ?? DateTime.now());
    await _db.updateExecutionSession(updatedSession);
    await _loadAllData();
  }

  bool isBlockActive(int blockId) {
    return _executionSessions.any((s) => s.blockId == blockId && s.endTime == null);
  }

  Future<void> addPastExecutionSession(int blockId, DateTime start, DateTime end) async {
    final session = ExecutionSession(
      blockId: blockId,
      startTime: start,
      endTime: end,
    );
    await _db.insertExecutionSession(session);
    await _loadAllData();
  }

  // Weather Tags CRUD
  Future<void> addWeatherTag(WeatherTag tag) async {
    await _db.insertWeatherTag(tag);
    await _loadAllData();
  }

  Future<void> updateWeatherTag(WeatherTag tag) async {
    await _db.updateWeatherTag(tag);
    await _loadAllData();
  }

  Future<void> deleteWeatherTag(int id) async {
    await _db.deleteWeatherTag(id);
    await _loadAllData();
  }

  // Block Blueprint CRUD
  Future<void> addBlockBlueprint(BlockBlueprint blueprint) async {
    await _db.insertBlockBlueprint(blueprint);
    await _loadAllData();
  }

  Future<void> updateBlockBlueprint(BlockBlueprint blueprint) async {
    await _db.updateBlockBlueprint(blueprint);
    await _loadAllData();
  }

  Future<void> deleteBlockBlueprint(int id) async {
    await _db.deleteBlockBlueprint(id);
    await _loadAllData();
  }

  // Task Blueprint CRUD
  Future<void> addTaskBlueprint(TaskBlueprint blueprint) async {
    await _db.insertTaskBlueprint(blueprint);
    await _loadAllData();
  }

  Future<void> updateTaskBlueprint(TaskBlueprint blueprint) async {
    await _db.updateTaskBlueprint(blueprint);
    await _loadAllData();
  }

  Future<void> deleteTaskBlueprint(int id) async {
    await _db.deleteTaskBlueprint(id);
    await _loadAllData();
  }
}
