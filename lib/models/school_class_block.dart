class SchoolClassBlock {
  SchoolClassBlock({
    required this.id,
    required this.subject,
    required this.dayOfWeek, // 1 = Monday .. 7 = Sunday
    required this.startTime, // "08:00"
    required this.durationMinutes, // 45
    required this.sound,
    this.repeatRule = 'Semanal',
    this.pendingSync = true,
  });

  final String id;
  String subject;
  int dayOfWeek;
  String startTime;
  int durationMinutes;
  String sound;
  String repeatRule;
  bool pendingSync;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'sound': sound,
      'repeatRule': repeatRule,
      'pendingSync': pendingSync ? 1 : 0,
    };
  }

  factory SchoolClassBlock.fromMap(Map<String, dynamic> map) {
    return SchoolClassBlock(
      id: map['id'],
      subject: map['subject'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      startTime: map['startTime'] ?? '08:00',
      durationMinutes: map['durationMinutes'] ?? 45,
      sound: map['sound'] ?? 'Timbre 1',
      repeatRule: map['repeatRule'] ?? 'Semanal',
      pendingSync: (map['pendingSync'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'sound': sound,
      'repeatRule': repeatRule,
    };
  }
}
