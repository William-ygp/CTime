class CustomAudioTrack {
  CustomAudioTrack({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.durationSeconds = 0,
    this.syncStatus = 'Local',
  });

  final String id;
  String fileName;
  String filePath;
  int durationSeconds;
  String syncStatus; // 'Local', 'Sincronizado', 'Pendiente'

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'durationSeconds': durationSeconds,
      'syncStatus': syncStatus,
    };
  }

  factory CustomAudioTrack.fromMap(Map<String, dynamic> map) {
    return CustomAudioTrack(
      id: map['id'],
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      syncStatus: map['syncStatus'] ?? 'Local',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'durationSeconds': durationSeconds,
      'syncStatus': syncStatus,
    };
  }
}
