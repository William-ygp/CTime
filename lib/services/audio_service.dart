import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/custom_audio_track.dart';
import 'cloud_database_service.dart';

class AudioService {
  AudioService._privateConstructor();
  static final AudioService instance = AudioService._privateConstructor();

  static const List<String> builtInTones = [
    'Timbre 1',
    'Timbre 2',
    'Timbre 3',
    'Campana corta',
    'Suave digital',
  ];

  Future<List<String>> getAllAvailableSoundOptions() async {
    final customTracks = await CloudDatabaseService.instance.getCustomAudioTracks();
    final customNames = customTracks.map((t) => '🎵 ${t.fileName}').toList();
    return [...builtInTones, ...customNames];
  }

  Future<CustomAudioTrack?> pickAndSaveCustomAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.first;
    if (pickedFile.path == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDocDir.path, 'custom_audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final newFileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    final savedPath = p.join(audioDir.path, newFileName);

    await File(pickedFile.path!).copy(savedPath);

    final track = CustomAudioTrack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: pickedFile.name,
      filePath: savedPath,
      durationSeconds: 15,
      syncStatus: 'En Nube',
    );

    await CloudDatabaseService.instance.saveCustomAudioTrack(track);
    return track;
  }
}
