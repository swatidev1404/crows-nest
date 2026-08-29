class JournalNote {
  final int? id;
  final DateTime date;
  final DateTime timestamp;
  final String content;
  final String tag;

  JournalNote({
    this.id,
    required this.date,
    required this.timestamp,
    required this.content,
    this.tag = 'Log',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'content': content,
      'tag': tag,
    };
  }

  factory JournalNote.fromMap(Map<String, dynamic> map) {
    return JournalNote(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      content: map['content'] as String,
      tag: (map['tag'] as String?) ?? 'Log',
    );
  }

  JournalNote copyWith({
    int? id,
    DateTime? date,
    DateTime? timestamp,
    String? content,
    String? tag,
  }) {
    return JournalNote(
      id: id ?? this.id,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
      tag: tag ?? this.tag,
    );
  }
}
