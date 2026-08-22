import 'package:flutter_test/flutter_test.dart';
import 'package:crows_nest/models/block.dart';
import 'package:crows_nest/models/task.dart';

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
      colorValue: 4286088320, // Colors.blue.value
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
}
