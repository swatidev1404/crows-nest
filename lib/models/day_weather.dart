import 'dart:convert';

class DayWeather {
  final int? id;
  final DateTime date;
  final List<int> activeTagIds;

  DayWeather({
    this.id,
    required this.date,
    required this.activeTagIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // Store just the YYYY-MM-DD
      'activeTagIds': jsonEncode(activeTagIds),
    };
  }

  factory DayWeather.fromMap(Map<String, dynamic> map) {
    return DayWeather(
      id: map['id'],
      date: DateTime.parse(map['date']),
      activeTagIds: List<int>.from(jsonDecode(map['activeTagIds'] ?? '[]')),
    );
  }
}
