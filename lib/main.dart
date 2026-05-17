import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const SmartClockApp());

class SmartClockApp extends StatelessWidget {
  const SmartClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Clock System',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF081126),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B7FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ClockShell(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const SmartClockApp();
}

class ClockEvent {
  const ClockEvent({
    required this.name,
    required this.time,
    required this.duration,
    required this.sound,
    required this.color,
    this.category = 'Personal',
  });

  final String name;
  final String time;
  final String duration;
  final String sound;
  final Color color;
  final String category;
}

class ClockShell extends StatefulWidget {
  const ClockShell({super.key});

  @override
  State<ClockShell> createState() => _ClockShellState();
}

class _ClockShellState extends State<ClockShell> {
  int _selectedIndex = 0;

  final List<ClockEvent> _events = const [
    ClockEvent(
      name: 'Matematicas',
      time: '10:00',
      duration: '45 min',
      sound: 'Timbre 1',
      color: Color(0xFFD83FE7),
      category: 'Clase',
    ),
    ClockEvent(
      name: 'Trabajo',
      time: '12:00',
      duration: '60 min',
      sound: 'Timbre 2',
      color: Color(0xFF00A8FF),
      category: 'Rutina',
    ),
    ClockEvent(
      name: 'Gym',
      time: '18:00',
      duration: '90 min',
      sound: 'Timbre 3',
      color: Color(0xFF16D676),
      category: 'Personal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(events: _events, onOpenTab: _openTab),
      SchedulePage(events: _events),
      const ClockControlPage(),
      const AlarmsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: SmartBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: _openTab,
      ),
    );
  }

  void _openTab(int index) => setState(() => _selectedIndex = index);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.events,
    required this.onOpenTab,
  });

  final List<ClockEvent> events;
  final ValueChanged<int> onOpenTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
    final nextEvent = widget.events.first;

    return AppFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FuturisticCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GlowIcon(
                      icon: Icons.schedule,
                      color: Color(0xFF776CFF),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hora actual', style: smallLabel),
                        Text(_dateLine(_now), style: captionStrong),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _timeLine(_now),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(
                      child: StatusTile(
                        icon: Icons.bolt,
                        title: 'Estado',
                        value: 'Normal',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatusTile(
                        icon: Icons.thermostat,
                        title: 'Temperatura',
                        value: '24 C',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Acceso rapido', style: sectionTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              QuickAction(
                icon: Icons.calendar_month,
                label: 'Horario',
                onTap: () => widget.onOpenTab(1),
              ),
              const SizedBox(width: 10),
              QuickAction(
                icon: Icons.timer,
                label: 'Cronometro',
                onTap: () => widget.onOpenTab(2),
              ),
              const SizedBox(width: 10),
              QuickAction(
                icon: Icons.notifications_none,
                label: 'Alarmas',
                onTap: () => widget.onOpenTab(3),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FuturisticCard(
            child: Row(
              children: [
                GlowIcon(icon: Icons.event_available, color: nextEvent.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Proximo evento', style: cardTitle),
                      const SizedBox(height: 10),
                      Text(
                        nextEvent.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${nextEvent.time} AM - ${nextEvent.duration}',
                        style: mutedText,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('Inicia en', style: mutedTiny),
                    Text(
                      '1h 30m',
                      style: TextStyle(
                        color: Color(0xFF00C8FF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const ConnectionStrip(),
        ],
      ),
    );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.events});

  final List<ClockEvent> events;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _educationalMode = true;
  int _selectedDay = 2;

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderRow(
            title: 'Horario',
            subtitle: 'Gestiona tu tiempo inteligentemente',
            action: IconButton.filled(
              onPressed: () {},
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF00A8FF),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ModeSelector(
            educationalMode: _educationalMode,
            onChanged: (value) => setState(() => _educationalMode = value),
          ),
          const SizedBox(height: 18),
          DaySelector(
            selectedDay: _selectedDay,
            onSelected: (day) => setState(() => _selectedDay = day),
          ),
          const SizedBox(height: 18),
          if (_educationalMode) ...[
            Row(
              children: [
                Expanded(
                  child: ActionPill(icon: Icons.copy, label: 'Copiar dia'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionPill(
                    icon: Icons.calendar_view_week,
                    label: 'Duplicar semana',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Text(
            _educationalMode ? 'Bloques de hoy' : 'Eventos de hoy',
            style: sectionTitle,
          ),
          const SizedBox(height: 12),
          ...widget.events.map(
            (event) =>
                EventCard(event: event, educationalMode: _educationalMode),
          ),
        ],
      ),
    );
  }
}

class ClockControlPage extends StatefulWidget {
  const ClockControlPage({super.key});

  @override
  State<ClockControlPage> createState() => _ClockControlPageState();
}

class _ClockControlPageState extends State<ClockControlPage> {
  bool _running = false;
  int _elapsed = 0;
  double _countdownMinutes = 25;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderRow(
            title: 'Timer',
            subtitle: 'Panel inteligente del reloj',
          ),
          const SizedBox(height: 22),
          FuturisticCard(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const GlowIcon(
                  icon: Icons.timer,
                  color: Color(0xFF00C8FF),
                  size: 58,
                ),
                const SizedBox(height: 16),
                Text(
                  _formatSeconds(_elapsed),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryControlButton(
                        label: _running ? 'Detener' : 'Iniciar',
                        icon: _running ? Icons.pause : Icons.play_arrow,
                        onTap: _toggleStopwatch,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryControlButton(
                        label: 'Reiniciar',
                        icon: Icons.restart_alt,
                        onTap: _resetStopwatch,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FuturisticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cuenta regresiva', style: cardTitle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${_countdownMinutes.round()} min',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.hourglass_bottom),
                      label: const Text('Iniciar'),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00C8FF),
                    thumbColor: const Color(0xFF00C8FF),
                  ),
                  child: Slider(
                    value: _countdownMinutes,
                    min: 1,
                    max: 120,
                    onChanged: (value) =>
                        setState(() => _countdownMinutes = value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleStopwatch() {
    setState(() => _running = !_running);
    _timer?.cancel();
    if (_running) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _elapsed++),
      );
    }
  }

  void _resetStopwatch() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _elapsed = 0;
    });
  }
}

class AlarmsPage extends StatelessWidget {
  const AlarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          HeaderRow(
            title: 'Alarmas',
            subtitle: 'Sonidos, timbres y alertas automatizadas',
          ),
          SizedBox(height: 22),
          AlarmCard(
            time: '06:30',
            title: 'Inicio de jornada',
            sound: 'Timbre 1',
            enabled: true,
          ),
          AlarmCard(
            time: '10:45',
            title: 'Cambio de clase',
            sound: 'Campana corta',
            enabled: true,
          ),
          AlarmCard(
            time: '19:00',
            title: 'Rutina nocturna',
            sound: 'Suave digital',
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _brightness = 75;
  bool _automatic = true;
  String _theme = 'Oscuro';
  String _sound = 'Timbre 1';

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderRow(
            title: 'Configuracion',
            subtitle: 'Smart Clock System',
          ),
          const SizedBox(height: 18),
          const DeviceCard(),
          const SizedBox(height: 20),
          Text('Apariencia', style: sectionTitle),
          const SizedBox(height: 10),
          FuturisticCard(
            child: DropdownButtonFormField<String>(
              initialValue: _theme,
              dropdownColor: const Color(0xFF17243A),
              decoration: inputDecoration('Tema'),
              items: const ['Oscuro', 'Claro', 'Automatico']
                  .map(
                    (theme) =>
                        DropdownMenuItem(value: theme, child: Text(theme)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _theme = value ?? _theme),
            ),
          ),
          const SizedBox(height: 16),
          Text('Dispositivo', style: sectionTitle),
          const SizedBox(height: 10),
          FuturisticCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.wb_sunny_outlined,
                  color: const Color(0xFFFF9F0A),
                  title: 'Brillo',
                  value: '${_brightness.round()}%',
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF9F0A),
                    thumbColor: const Color(0xFFFF9F0A),
                  ),
                  child: Slider(
                    value: _brightness,
                    min: 0,
                    max: 100,
                    onChanged: (value) => setState(() => _brightness = value),
                  ),
                ),
                const Divider(color: Color(0xFF263B58)),
                const SettingsRow(
                  icon: Icons.battery_5_bar,
                  color: Color(0xFF16D676),
                  title: 'Bateria',
                  value: '86%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Sonidos', style: sectionTitle),
          const SizedBox(height: 10),
          FuturisticCard(
            child: DropdownButtonFormField<String>(
              initialValue: _sound,
              dropdownColor: const Color(0xFF17243A),
              decoration: inputDecoration('Sonido predeterminado'),
              items:
                  const [
                        'Timbre 1',
                        'Timbre 2',
                        'Campana corta',
                        'Suave digital',
                      ]
                      .map(
                        (sound) =>
                            DropdownMenuItem(value: sound, child: Text(sound)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _sound = value ?? _sound),
            ),
          ),
          const SizedBox(height: 16),
          Text('Automatizacion', style: sectionTitle),
          const SizedBox(height: 10),
          FuturisticCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const GlowIcon(
                icon: Icons.smartphone,
                color: Color(0xFF00A8FF),
                size: 42,
              ),
              title: const Text('Modo automatico', style: cardTitle),
              subtitle: const Text(
                'Ejecutar horario sin intervencion',
                style: mutedText,
              ),
              value: _automatic,
              activeThumbColor: const Color(0xFF00B7FF),
              onChanged: (value) => setState(() => _automatic = value),
            ),
          ),
          const SizedBox(height: 16),
          Text('Conexion', style: sectionTitle),
          const SizedBox(height: 10),
          const ConnectionStrip(),
        ],
      ),
    );
  }
}

class SmartBottomNav extends StatelessWidget {
  const SmartBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Inicio'),
      (Icons.calendar_month_outlined, 'Horario'),
      (Icons.timer_outlined, 'Timer'),
      (Icons.notifications_none, 'Alarmas'),
      (Icons.settings_outlined, 'Ajustes'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B152A),
        border: Border(top: BorderSide(color: Color(0xFF1B2B46))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedIndex == i
                          ? const Color(0xFF073E66)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selectedIndex == i
                          ? Border.all(color: const Color(0xFF00B7FF))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].$1,
                          size: 20,
                          color: selectedIndex == i
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFF6F829B),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          child: Text(
                            items[i].$2,
                            style: TextStyle(
                              fontSize: 11,
                              color: selectedIndex == i
                                  ? const Color(0xFF00D4FF)
                                  : const Color(0xFF6F829B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF09132A), Color(0xFF071023)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: child,
      ),
    );
  }
}

class FuturisticCard extends StatelessWidget {
  const FuturisticCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121E34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263B58)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3300A8FF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: mutedText),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class GlowIcon extends StatelessWidget {
  const GlowIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18263D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF00D4FF)),
              const SizedBox(width: 6),
              Text(title, style: mutedTiny),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 94,
          decoration: BoxDecoration(
            color: const Color(0xFF121E34),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF263B58)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 10),
              FittedBox(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.educationalMode,
    required this.onChanged,
  });

  final bool educationalMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF101B2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF263B58)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentButton(
              label: 'Personal',
              selected: !educationalMode,
              color: const Color(0xFF16D676),
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: SegmentButton(
              label: 'Educativo',
              selected: educationalMode,
              color: const Color(0xFF00A8FF),
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class SegmentButton extends StatelessWidget {
  const SegmentButton({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : const Color(0xFF8FA5C1),
          ),
        ),
      ),
    );
  }
}

class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onSelected,
  });

  final int selectedDay;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const names = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = index == selectedDay;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 58,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00A8FF)
                    : const Color(0xFF121E34),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF29D6FF)
                      : const Color(0xFF263B58),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    names[index],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${23 + index}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
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

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.educationalMode,
  });

  final ClockEvent event;
  final bool educationalMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FuturisticCard(
        child: Row(
          children: [
            GlowIcon(
              icon: educationalMode ? Icons.menu_book : Icons.schedule,
              color: event.color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(event.time, style: mutedText),
                      Text(event.duration, style: mutedText),
                      Text(event.sound, style: mutedText),
                      Text(event.category, style: mutedText),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF20314C),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFFF5E78),
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF20314C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  const ActionPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: FittedBox(child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFBFD7F4),
        side: const BorderSide(color: Color(0xFF263B58)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      child: Row(
        children: [
          const GlowIcon(icon: Icons.phone_iphone, color: Color(0xFF8E5BFF)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Arduino + ESP8266', style: cardTitle),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF16D676)),
                  SizedBox(width: 6),
                  Text(
                    'En linea',
                    style: TextStyle(
                      color: Color(0xFF16D676),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlowIcon(icon: icon, color: color, size: 42),
        const SizedBox(width: 14),
        Text(title, style: cardTitle),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class ConnectionStrip extends StatelessWidget {
  const ConnectionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      child: Row(
        children: [
          const GlowIcon(
            icon: Icons.wifi_tethering,
            color: Color(0xFF16D676),
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('ESP8266 conectado', style: cardTitle),
                SizedBox(height: 4),
                Text('IP 192.168.1.44 - sincronizado', style: mutedText),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Reconectar')),
        ],
      ),
    );
  }
}

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.time,
    required this.title,
    required this.sound,
    required this.enabled,
  });

  final String time;
  final String title;
  final String sound;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FuturisticCard(
        child: Row(
          children: [
            const GlowIcon(
              icon: Icons.notifications_active_outlined,
              color: Color(0xFF00A8FF),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(sound, style: mutedText),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: const Color(0xFF00B7FF),
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryControlButton extends StatelessWidget {
  const PrimaryControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: FittedBox(child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF00A8FF),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class SecondaryControlButton extends StatelessWidget {
  const SecondaryControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: FittedBox(child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFF365174)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

InputDecoration inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF9DB4D0)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF365174)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00B7FF)),
    ),
  );
}

String _timeLine(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
}

String _dateLine(DateTime date) {
  const days = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];
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
    'Diciembre',
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

const sectionTitle = TextStyle(
  color: Color(0xFF98C8FF),
  fontSize: 14,
  fontWeight: FontWeight.w800,
);
const cardTitle = TextStyle(fontWeight: FontWeight.w900, fontSize: 16);
const smallLabel = TextStyle(color: Color(0xFFB8CAE0), fontSize: 12);
const captionStrong = TextStyle(fontSize: 12, fontWeight: FontWeight.w800);
const mutedText = TextStyle(color: Color(0xFF9DB4D0), fontSize: 13);
const mutedTiny = TextStyle(color: Color(0xFF8FA5C1), fontSize: 11);
