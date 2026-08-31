import 'package:flutter/material.dart';
import '../models/alarm_item.dart';
import '../models/personal_event.dart';
import '../models/school_class_block.dart';
import '../services/audio_service.dart';

class NotionModals {
  static Future<PersonalEvent?> showAddEditPersonalEventModal(
    BuildContext context, {
    PersonalEvent? existingEvent,
  }) async {
    final titleController = TextEditingController(text: existingEvent?.title ?? '');
    final descController = TextEditingController(text: existingEvent?.description ?? '');
    final dateController = TextEditingController(
      text: existingEvent?.date ?? _formatDate(DateTime.now()),
    );
    String selectedTime = existingEvent?.time ?? '10:00 AM';
    final durationController = TextEditingController(text: existingEvent?.duration ?? '45 min');
    String selectedCategory = existingEvent?.category ?? 'Personal';
    String selectedSound = existingEvent?.sound ?? 'Timbre 1';

    List<String> soundOptions = await AudioService.instance.getAllAvailableSoundOptions();
    if (!soundOptions.contains(selectedSound)) {
      soundOptions.add(selectedSound);
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<PersonalEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202020) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border.all(
                  color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE9E9E7),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingEvent == null ? 'Añadir Evento Personal' : 'Editar Evento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF37352F),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: _notionModalInputDecoration('Título del evento', ctx),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: _notionModalInputDecoration('Descripción (Opcional)', ctx),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateController,
                            decoration: _notionModalInputDecoration('Fecha (AAAA-MM-DD)', ctx),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNotionTimePickerField(
                            ctx,
                            label: 'Hora inicio',
                            current12hTime: selectedTime,
                            onTimeSelected: (t) => selectedTime = t,
                            onStateUpdate: () => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            decoration: _notionModalInputDecoration('Duración (ej. 45 min)', ctx),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: _notionModalInputDecoration('Categoría', ctx),
                            items: const ['Personal', 'Clase', 'Rutina', 'Trabajo']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedCategory = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSound,
                      decoration: _notionModalInputDecoration('Sonido de notificación', ctx),
                      items: soundOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedSound = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty) return;
                            final event = PersonalEvent(
                              id: existingEvent?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              date: dateController.text.trim(),
                              time: selectedTime,
                              duration: durationController.text.trim(),
                              sound: selectedSound,
                              category: selectedCategory,
                              colorValue: _getColorForCategory(selectedCategory),
                            );
                            Navigator.pop(ctx, event);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E75D6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<SchoolClassBlock?> showAddEditSchoolBlockModal(
    BuildContext context, {
    SchoolClassBlock? existingBlock,
  }) async {
    final subjectController = TextEditingController(text: existingBlock?.subject ?? '');
    String selectedStartTime = existingBlock?.startTime ?? '08:00 AM';
    final durationController = TextEditingController(
      text: existingBlock?.durationMinutes.toString() ?? '45',
    );
    int selectedDay = existingBlock?.dayOfWeek ?? 1;
    String selectedSound = existingBlock?.sound ?? 'Timbre 1';

    List<String> soundOptions = await AudioService.instance.getAllAvailableSoundOptions();
    if (!soundOptions.contains(selectedSound)) {
      soundOptions.add(selectedSound);
    }

    if (!context.mounted) return null;

    const daysMap = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo',
    };

    return showModalBottomSheet<SchoolClassBlock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202020) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border.all(
                  color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE9E9E7),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingBlock == null ? 'Añadir Bloque de Clase' : 'Editar Bloque de Clase',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF37352F),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: _notionModalInputDecoration('Materia / Asignatura', ctx),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      decoration: _notionModalInputDecoration('Día de la semana', ctx),
                      items: daysMap.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedDay = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNotionTimePickerField(
                            ctx,
                            label: 'Hora inicio',
                            current12hTime: selectedStartTime,
                            onTimeSelected: (t) => selectedStartTime = t,
                            onStateUpdate: () => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: _notionModalInputDecoration('Duración (minutos)', ctx),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSound,
                      decoration: _notionModalInputDecoration('Timbre de inicio/fin', ctx),
                      items: soundOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedSound = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            if (subjectController.text.trim().isEmpty) return;
                            final block = SchoolClassBlock(
                              id: existingBlock?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              subject: subjectController.text.trim(),
                              dayOfWeek: selectedDay,
                              startTime: selectedStartTime,
                              durationMinutes: int.tryParse(durationController.text.trim()) ?? 45,
                              sound: selectedSound,
                            );
                            Navigator.pop(ctx, block);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E75D6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<AlarmItem?> showAddEditAlarmModal(
    BuildContext context, {
    AlarmItem? existingAlarm,
  }) async {
    String selectedTime = existingAlarm?.time ?? '07:00 AM';
    final titleController = TextEditingController(text: existingAlarm?.title ?? 'Alarma');
    String selectedSound = existingAlarm?.sound ?? 'Timbre 1';
    List<int> selectedDays = List.from(existingAlarm?.repeatDays ?? [1, 2, 3, 4, 5]);

    List<String> soundOptions = await AudioService.instance.getAllAvailableSoundOptions();
    if (!soundOptions.contains(selectedSound)) {
      soundOptions.add(selectedSound);
    }

    if (!context.mounted) return null;

    const dayLabels = {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'};

    return showModalBottomSheet<AlarmItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202020) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border.all(
                  color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE9E9E7),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingAlarm == null ? 'Añadir Alarma' : 'Editar Alarma',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF37352F),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNotionTimePickerField(
                      ctx,
                      label: 'Hora de la alarma',
                      current12hTime: selectedTime,
                      onTimeSelected: (t) => selectedTime = t,
                      onStateUpdate: () => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: _notionModalInputDecoration('Etiqueta / Nombre', ctx),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSound,
                      decoration: _notionModalInputDecoration('Tono de Alarma', ctx),
                      items: soundOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedSound = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'DÍAS DE REPETICIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: dayLabels.entries.map((entry) {
                        final isSelected = selectedDays.contains(entry.key);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedDays.remove(entry.key);
                              } else {
                                selectedDays.add(entry.key);
                              }
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2E75D6)
                                  : (isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF2F1EE)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            final alarm = AlarmItem(
                              id: existingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              time: selectedTime,
                              title: titleController.text.trim(),
                              sound: selectedSound,
                              enabled: existingAlarm?.enabled ?? true,
                              repeatDays: selectedDays,
                            );
                            Navigator.pop(ctx, alarm);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E75D6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TIME PICKER WIDGET & HELPERS ---
  static Widget _buildNotionTimePickerField(
    BuildContext context, {
    required String label,
    required String current12hTime,
    required ValueChanged<String> onTimeSelected,
    required VoidCallback onStateUpdate,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPm = current12hTime.toUpperCase().contains('PM');

    return InkWell(
      onTap: () async {
        final initialTime = _parseTimeOfDay(current12hTime);
        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (ctx, child) {
            return MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final formatted = _formatTimeOfDay12H(picked);
          onTimeSelected(formatted);
          onStateUpdate();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF9F9F8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE9E9E7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9B9A97) : const Color(0xFF787774),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  current12hTime.isEmpty ? 'Seleccionar hora' : current12hTime,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF37352F),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E75D6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPm ? 'PM' : 'AM',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E75D6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF9B9A97) : const Color(0xFF787774),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      bool isPm = clean.contains('PM');
      bool isAm = clean.contains('AM');
      final digits = clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      int h = int.parse(digits[0]);
      int m = int.parse(digits[1]);
      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 10, minute: 0);
    }
  }

  static String _formatTimeOfDay12H(TimeOfDay time) {
    final hourOfPeriod = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final periodStr = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourStr = hourOfPeriod.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $periodStr';
  }
}

InputDecoration _notionModalInputDecoration(String label, BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontSize: 13,
      color: isDark ? const Color(0xFF9B9A97) : const Color(0xFF787774),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFE9E9E7),
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFF2E75D6),
        width: 1.0,
      ),
    ),
  );
}

String _formatDate(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
}

int _getColorForCategory(String cat) {
  switch (cat) {
    case 'Clase':
      return 0xFF2E75D6;
    case 'Rutina':
      return 0xFF00A8FF;
    case 'Trabajo':
      return 0xFF8E5BFF;
    case 'Personal':
    default:
      return 0xFF16D676;
  }
}
