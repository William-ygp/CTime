import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';
import 'cloud_database_service.dart';

class Esp32StatusResult {
  Esp32StatusResult({
    required this.isConnected,
    this.dfPlayerReady = false,
    this.statusMessage = 'Sin conexión',
    this.ip = '',
  });

  final bool isConnected;
  final bool dfPlayerReady;
  final String statusMessage;
  final String ip;
}

class Esp32SyncService {
  Esp32SyncService._privateConstructor();
  static final Esp32SyncService instance = Esp32SyncService._privateConstructor();

  Future<Esp32StatusResult> checkRealConnection() async {
    final settings = CloudDatabaseService.instance.settings;
    try {
      final url = Uri.parse('http://${settings.esp32Ip}/api/status');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        bool dfPlayer = false;
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            dfPlayer = data['dfPlayerReady'] == true || data['dfPlayer'] == 'ready';
          }
        } catch (_) {}

        settings.isConnected = true;
        await CloudDatabaseService.instance.saveSettings(settings);

        return Esp32StatusResult(
          isConnected: true,
          dfPlayerReady: dfPlayer,
          statusMessage: dfPlayer
              ? 'ESP32 + DFPlayer Mini: En línea'
              : 'ESP32 Conectado (DFPlayer Mini no detectado)',
          ip: settings.esp32Ip,
        );
      }
    } catch (_) {
      // Real connection failed (host unreachable, timeout, offline)
    }

    settings.isConnected = false;
    await CloudDatabaseService.instance.saveSettings(settings);

    return Esp32StatusResult(
      isConnected: false,
      dfPlayerReady: false,
      statusMessage: 'ESP32 + DFPlayer Mini: Desconectado',
      ip: settings.esp32Ip,
    );
  }

  Future<bool> pushLocalStateToClock() async {
    try {
      final cloud = CloudDatabaseService.instance;
      final settings = cloud.settings;
      final alarms = await cloud.getAlarms();
      final events = await cloud.getPersonalEvents();
      final classBlocks = await cloud.getSchoolClassBlocks();

      final payload = {
        'settings': settings.toJson(),
        'alarms': alarms.map((a) => a.toJson()).toList(),
        'personalEvents': events.map((e) => e.toJson()).toList(),
        'schoolClassBlocks': classBlocks.map((b) => b.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final url = Uri.parse('http://${settings.esp32Ip}/api/sync');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        for (var a in alarms) {
          a.pendingSync = false;
        }
        for (var e in events) {
          e.pendingSync = false;
        }
        for (var b in classBlocks) {
          b.pendingSync = false;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchClockState() async {
    try {
      final settings = CloudDatabaseService.instance.settings;
      final url = Uri.parse('http://${settings.esp32Ip}/api/status');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> syncAudioFile(File audioFile, AppSettings settings) async {
    try {
      final url = Uri.parse('http://${settings.esp32Ip}/api/upload_audio');
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      return streamedResponse.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
