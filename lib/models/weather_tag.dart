import 'dart:convert';

class WeatherTag {
  final int? id;
  final String name;
  final String icon;
  final String recurrenceRule; // JSON string

  WeatherTag({
    this.id,
    required this.name,
    this.icon = 'tag',
    required this.recurrenceRule,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'recurrenceRule': recurrenceRule,
    };
  }

  factory WeatherTag.fromMap(Map<String, dynamic> map) {
    return WeatherTag(
      id: map['id'],
      name: map['name'],
      icon: map['icon'] ?? 'tag',
      recurrenceRule: map['recurrenceRule'] ?? '{}',
    );
  }
}
