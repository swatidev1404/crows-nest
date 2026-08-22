class ExecutionSession {
  final int? id;
  final int blockId;
  final DateTime startTime;
  final DateTime? endTime;

  ExecutionSession({
    this.id,
    required this.blockId,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockId': blockId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory ExecutionSession.fromMap(Map<String, dynamic> map) {
    return ExecutionSession(
      id: map['id'],
      blockId: map['blockId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }

  ExecutionSession copyWith({
    int? id,
    int? blockId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ExecutionSession(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
