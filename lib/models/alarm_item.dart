class AlarmItem {
  AlarmItem({
    required this.id,
    required this.time,
    required this.title,
    required this.sound,
    required this.enabled,
    this.repeatDays = const [1, 2, 3, 4, 5],
    this.pendingSync = true,
  });

  final String id;
  String time;
  String title;
  String sound;
  bool enabled;
  List<int> repeatDays; // 1=Mon, 7=Sun
  bool pendingSync;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'title': title,
      'sound': sound,
      'enabled': enabled ? 1 : 0,
      'repeatDays': repeatDays.join(','),
      'pendingSync': pendingSync ? 1 : 0,
    };
  }

  factory AlarmItem.fromMap(Map<String, dynamic> map) {
    List<int> days = [];
    if (map['repeatDays'] != null && map['repeatDays'].toString().isNotEmpty) {
      days = map['repeatDays']
          .toString()
          .split(',')
          .map((e) => int.tryParse(e.trim()) ?? 1)
          .toList();
    }
    return AlarmItem(
      id: map['id'],
      time: map['time'] ?? '07:00',
      title: map['title'] ?? 'Alarma',
      sound: map['sound'] ?? 'Timbre 1',
      enabled: (map['enabled'] ?? 1) == 1,
      repeatDays: days.isEmpty ? [1, 2, 3, 4, 5] : days,
      pendingSync: (map['pendingSync'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'title': title,
      'sound': sound,
      'enabled': enabled,
      'repeatDays': repeatDays,
    };
  }
}
