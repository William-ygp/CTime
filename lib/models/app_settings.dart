class AppSettings {
  AppSettings({
    this.themeMode = 'Oscuro',
    this.brightness = 75.0,
    this.defaultAlarmTone = 'Timbre 1',
    this.esp32Ip = '192.168.1.44',
    this.esp32Mac = 'AA:BB:CC:DD:EE:FF',
    this.isConnected = false,
    this.automaticMode = true,
  });

  String themeMode;
  double brightness;
  String defaultAlarmTone;
  String esp32Ip;
  String esp32Mac;
  bool isConnected;
  bool automaticMode;

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'themeMode': themeMode,
      'brightness': brightness,
      'defaultAlarmTone': defaultAlarmTone,
      'esp32Ip': esp32Ip,
      'esp32Mac': esp32Mac,
      'isConnected': isConnected ? 1 : 0,
      'automaticMode': automaticMode ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: map['themeMode'] ?? 'Oscuro',
      brightness: (map['brightness'] as num?)?.toDouble() ?? 75.0,
      defaultAlarmTone: map['defaultAlarmTone'] ?? 'Timbre 1',
      esp32Ip: map['esp32Ip'] ?? '192.168.1.44',
      esp32Mac: map['esp32Mac'] ?? 'AA:BB:CC:DD:EE:FF',
      isConnected: (map['isConnected'] ?? 1) == 1,
      automaticMode: (map['automaticMode'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'brightness': brightness,
      'defaultAlarmTone': defaultAlarmTone,
      'esp32Ip': esp32Ip,
      'automaticMode': automaticMode,
    };
  }
}
