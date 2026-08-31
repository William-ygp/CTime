import 'package:flutter/material.dart';

class PersonalEvent {
  PersonalEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.date, // Format YYYY-MM-DD
    required this.time, // e.g. "10:00"
    required this.duration, // e.g. "45 min"
    required this.sound,
    required this.category,
    this.colorValue = 0xFF2E75D6,
    this.pendingSync = true,
  });

  final String id;
  String title;
  String description;
  String date;
  String time;
  String duration;
  String sound;
  String category;
  int colorValue;
  bool pendingSync;

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'duration': duration,
      'sound': sound,
      'category': category,
      'colorValue': colorValue,
      'pendingSync': pendingSync ? 1 : 0,
    };
  }

  factory PersonalEvent.fromMap(Map<String, dynamic> map) {
    return PersonalEvent(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '10:00',
      duration: map['duration'] ?? '30 min',
      sound: map['sound'] ?? 'Timbre 1',
      category: map['category'] ?? 'Personal',
      colorValue: map['colorValue'] ?? 0xFF2E75D6,
      pendingSync: (map['pendingSync'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'duration': duration,
      'sound': sound,
      'category': category,
    };
  }
}
