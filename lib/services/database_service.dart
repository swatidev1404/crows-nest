import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crows_nest/models/block.dart';
import 'package:crows_nest/models/task.dart';
import 'package:crows_nest/models/execution_session.dart';
import 'package:crows_nest/models/weather_tag.dart';
import 'package:crows_nest/models/day_weather.dart';
import 'package:crows_nest/models/blueprint.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'crows_nest.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS blocks');
      await db.execute('DROP TABLE IF EXISTS execution_sessions');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE blocks ADD COLUMN recurrence TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE weather_tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          recurrenceRule TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE day_weather (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          activeTagIds TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE block_blueprints (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          startHour INTEGER NOT NULL,
          startMinute INTEGER NOT NULL,
          endHour INTEGER NOT NULL,
          endMinute INTEGER NOT NULL,
          colorValue INTEGER NOT NULL,
          requiredTagIds TEXT NOT NULL,
          excludedTagIds TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE task_blueprints (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          blockBlueprintId INTEGER,
          title TEXT NOT NULL,
          requiredTagIds TEXT NOT NULL,
          excludedTagIds TEXT NOT NULL,
          FOREIGN KEY (blockBlueprintId) REFERENCES block_blueprints (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        recurrence TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        blockId INTEGER,
        title TEXT NOT NULL,
        planned INTEGER NOT NULL,
        executed INTEGER NOT NULL,
        completedPlan INTEGER NOT NULL,
        completedExecution INTEGER NOT NULL,
        FOREIGN KEY (blockId) REFERENCES blocks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE execution_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        blockId INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        FOREIGN KEY (blockId) REFERENCES blocks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE weather_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        recurrenceRule TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE day_weather (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        activeTagIds TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE block_blueprints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        startHour INTEGER NOT NULL,
        startMinute INTEGER NOT NULL,
        endHour INTEGER NOT NULL,
        endMinute INTEGER NOT NULL,
        colorValue INTEGER NOT NULL,
        requiredTagIds TEXT NOT NULL,
        excludedTagIds TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE task_blueprints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        blockBlueprintId INTEGER,
        title TEXT NOT NULL,
        requiredTagIds TEXT NOT NULL,
        excludedTagIds TEXT NOT NULL,
        FOREIGN KEY (blockBlueprintId) REFERENCES block_blueprints (id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD for Blocks
  Future<int> insertBlock(Block block) async {
    final db = await database;
    return await db.insert('blocks', block.toMap());
  }

  Future<List<Block>> getBlocksForDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> blockMaps = await db.query('blocks');
    List<Block> blocks = [];
    for (var map in blockMaps) {
      final block = Block.fromMap(map);
      if (block.date.year == date.year && block.date.month == date.month && block.date.day == date.day) {
        final tasks = await getTasksForBlock(block.id!);
        blocks.add(block.copyWith(tasks: tasks));
      }
    }
    blocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    return blocks;
  }

  Future<void> updateBlock(Block block) async {
    final db = await database;
    await db.update('blocks', block.toMap(), where: 'id = ?', whereArgs: [block.id]);
  }

  Future<void> deleteBlock(int id) async {
    final db = await database;
    await db.delete('blocks', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD for Tasks
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksForBlock(int blockId) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'blockId = ?', whereArgs: [blockId]);
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }
  
  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Task>> getStandaloneTasks() async {
    final db = await database;
    final maps = await db.query('tasks', where: 'blockId IS NULL');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // CRUD for Execution Sessions
  Future<int> insertExecutionSession(ExecutionSession session) async {
    final db = await database;
    return await db.insert('execution_sessions', session.toMap());
  }

  Future<List<ExecutionSession>> getExecutionSessionsForDate(DateTime date) async {
    final db = await database;
    // For now we just query all and filter, similarly to blocks.
    final maps = await db.query('execution_sessions');
    return maps.map((map) => ExecutionSession.fromMap(map)).where((s) {
      return s.startTime.year == date.year &&
             s.startTime.month == date.month &&
             s.startTime.day == date.day;
    }).toList();
  }

  Future<void> updateExecutionSession(ExecutionSession session) async {
    final db = await database;
    await db.update('execution_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  // CRUD for WeatherTags
  Future<int> insertWeatherTag(WeatherTag tag) async {
    final db = await database;
    return await db.insert('weather_tags', tag.toMap());
  }

  Future<List<WeatherTag>> getWeatherTags() async {
    final db = await database;
    final maps = await db.query('weather_tags');
    return maps.map((map) => WeatherTag.fromMap(map)).toList();
  }

  Future<void> updateWeatherTag(WeatherTag tag) async {
    final db = await database;
    await db.update('weather_tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteWeatherTag(int id) async {
    final db = await database;
    await db.delete('weather_tags', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD for DayWeather
  Future<int> insertDayWeather(DayWeather dw) async {
    final db = await database;
    return await db.insert('day_weather', dw.toMap());
  }

  Future<DayWeather?> getDayWeather(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await db.query('day_weather', where: 'date = ?', whereArgs: [dateStr]);
    if (maps.isNotEmpty) {
      return DayWeather.fromMap(maps.first);
    }
    return null;
  }

  // CRUD for Blueprints
  Future<int> insertBlockBlueprint(BlockBlueprint blueprint) async {
    final db = await database;
    return await db.insert('block_blueprints', blueprint.toMap());
  }

  Future<List<BlockBlueprint>> getBlockBlueprints() async {
    final db = await database;
    final maps = await db.query('block_blueprints');
    return maps.map((map) => BlockBlueprint.fromMap(map)).toList();
  }

  Future<void> updateBlockBlueprint(BlockBlueprint blueprint) async {
    final db = await database;
    await db.update('block_blueprints', blueprint.toMap(), where: 'id = ?', whereArgs: [blueprint.id]);
  }

  Future<void> deleteBlockBlueprint(int id) async {
    final db = await database;
    await db.delete('block_blueprints', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTaskBlueprint(TaskBlueprint blueprint) async {
    final db = await database;
    return await db.insert('task_blueprints', blueprint.toMap());
  }

  Future<List<TaskBlueprint>> getTaskBlueprints() async {
    final db = await database;
    final maps = await db.query('task_blueprints');
    return maps.map((map) => TaskBlueprint.fromMap(map)).toList();
  }

  Future<void> updateTaskBlueprint(TaskBlueprint blueprint) async {
    final db = await database;
    await db.update('task_blueprints', blueprint.toMap(), where: 'id = ?', whereArgs: [blueprint.id]);
  }

  Future<void> deleteTaskBlueprint(int id) async {
    final db = await database;
    await db.delete('task_blueprints', where: 'id = ?', whereArgs: [id]);
  }

  // Month & Day Aggregations for Calendar
  Future<Set<String>> getChartedDatesInMonth(int year, int month) async {
    final db = await database;
    final m = month.toString().padLeft(2, '0');
    final pattern = '\-\%';
    final maps = await db.query(
      'day_weather',
      columns: ['date'],
      where: 'date LIKE ?',
      whereArgs: [pattern],
    );
    return maps.map((row) => (row['date'] as String).split('T')[0]).toSet();
  }

  Future<Map<String, int>> getBlockCountsByDateInMonth(int year, int month) async {
    final db = await database;
    final m = month.toString().padLeft(2, '0');
    final pattern = '\-\%';
    final maps = await db.query(
      'blocks',
      columns: ['date'],
      where: 'date LIKE ?',
      whereArgs: [pattern],
    );
    final Map<String, int> counts = {};
    for (var row in maps) {
      final dateStr = (row['date'] as String).split('T')[0];
      counts[dateStr] = (counts[dateStr] ?? 0) + 1;
    }
    return counts;
  }
}