import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/utils/time_formatter.dart';

final _daysOfWeek = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

class DaySchedule {
  bool enabled;
  bool allDay;
  TimeOfDay? start;
  TimeOfDay? end;
  DaySchedule({this.enabled = false, this.allDay = true, this.start, this.end});
}

class StepSchedule extends StatefulWidget {
  final Map<String, String> strings;
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onChanged;
  const StepSchedule({
    super.key,
    required this.strings,
    required this.data,
    required this.onChanged,
  });

  @override
  State<StepSchedule> createState() => _StepScheduleState();
}

class _StepScheduleState extends State<StepSchedule> {
  late List<DaySchedule> _days;

  @override
  void initState() {
    super.initState();
    final raw = widget.data['availability'] as List? ?? [];
    final items = List<Map<String, dynamic>?>.filled(7, null);
    for (final item in raw) {
      if (item is Map) {
        final dow = item['day_of_week'] as int?;
        if (dow != null && dow >= 0 && dow < 7) {
          items[dow] = Map<String, dynamic>.from(item);
        }
      }
    }
    _days = List.generate(7, (i) {
      final providerDow = (i + 6) % 7;
      final d = items[providerDow];
      if (d == null) return DaySchedule();
      final start = d['start_time'] as String?;
      final end = d['end_time'] as String?;
      if (start == null || end == null) return DaySchedule(enabled: true, allDay: true);
      if (start == '00:00' && end == '23:59') return DaySchedule(enabled: true, allDay: true);
      final sp = start.split(':');
      final ep = end.split(':');
      return DaySchedule(
        enabled: true,
        allDay: false,
        start: TimeOfDay(hour: int.tryParse(sp[0]) ?? 9, minute: int.tryParse(sp[1]) ?? 0),
        end: TimeOfDay(hour: int.tryParse(ep[0]) ?? 17, minute: int.tryParse(ep[1]) ?? 0),
      );
    });
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    return TimeFormatter.formatTimeOfDay(t, Localizations.localeOf(context).languageCode);
  }

  void _emit() {
    final availability = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final day = _days[i];
      if (day.enabled) {
        final providerDow = (i + 6) % 7;
        if (day.allDay) {
          availability.add({
            'day': _daysOfWeek[i],
            'day_of_week': providerDow,
            'start_time': '00:00',
            'end_time': '23:59',
          });
        } else if (day.start != null && day.end != null) {
          availability.add({
            'day': _daysOfWeek[i],
            'day_of_week': providerDow,
            'start_time': '${day.start!.hour.toString().padLeft(2, '0')}:${day.start!.minute.toString().padLeft(2, '0')}',
            'end_time': '${day.end!.hour.toString().padLeft(2, '0')}:${day.end!.minute.toString().padLeft(2, '0')}',
          });
        }
      }
    }
    widget.onChanged({'availability': availability});
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final current = isStart ? _days[index].start : _days[index].end;
    final picked = await showTimePicker(
      context: Navigator.of(context).context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _days[index].start = picked;
        } else {
          _days[index].end = picked;
        }
        _emit();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final activeDays = _days.where((d) => d.enabled).length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(
          icon: Icons.schedule_outlined,
          title: s['schedule'] ?? 'Availability',
          subtitle: s['schedule_subtitle'] ?? 'When are you available?',
        ),
        SizedBox(height: AppSpacing.md),
        if (activeDays > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text('$activeDays ${'day(s) selected'}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.primary)),
          ),
        ...List.generate(7, (i) {
          final day = _days[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: day.enabled ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
                  width: day.enabled ? 1.5 : 1,
                ),
                boxShadow: day.enabled ? AppShadows.subtle : null,
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => setState(() { day.enabled = !day.enabled; _emit(); }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s[_daysOfWeek[i].toLowerCase()] ?? _daysOfWeek[i],
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: day.enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          if (day.enabled) ...[
                            _ToggleChip(
                              label: s[AppLocalization.all_day] ?? 'All day',
                              selected: day.allDay,
                              onTap: () => setState(() { day.allDay = true; _emit(); }),
                            ),
                            SizedBox(width: 6),
                            _ToggleChip(
                              label: s[AppLocalization.set_times] ?? 'Set times',
                              selected: !day.allDay,
                              onTap: () => setState(() { day.allDay = false; _emit(); }),
                            ),
                          ] else
                            Icon(Icons.add_circle_outline_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                  ),
                  if (day.enabled && !day.allDay)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                      child: Row(
                        children: [
                          _TimeBox(
                            label: _formatTime(day.start),
                            onTap: () => _pickTime(i, true),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            child: Icon(Icons.arrow_forward_rounded, size: 16, color: cs.primary.withValues(alpha: 0.5)),
                          ),
                          _TimeBox(
                            label: _formatTime(day.end),
                            onTap: () => _pickTime(i, false),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Days set to "All day" accept bookings anytime. Days with time limits only accept bookings within those hours. Leave a day off to stay unavailable.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: selected ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeBox({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: cs.onPrimary, size: 24),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ],
    );
  }
}
