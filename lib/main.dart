import 'dart:async';
import 'package:flutter/material.dart';

import 'models/alarm_item.dart';
import 'models/app_settings.dart';
import 'models/custom_audio_track.dart';
import 'models/personal_event.dart';
import 'models/school_class_block.dart';
import 'services/audio_service.dart';
import 'services/cloud_database_service.dart';
import 'services/esp32_sync_service.dart';
import 'widgets/notion_modals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartClockApp());
}

class SmartClockApp extends StatefulWidget {
  const SmartClockApp({super.key});

  @override
  State<SmartClockApp> createState() => _SmartClockAppState();
}

class _SmartClockAppState extends State<SmartClockApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _updateThemeMode(String themeName) {
    setState(() {
      if (themeName == 'Claro') {
        _themeMode = ThemeMode.light;
      } else if (themeName == 'Oscuro') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CTime - Smart Clock System',
      themeMode: _themeMode,
      theme: NotionTheme.lightTheme,
      darkTheme: NotionTheme.darkTheme,
      home: ClockShell(onThemeChanged: _updateThemeMode),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SmartClockApp();
}

// -----------------------------------------------------------------------------
// NOTION DESIGN SYSTEM TOKENS & THEMES
// -----------------------------------------------------------------------------
abstract class NotionColors {
  // Light Theme
  static const Color lightBg = Color(0xFFFBFBFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE9E9E7);
  static const Color lightTextPrimary = Color(0xFF37352F);
  static const Color lightTextSecondary = Color(0xFF787774);
  static const Color lightTextMuted = Color(0xFF9B9A97);
  static const Color lightAccent = Color(0xFF2E75D6);
  static const Color lightSubtleHighlight = Color(0xFFF2F1EE);

  // Dark Theme
  static const Color darkBg = Color(0xFF191919);
  static const Color darkSurface = Color(0xFF202020);
  static const Color darkBorder = Color(0xFF2F2F2F);
  static const Color darkTextPrimary = Color(0xFFF7F7F7);
  static const Color darkTextSecondary = Color(0xFF9B9A97);
  static const Color darkTextMuted = Color(0xFF6B6B6B);
  static const Color darkAccent = Color(0xFF478DFF);
  static const Color darkSubtleHighlight = Color(0xFF282828);
}

class NotionTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: NotionColors.lightBg,
      colorScheme: const ColorScheme.light(
        surface: NotionColors.lightSurface,
        primary: NotionColors.lightAccent,
        onSurface: NotionColors.lightTextPrimary,
        outline: NotionColors.lightBorder,
      ),
      useMaterial3: true,
      dividerColor: NotionColors.lightBorder,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: NotionColors.darkBg,
      colorScheme: const ColorScheme.dark(
        surface: NotionColors.darkSurface,
        primary: NotionColors.darkAccent,
        onSurface: NotionColors.darkTextPrimary,
        outline: NotionColors.darkBorder,
      ),
      useMaterial3: true,
      dividerColor: NotionColors.darkBorder,
    );
  }
}

enum AppScreen {
  home,
  horarios,
  temporizador,
  alarmas,
  configuracion,
}

// -----------------------------------------------------------------------------
// CLOCK SHELL (MAIN ROUTER & STATE CONTAINER CONNECTED TO SQLITE)
// -----------------------------------------------------------------------------
class ClockShell extends StatefulWidget {
  const ClockShell({super.key, required this.onThemeChanged});

  final ValueChanged<String> onThemeChanged;

  @override
  State<ClockShell> createState() => _ClockShellState();
}

class _ClockShellState extends State<ClockShell> {
  AppScreen _currentScreen = AppScreen.home;
  bool _isLoading = true;

  // DB States
  AppSettings _settings = AppSettings();
  List<AlarmItem> _alarms = [];
  List<PersonalEvent> _personalEvents = [];
  List<SchoolClassBlock> _schoolBlocks = [];
  List<CustomAudioTrack> _customAudioTracks = [];

  @override
  void initState() {
    super.initState();
    _loadAllDataFromCloud();
  }

  Future<void> _loadAllDataFromCloud() async {
    final cloud = CloudDatabaseService.instance;
    await cloud.syncWithCloud();

    setState(() {
      _settings = cloud.settings;
      _alarms = cloud.alarms;
      _personalEvents = cloud.personalEvents;
      _schoolBlocks = cloud.schoolClassBlocks;
      _customAudioTracks = cloud.customAudioTracks;
      _isLoading = false;
    });

    widget.onThemeChanged(_settings.themeMode);
  }

  void _navigateTo(AppScreen screen) {
    setState(() => _currentScreen = screen);
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    setState(() => _settings = newSettings);
    await CloudDatabaseService.instance.saveSettings(newSettings);
    widget.onThemeChanged(newSettings.themeMode);
  }

  // --- CRUD DISPATCHERS ---
  Future<void> _addOrUpdatePersonalEvent(PersonalEvent event) async {
    await CloudDatabaseService.instance.savePersonalEvent(event);
    await _loadAllDataFromCloud();
    Esp32SyncService.instance.pushLocalStateToClock();
  }

  Future<void> _deletePersonalEvent(String id) async {
    await CloudDatabaseService.instance.deletePersonalEvent(id);
    await _loadAllDataFromCloud();
    Esp32SyncService.instance.pushLocalStateToClock();
  }

  Future<void> _addOrUpdateSchoolBlock(SchoolClassBlock block) async {
    await CloudDatabaseService.instance.saveSchoolClassBlock(block);
    await _loadAllDataFromCloud();
    Esp32SyncService.instance.pushLocalStateToClock();
  }

  Future<void> _deleteSchoolBlock(String id) async {
    await CloudDatabaseService.instance.deleteSchoolClassBlock(id);
    await _loadAllDataFromCloud();
    Esp32SyncService.instance.pushLocalStateToClock();
  }

  Future<void> _addOrUpdateAlarm(AlarmItem alarm) async {
    await CloudDatabaseService.instance.saveAlarm(alarm);
    await _loadAllDataFromCloud();
    Esp32SyncService.instance.pushLocalStateToClock();
  }

  Future<void> _deleteAlarm(String id) async {
    await CloudDatabaseService.instance.deleteAlarm(id);
    await _loadAllDataFromCloud();
    Esp32SyncService.instance.pushLocalStateToClock();
  }

  Future<void> _pickAndSaveAudio() async {
    final track = await AudioService.instance.pickAndSaveCustomAudio();
    if (track != null) {
      await _loadAllDataFromCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio "${track.fileName}" sincronizado en Nube')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: _currentScreen == AppScreen.home,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentScreen != AppScreen.home) {
          setState(() => _currentScreen = AppScreen.home);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildCurrentPage(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentScreen) {
      case AppScreen.home:
        return HomeHubPage(
          key: const ValueKey('home'),
          personalEvents: _personalEvents,
          settings: _settings,
          onNavigate: _navigateTo,
        );
      case AppScreen.horarios:
        return SchedulePage(
          key: const ValueKey('horarios'),
          personalEvents: _personalEvents,
          schoolBlocks: _schoolBlocks,
          onSavePersonalEvent: _addOrUpdatePersonalEvent,
          onDeletePersonalEvent: _deletePersonalEvent,
          onSaveSchoolBlock: _addOrUpdateSchoolBlock,
          onDeleteSchoolBlock: _deleteSchoolBlock,
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.temporizador:
        return ClockControlPage(
          key: const ValueKey('temporizador'),
          isConnected: _settings.isConnected,
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.alarmas:
        return AlarmsPage(
          key: const ValueKey('alarmas'),
          alarms: _alarms,
          onSaveAlarm: _addOrUpdateAlarm,
          onDeleteAlarm: _deleteAlarm,
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.configuracion:
        return SettingsPage(
          key: const ValueKey('configuracion'),
          settings: _settings,
          customAudioTracks: _customAudioTracks,
          onUpdateSettings: _updateSettings,
          onUploadAudio: _pickAndSaveAudio,
          onBack: () => _navigateTo(AppScreen.home),
        );
    }
  }
}

// -----------------------------------------------------------------------------
// REUSABLE NOTION COMPONENTS
// -----------------------------------------------------------------------------
class NotionBlock extends StatelessWidget {
  const NotionBlock({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? NotionColors.darkSurface : NotionColors.lightSurface;
    final borderColor = isDark ? NotionColors.darkBorder : NotionColors.lightBorder;

    Widget content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      );
    }

    return content;
  }
}

class NotionHeader extends StatelessWidget {
  const NotionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.action,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18, color: secondaryText),
                    const SizedBox(width: 6),
                    Text(
                      'Inicio',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: primaryText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?action,
          ],
        ),
      ],
    );
  }
}

class NotionAddBlockCard extends StatelessWidget {
  const NotionAddBlockCard({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? NotionColors.darkBorder : NotionColors.lightBorder;
    final textColor = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotionSegmentedControl extends StatelessWidget {
  const NotionSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? NotionColors.darkSurface : NotionColors.lightSubtleHighlight;
    final borderColor = isDark ? NotionColors.darkBorder : NotionColors.lightBorder;
    final selectedBg = isDark ? NotionColors.darkSubtleHighlight : NotionColors.lightSurface;
    final selectedTextColor = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final unselectedTextColor = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected ? Border.all(color: borderColor, width: 0.8) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA: INICIO (HOME HUB)
// -----------------------------------------------------------------------------
class HomeHubPage extends StatefulWidget {
  const HomeHubPage({
    super.key,
    required this.personalEvents,
    required this.settings,
    required this.onNavigate,
  });

  final List<PersonalEvent> personalEvents;
  final AppSettings settings;
  final ValueChanged<AppScreen> onNavigate;

  @override
  State<HomeHubPage> createState() => _HomeHubPageState();
}

class _HomeHubPageState extends State<HomeHubPage> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;
    final accentColor = isDark ? NotionColors.darkAccent : NotionColors.lightAccent;

    final nextEvent = widget.personalEvents.isNotEmpty ? widget.personalEvents.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotionHeader(
            title: 'Inicio',
            subtitle: 'Centro de Control y Pilares',
            action: IconButton(
              onPressed: () => widget.onNavigate(AppScreen.configuracion),
              icon: const Icon(Icons.settings_outlined, size: 22),
              tooltip: 'Configuración',
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 20),

          // Clock Header Block
          NotionBlock(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Hora actual',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _timeLine(_now),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1.0,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLine(_now),
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'PILARES PRINCIPALES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 12),

          _HomePillarBlock(
            icon: Icons.calendar_today_outlined,
            title: 'Horarios',
            subtitle: 'Calendario personal y bloques de clases',
            onTap: () => widget.onNavigate(AppScreen.horarios),
          ),
          const SizedBox(height: 12),

          _HomePillarBlock(
            icon: Icons.timer_outlined,
            title: 'Temporizador',
            subtitle: 'Cronómetro sobrio y cuenta regresiva',
            onTap: () => widget.onNavigate(AppScreen.temporizador),
          ),
          const SizedBox(height: 12),

          _HomePillarBlock(
            icon: Icons.notifications_none_outlined,
            title: 'Alarmas',
            subtitle: 'Alertas y timbres automatizados',
            onTap: () => widget.onNavigate(AppScreen.alarmas),
          ),
          const SizedBox(height: 24),

          if (nextEvent != null) ...[
            Text(
              'PRÓXIMO EVENTO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            NotionBlock(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: nextEvent.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.event_outlined, size: 20, color: nextEvent.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextEvent.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nextEvent.time} • ${nextEvent.duration}',
                          style: TextStyle(fontSize: 13, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'En vista',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          ConnectionStrip(ip: widget.settings.esp32Ip, isConnected: widget.settings.isConnected),
        ],
      ),
    );
  }
}

class _HomePillarBlock extends StatelessWidget {
  const _HomePillarBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    return NotionBlock(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Row(
        children: [
          Icon(icon, size: 22, color: primaryText),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryText),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: secondaryText)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: secondaryText),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA: HORARIOS (SCHEDULE WITH DYNAMIC CALENDAR VIEWS)
// -----------------------------------------------------------------------------
class SchedulePage extends StatefulWidget {
  const SchedulePage({
    super.key,
    required this.personalEvents,
    required this.schoolBlocks,
    required this.onSavePersonalEvent,
    required this.onDeletePersonalEvent,
    required this.onSaveSchoolBlock,
    required this.onDeleteSchoolBlock,
    required this.onBack,
  });

  final List<PersonalEvent> personalEvents;
  final List<SchoolClassBlock> schoolBlocks;
  final Function(PersonalEvent) onSavePersonalEvent;
  final Function(String) onDeletePersonalEvent;
  final Function(SchoolClassBlock) onSaveSchoolBlock;
  final Function(String) onDeleteSchoolBlock;
  final VoidCallback onBack;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _modeIndex = 0; // 0: Personal, 1: Escolar
  int _personalViewIndex = 0; // 0: Diario, 1: Semanal, 2: Mensual
  int _schoolViewIndex = 0; // 0: Diario, 1: Semanal (Monthly is strictly prohibited)
  int _selectedDayIndex = 2; // Wed

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotionHeader(
            title: 'Horarios',
            subtitle: 'Gestión inteligente del tiempo',
            onBack: widget.onBack,
          ),
          const SizedBox(height: 20),

          // Main Segment: Personal vs Escolar
          NotionSegmentedControl(
            options: const ['Personal', 'Escolar'],
            selectedIndex: _modeIndex,
            onSelected: (idx) => setState(() => _modeIndex = idx),
          ),
          const SizedBox(height: 18),

          // Day Selector Strip
          DaySelectorStrip(
            selectedDay: _selectedDayIndex,
            onSelected: (day) => setState(() => _selectedDayIndex = day),
          ),
          const SizedBox(height: 20),

          if (_modeIndex == 0) ...[
            // --- PERSONAL MODE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HORARIO PERSONAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: secondaryText,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: NotionSegmentedControl(
                    options: const ['Diario', 'Semanal', 'Mensual'],
                    selectedIndex: _personalViewIndex,
                    onSelected: (idx) => setState(() => _personalViewIndex = idx),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPersonalViewContent(),
            const SizedBox(height: 14),
            NotionAddBlockCard(
              label: 'Añadir evento personal',
              onTap: () async {
                final result = await NotionModals.showAddEditPersonalEventModal(context);
                if (result != null) {
                  widget.onSavePersonalEvent(result);
                }
              },
            ),
          ] else ...[
            // --- ESCOLAR MODE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HORARIO ESCOLAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: secondaryText,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: NotionSegmentedControl(
                    options: const ['Diario', 'Semanal'], // STRICTLY NO MONTHLY VIEW
                    selectedIndex: _schoolViewIndex,
                    onSelected: (idx) => setState(() => _schoolViewIndex = idx),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSchoolViewContent(),
            const SizedBox(height: 14),
            NotionAddBlockCard(
              label: 'Añadir bloque de clase',
              onTap: () async {
                final result = await NotionModals.showAddEditSchoolBlockModal(context);
                if (result != null) {
                  widget.onSaveSchoolBlock(result);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalViewContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    if (_personalViewIndex == 0) {
      // Diario: Timeline View
      return Column(
        children: widget.personalEvents.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotionBlock(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(color: event.color, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText)),
                        if (event.description.isNotEmpty)
                          Text(event.description, style: TextStyle(fontSize: 12, color: secondaryText)),
                        Text('${event.time} • ${event.duration} • ${event.sound}', style: TextStyle(fontSize: 12, color: secondaryText)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () async {
                      final updated = await NotionModals.showAddEditPersonalEventModal(context, existingEvent: event);
                      if (updated != null) widget.onSavePersonalEvent(updated);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: () => widget.onDeletePersonalEvent(event.id),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else if (_personalViewIndex == 1) {
      // Semanal: 7-day Column Grid View
      return NotionBlock(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VISTA SEMANAL DE EVENTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secondaryText)),
            const SizedBox(height: 10),
            ...widget.personalEvents.map((event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: event.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('${event.time} - ${event.title}', style: TextStyle(fontSize: 13, color: primaryText)),
                    ],
                  ),
                )),
          ],
        ),
      );
    } else {
      // Mensual: Full Month Grid View
      return NotionBlock(
        child: Column(
          children: [
            Text('JULIO 2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryText)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 31,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (ctx, idx) {
                final day = idx + 1;
                final hasEvent = day % 3 == 0;
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282828) : const Color(0xFFF2F1EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: TextStyle(fontSize: 12, color: primaryText)),
                      if (hasEvent)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(color: Color(0xFF2E75D6), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSchoolViewContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    if (_schoolViewIndex == 0) {
      // Diario: Class Blocks for selected day
      final currentDayBlocks = widget.schoolBlocks
          .where((b) => b.dayOfWeek == (_selectedDayIndex + 1))
          .toList();

      if (currentDayBlocks.isEmpty) {
        return NotionBlock(
          child: Center(
            child: Text('Sin clases programadas para este día', style: TextStyle(fontSize: 13, color: secondaryText)),
          ),
        );
      }

      return Column(
        children: currentDayBlocks.map((block) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotionBlock(
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFF2E75D6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(block.subject, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText)),
                        Text('${block.startTime} AM • ${block.durationMinutes} min • ${block.sound}',
                            style: TextStyle(fontSize: 12, color: secondaryText)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () async {
                      final updated = await NotionModals.showAddEditSchoolBlockModal(context, existingBlock: block);
                      if (updated != null) widget.onSaveSchoolBlock(updated);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: () => widget.onDeleteSchoolBlock(block.id),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // Semanal: Mon-Fri Timetable Grid
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
      return NotionBlock(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HORARIO ESCOLAR (LUNES A VIERNES)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secondaryText)),
            const SizedBox(height: 12),
            Row(
              children: days
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryText)),
                        ),
                      ))
                  .toList(),
            ),
            const Divider(height: 16),
            ...widget.schoolBlocks.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${b.startTime} - ${b.subject}',
                    style: TextStyle(fontSize: 12, color: primaryText),
                  ),
                )),
          ],
        ),
      );
    }
  }
}

class DaySelectorStrip extends StatelessWidget {
  const DaySelectorStrip({
    super.key,
    required this.selectedDay,
    required this.onSelected,
  });

  final int selectedDay;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? NotionColors.darkBorder : NotionColors.lightBorder;
    final selectedBg = isDark ? NotionColors.darkAccent : NotionColors.lightAccent;
    final unselectedBg = isDark ? NotionColors.darkSurface : NotionColors.lightSurface;
    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedDay;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : unselectedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? selectedBg : borderColor, width: 1.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${23 + index}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : primaryText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA: TEMPORIZADOR (TIMER)
// -----------------------------------------------------------------------------
class ClockControlPage extends StatefulWidget {
  const ClockControlPage({
    super.key,
    required this.isConnected,
    required this.onBack,
  });

  final bool isConnected;
  final VoidCallback onBack;

  @override
  State<ClockControlPage> createState() => _ClockControlPageState();
}

class _ClockControlPageState extends State<ClockControlPage> {
  int _timerModeIndex = 0; // 0: Cronómetro, 1: Temporizador

  // Stopwatch State
  bool _stopwatchRunning = false;
  int _stopwatchElapsed = 0;
  Timer? _stopwatchTimer;

  // Countdown Timer State
  bool _countdownRunning = false;
  double _countdownMinutes = 25;
  int _countdownRemainingSeconds = 25 * 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownRemainingSeconds = (_countdownMinutes * 60).round();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkConnectionWarning(String modeName) {
    if (!widget.isConnected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Advertencia: El reloj no está conectado. El reloj no está sincronizando el $modeName.',
          ),
          backgroundColor: const Color(0xFFD9534F),
        ),
      );
    }
  }

  void _toggleStopwatch() {
    _checkConnectionWarning('cronómetro');
    setState(() => _stopwatchRunning = !_stopwatchRunning);
    _stopwatchTimer?.cancel();
    if (_stopwatchRunning) {
      _stopwatchTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _stopwatchElapsed++),
      );
    }
  }

  void _resetStopwatch() {
    _checkConnectionWarning('cronómetro');
    _stopwatchTimer?.cancel();
    setState(() {
      _stopwatchRunning = false;
      _stopwatchElapsed = 0;
    });
  }

  void _toggleCountdown() {
    _checkConnectionWarning('temporizador');
    setState(() => _countdownRunning = !_countdownRunning);
    _countdownTimer?.cancel();
    if (_countdownRunning) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (_countdownRemainingSeconds > 0) {
            setState(() => _countdownRemainingSeconds--);
          } else {
            _countdownTimer?.cancel();
            setState(() => _countdownRunning = false);
          }
        },
      );
    }
  }

  void _resetCountdown() {
    _checkConnectionWarning('temporizador');
    _countdownTimer?.cancel();
    setState(() {
      _countdownRunning = false;
      _countdownRemainingSeconds = (_countdownMinutes * 60).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;
    final accentColor = isDark ? NotionColors.darkAccent : NotionColors.lightAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotionHeader(
            title: 'Temporizador y Cronómetro',
            subtitle: 'Panel sobrio de control de tiempo',
            onBack: widget.onBack,
          ),
          const SizedBox(height: 20),

          // Segment Selector Tab between Cronómetro and Temporizador
          NotionSegmentedControl(
            options: const ['Cronómetro', 'Temporizador'],
            selectedIndex: _timerModeIndex,
            onSelected: (idx) => setState(() => _timerModeIndex = idx),
          ),
          const SizedBox(height: 16),

          // Disconnection Warning Banner
          if (!widget.isConnected)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF332010) : const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF664411) : const Color(0xFFFFE0B2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Advertencia: El reloj no está conectado. El reloj no está sincronizando el ${_timerModeIndex == 0 ? "cronómetro" : "temporizador"} en este momento.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFFFE0B2) : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_timerModeIndex == 0) ...[
            // CRONÓMETRO VIEW
            NotionBlock(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'CRONÓMETRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatSeconds(_stopwatchElapsed),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.0,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleStopwatch,
                          icon: Icon(
                            _stopwatchRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(_stopwatchRunning ? 'Detener' : 'Iniciar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetStopwatch,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('Reiniciar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryText,
                            side: BorderSide(
                              color: isDark ? NotionColors.darkBorder : NotionColors.lightBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // TEMPORIZADOR VIEW (COUNTDOWN)
            NotionBlock(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TEMPORIZADOR (CUENTA REGRESIVA)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _formatSeconds(_countdownRemainingSeconds),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1.0,
                        color: primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleCountdown,
                          icon: Icon(
                            _countdownRunning ? Icons.pause_rounded : Icons.hourglass_bottom_rounded,
                            size: 18,
                          ),
                          label: Text(_countdownRunning ? 'Detener' : 'Iniciar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetCountdown,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('Reiniciar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryText,
                            side: BorderSide(
                              color: isDark ? NotionColors.darkBorder : NotionColors.lightBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ajustar minutos: ${_countdownMinutes.round()} min',
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: isDark ? NotionColors.darkBorder : NotionColors.lightBorder,
                      thumbColor: accentColor,
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                    ),
                    child: Slider(
                      value: _countdownMinutes,
                      min: 1,
                      max: 120,
                      onChanged: (val) {
                        setState(() {
                          _countdownMinutes = val;
                          if (!_countdownRunning) {
                            _countdownRemainingSeconds = (_countdownMinutes * 60).round();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA: ALARMAS (ALARMS WITH SQLITE & MODALS)
// -----------------------------------------------------------------------------
class AlarmsPage extends StatefulWidget {
  const AlarmsPage({
    super.key,
    required this.alarms,
    required this.onSaveAlarm,
    required this.onDeleteAlarm,
    required this.onBack,
  });

  final List<AlarmItem> alarms;
  final Function(AlarmItem) onSaveAlarm;
  final Function(String) onDeleteAlarm;
  final VoidCallback onBack;

  @override
  State<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends State<AlarmsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotionHeader(
            title: 'Alarmas',
            subtitle: 'Sonidos, timbres y alertas programadas',
            onBack: widget.onBack,
          ),
          const SizedBox(height: 20),
          ...widget.alarms.map(
            (alarm) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NotionAlarmCard(
                alarm: alarm,
                onChanged: (val) {
                  alarm.enabled = val;
                  widget.onSaveAlarm(alarm);
                },
                onEdit: () async {
                  final updated = await NotionModals.showAddEditAlarmModal(context, existingAlarm: alarm);
                  if (updated != null) widget.onSaveAlarm(updated);
                },
                onDelete: () => widget.onDeleteAlarm(alarm.id),
              ),
            ),
          ),
          const SizedBox(height: 6),
          NotionAddBlockCard(
            label: 'Añadir alarma',
            onTap: () async {
              final result = await NotionModals.showAddEditAlarmModal(context);
              if (result != null) widget.onSaveAlarm(result);
            },
          ),
        ],
      ),
    );
  }
}

class NotionAlarmCard extends StatelessWidget {
  const NotionAlarmCard({
    super.key,
    required this.alarm,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final AlarmItem alarm;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;
    final accentColor = isDark ? NotionColors.darkAccent : NotionColors.lightAccent;

    return NotionBlock(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 20,
            color: alarm.enabled ? accentColor : secondaryText,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.time,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: alarm.enabled ? primaryText : secondaryText,
                  ),
                ),
                Text(
                  '${alarm.title} • ${alarm.sound}',
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: onDelete,
          ),
          Switch(
            value: alarm.enabled,
            activeThumbColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA: CONFIGURACIÓN (SETTINGS WITH AUDIO MANAGEMENT & ESP32 SYNC)
// -----------------------------------------------------------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.customAudioTracks,
    required this.onUpdateSettings,
    required this.onUploadAudio,
    required this.onBack,
  });

  final AppSettings settings;
  final List<CustomAudioTrack> customAudioTracks;
  final Function(AppSettings) onUpdateSettings;
  final VoidCallback onUploadAudio;
  final VoidCallback onBack;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSyncing = false;
  bool _isCheckingConnection = false;
  bool? _espConnected;
  bool _dfPlayerReady = false;
  String _connectionStatusMessage = 'Sin verificar';

  @override
  void initState() {
    super.initState();
    // Auto-check on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    final result = await Esp32SyncService.instance.checkRealConnection();
    if (mounted) {
      setState(() {
        _isCheckingConnection = false;
        _espConnected = result.isConnected;
        _dfPlayerReady = result.dfPlayerReady;
        _connectionStatusMessage = result.statusMessage;
      });
      // Propagate real connection status upward
      widget.settings.isConnected = result.isConnected;
      widget.onUpdateSettings(widget.settings);
    }
  }

  Future<void> _triggerEsp32Sync() async {
    setState(() => _isSyncing = true);
    final success = await Esp32SyncService.instance.pushLocalStateToClock();
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Sincronización con ESP32 exitosa'
                : 'No se pudo conectar con el ESP32 (${widget.settings.esp32Ip})',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final isDark = appTheme.brightness == Brightness.dark;

    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;
    final accentColor = isDark ? NotionColors.darkAccent : NotionColors.lightAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotionHeader(
            title: 'Configuración',
            subtitle: 'Preferencias del sistema y sincronización ESP32',
            onBack: widget.onBack,
          ),
          const SizedBox(height: 20),

          // Group 1: Dispositivo
          Text(
            'DISPOSITIVO & REPOSITORIO ESP32',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: secondaryText),
          ),
          const SizedBox(height: 10),
          DeviceCard(
            isConnected: _espConnected,
            dfPlayerReady: _dfPlayerReady,
            statusMessage: _connectionStatusMessage,
            isChecking: _isCheckingConnection,
            onVerify: _checkConnection,
          ),
          const SizedBox(height: 12),
          NotionBlock(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 18, color: secondaryText),
                    const SizedBox(width: 12),
                    Text('Brillo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryText)),
                    const Spacer(),
                    Text('${widget.settings.brightness.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryText)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: isDark ? NotionColors.darkBorder : NotionColors.lightBorder,
                    thumbColor: accentColor,
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  ),
                  child: Slider(
                    value: widget.settings.brightness,
                    min: 0,
                    max: 100,
                    onChanged: (val) {
                      widget.settings.brightness = val;
                      widget.onUpdateSettings(widget.settings);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Group 2: Audio Personalizado
          Text(
            'GESTIÓN DE AUDIO PERSONALIZADO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: secondaryText),
          ),
          const SizedBox(height: 10),
          NotionBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Audios Subidos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText)),
                    TextButton.icon(
                      onPressed: widget.onUploadAudio,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Cargar .mp3/.wav'),
                    ),
                  ],
                ),
                if (widget.customAudioTracks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No hay tonos personalizados cargados.', style: TextStyle(fontSize: 12, color: secondaryText)),
                  )
                else
                  ...widget.customAudioTracks.map((track) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.music_note_outlined, size: 16, color: Color(0xFF2E75D6)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(track.fileName, style: TextStyle(fontSize: 13, color: primaryText))),
                            Text(track.syncStatus, style: TextStyle(fontSize: 12, color: secondaryText)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Group 3: Apariencia
          Text(
            'APARIENCIA',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: secondaryText),
          ),
          const SizedBox(height: 10),
          NotionBlock(
            child: DropdownButtonFormField<String>(
              initialValue: widget.settings.themeMode,
              decoration: _notionInputDecoration('Tema visual', context),
              items: const ['Oscuro', 'Claro', 'Automático']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  widget.settings.themeMode = val;
                  widget.onUpdateSettings(widget.settings);
                }
              },
            ),
          ),
          const SizedBox(height: 22),

          // Group 4: Sincronización ESP32
          Text(
            'SINCRONIZACIÓN MOTOR ESP32',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: secondaryText),
          ),
          const SizedBox(height: 10),
          NotionBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_rounded, size: 20, color: secondaryText),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sincronizar Estado con Reloj ESP32', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText)),
                          Text('IP: ${widget.settings.esp32Ip}', style: TextStyle(fontSize: 12, color: secondaryText)),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: (_isSyncing || _espConnected != true) ? null : _triggerEsp32Sync,
                      style: FilledButton.styleFrom(backgroundColor: accentColor),
                      child: _isSyncing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Enviar a ESP32'),
                    ),
                  ],
                ),
                if (_espConnected == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF57C00)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reloj desconectado. Verifica la IP y que el ESP32 esté en la misma red Wi-Fi.',
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.isConnected,
    required this.dfPlayerReady,
    required this.statusMessage,
    required this.isChecking,
    required this.onVerify,
  });

  final bool? isConnected;
  final bool dfPlayerReady;
  final String statusMessage;
  final bool isChecking;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    Color dotColor;
    String dotLabel;
    if (isChecking || isConnected == null) {
      dotColor = const Color(0xFF9B9A97);
      dotLabel = 'Verificando conexión...';
    } else if (isConnected == true) {
      dotColor = const Color(0xFF16D676);
      dotLabel = statusMessage;
    } else {
      dotColor = const Color(0xFFD9534F);
      dotLabel = statusMessage;
    }

    return NotionBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_outlined, size: 22, color: primaryText),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP32 + DFPlayer Mini Smart Clock',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isChecking)
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dotLabel,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText),
                          ),
                        ),
                      ],
                    ),
                    if (isConnected == true && dfPlayerReady)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.music_note_rounded, size: 13, color: Color(0xFF16D676)),
                            const SizedBox(width: 6),
                            Text(
                              'DFPlayer Mini: Listo para reproducción MP3',
                              style: TextStyle(fontSize: 11, color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                    if (isConnected == true && !dfPlayerReady)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.music_off_rounded, size: 13, color: Color(0xFFF57C00)),
                            const SizedBox(width: 6),
                            Text(
                              'DFPlayer Mini: No detectado en ESP32',
                              style: TextStyle(fontSize: 11, color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: isChecking ? null : onVerify,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Verificar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryText,
                  side: BorderSide(
                    color: isDark ? NotionColors.darkBorder : NotionColors.lightBorder,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConnectionStrip extends StatelessWidget {
  const ConnectionStrip({super.key, required this.ip, required this.isConnected});

  final String ip;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? NotionColors.darkTextPrimary : NotionColors.lightTextPrimary;
    final secondaryText = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

    final dotColor = isConnected ? const Color(0xFF16D676) : const Color(0xFFD9534F);
    final label = isConnected ? 'ESP32 Conectado • IP $ip' : 'ESP32 Desconectado • IP $ip';

    return NotionBlock(
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 20,
            color: isConnected ? const Color(0xFF16D676) : const Color(0xFFD9534F),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'ESP32 Conectado' : 'ESP32 Desconectado',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontSize: 12, color: secondaryText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _notionInputDecoration(String label, BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final borderColor = isDark ? NotionColors.darkBorder : NotionColors.lightBorder;
  final labelColor = isDark ? NotionColors.darkTextSecondary : NotionColors.lightTextSecondary;

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: labelColor, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: borderColor, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: isDark ? NotionColors.darkAccent : NotionColors.lightAccent,
        width: 1.0,
      ),
    ),
  );
}

String _timeLine(DateTime date) {
  int hour = date.hour % 12;
  if (hour == 0) hour = 12;
  String two(int value) => value.toString().padLeft(2, '0');
  String period = date.hour >= 12 ? 'PM' : 'AM';
  return '${two(hour)}:${two(date.minute)}:${two(date.second)} $period';
}

String _dateLine(DateTime date) {
  const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];
  return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
}

String _formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(hours)}:${two(mins)}:${two(secs)}';
}
