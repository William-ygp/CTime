import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alarm_item.dart';
import '../models/app_settings.dart';
import '../models/custom_audio_track.dart';
import '../models/personal_event.dart';
import '../models/school_class_block.dart';

class CloudDatabaseService {
  CloudDatabaseService._privateConstructor();
  static final CloudDatabaseService instance = CloudDatabaseService._privateConstructor();

  // Cloud API Endpoint Base URL (can be customized by user or environment)
  String cloudEndpoint = 'https://api.ctime-clock.cloud/v1';

  // Light in-memory state
  AppSettings settings = AppSettings();
  List<AlarmItem> alarms = [
    AlarmItem(
      id: '1',
      time: '06:30',
      title: 'Inicio de jornada',
      sound: 'Timbre 1',
      enabled: true,
    ),
    AlarmItem(
      id: '2',
      time: '10:45',
      title: 'Cambio de clase',
      sound: 'Campana corta',
      enabled: true,
    ),
    AlarmItem(
      id: '3',
      time: '19:00',
      title: 'Rutina nocturna',
      sound: 'Suave digital',
      enabled: false,
    ),
  ];
  List<PersonalEvent> personalEvents = [
    PersonalEvent(
      id: '1',
      title: 'Matemáticas',
      description: 'Repaso de álgebra',
      date: '2026-08-07',
      time: '10:00',
      duration: '45 min',
      sound: 'Timbre 1',
      category: 'Clase',
      colorValue: 0xFF2E75D6,
    ),
    PersonalEvent(
      id: '2',
      title: 'Trabajo en proyecto',
      description: 'Desarrollo Flutter Cloud Sync',
      date: '2026-08-07',
      time: '12:00',
      duration: '60 min',
      sound: 'Timbre 2',
      category: 'Rutina',
      colorValue: 0xFF00A8FF,
    ),
    PersonalEvent(
      id: '3',
      title: 'Gym & Entrenamiento',
      description: 'Rutina de cardio y pesas',
      date: '2026-08-07',
      time: '18:00',
      duration: '90 min',
      sound: 'Timbre 3',
      category: 'Personal',
      colorValue: 0xFF16D676,
    ),
  ];
  List<SchoolClassBlock> schoolClassBlocks = [
    SchoolClassBlock(
      id: '1',
      subject: 'Matemáticas Avanzadas',
      dayOfWeek: 1, // Mon
      startTime: '08:00',
      durationMinutes: 45,
      sound: 'Timbre 1',
    ),
    SchoolClassBlock(
      id: '2',
      subject: 'Física General',
      dayOfWeek: 1, // Mon
      startTime: '09:00',
      durationMinutes: 45,
      sound: 'Campana corta',
    ),
    SchoolClassBlock(
      id: '3',
      subject: 'Programación Dart',
      dayOfWeek: 3, // Wed
      startTime: '10:00',
      durationMinutes: 60,
      sound: 'Timbre 2',
    ),
  ];
  List<CustomAudioTrack> customAudioTracks = [];

  // --- CLOUD SYNC METHOD ---
  Future<bool> syncWithCloud() async {
    try {
      final payload = {
        'settings': settings.toJson(),
        'alarms': alarms.map((a) => a.toJson()).toList(),
        'personalEvents': personalEvents.map((e) => e.toJson()).toList(),
        'schoolClassBlocks': schoolClassBlocks.map((b) => b.toJson()).toList(),
        'customAudioTracks': customAudioTracks.map((t) => t.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final url = Uri.parse('$cloudEndpoint/sync');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] != null) {
          _updateFromCloudJson(data['data']);
        }
        return true;
      }
      return false;
    } catch (_) {
      // In offline/mock mode, return success for light in-memory state
      return true;
    }
  }

  void _updateFromCloudJson(Map<String, dynamic> json) {
    if (json['settings'] != null) {
      settings = AppSettings.fromMap(json['settings']);
    }
    if (json['alarms'] != null && json['alarms'] is List) {
      alarms = (json['alarms'] as List).map((m) => AlarmItem.fromMap(m)).toList();
    }
    if (json['personalEvents'] != null && json['personalEvents'] is List) {
      personalEvents = (json['personalEvents'] as List).map((m) => PersonalEvent.fromMap(m)).toList();
    }
    if (json['schoolClassBlocks'] != null && json['schoolClassBlocks'] is List) {
      schoolClassBlocks = (json['schoolClassBlocks'] as List).map((m) => SchoolClassBlock.fromMap(m)).toList();
    }
    if (json['customAudioTracks'] != null && json['customAudioTracks'] is List) {
      customAudioTracks = (json['customAudioTracks'] as List).map((m) => CustomAudioTrack.fromMap(m)).toList();
    }
  }

  // --- CRUD METHODS FOR IN-MEMORY AND CLOUD SYNC ---

  // Settings
  Future<void> saveSettings(AppSettings newSettings) async {
    settings = newSettings;
    await syncWithCloud();
  }

  // Alarms
  Future<List<AlarmItem>> getAlarms() async => alarms;

  Future<void> saveAlarm(AlarmItem alarm) async {
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }
    await syncWithCloud();
  }

  Future<void> deleteAlarm(String id) async {
    alarms.removeWhere((a) => a.id == id);
    await syncWithCloud();
  }

  // Personal Events
  Future<List<PersonalEvent>> getPersonalEvents() async => personalEvents;

  Future<void> savePersonalEvent(PersonalEvent event) async {
    final index = personalEvents.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      personalEvents[index] = event;
    } else {
      personalEvents.add(event);
    }
    await syncWithCloud();
  }

  Future<void> deletePersonalEvent(String id) async {
    personalEvents.removeWhere((e) => e.id == id);
    await syncWithCloud();
  }

  // School Class Blocks
  Future<List<SchoolClassBlock>> getSchoolClassBlocks() async => schoolClassBlocks;

  Future<void> saveSchoolClassBlock(SchoolClassBlock block) async {
    final index = schoolClassBlocks.indexWhere((b) => b.id == block.id);
    if (index >= 0) {
      schoolClassBlocks[index] = block;
    } else {
      schoolClassBlocks.add(block);
    }
    await syncWithCloud();
  }

  Future<void> deleteSchoolClassBlock(String id) async {
    schoolClassBlocks.removeWhere((b) => b.id == id);
    await syncWithCloud();
  }

  // Custom Audio Tracks
  Future<List<CustomAudioTrack>> getCustomAudioTracks() async => customAudioTracks;

  Future<void> saveCustomAudioTrack(CustomAudioTrack track) async {
    final index = customAudioTracks.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      customAudioTracks[index] = track;
    } else {
      customAudioTracks.add(track);
    }
    await syncWithCloud();
  }

  Future<void> deleteCustomAudioTrack(String id) async {
    customAudioTracks.removeWhere((t) => t.id == id);
    await syncWithCloud();
  }
}
