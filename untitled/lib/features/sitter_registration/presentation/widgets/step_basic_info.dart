import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class StepBasicInfo extends StatefulWidget {
  final Map<String, String> strings;
  final Map<String, dynamic> data;
  final List<String> availableLanguages;
  final void Function(Map<String, dynamic>) onChanged;
  const StepBasicInfo({
    super.key,
    required this.strings,
    required this.data,
    required this.availableLanguages,
    required this.onChanged,
  });

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> {
  int _age = 25;
  int _yearsExp = 0;
  String _gender = '';
  List<String> _languages = [];
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  LocationPickerData? _locationData;

  @override
  void initState() {
    super.initState();
    _age = widget.data['age'] as int? ?? 25;
    _yearsExp = widget.data['years_experience'] as int? ?? 0;
    _gender = widget.data['gender'] as String? ?? '';
    _languages = List<String>.from(widget.data['languages'] as List? ?? []);
    _bioCtrl = TextEditingController(text: widget.data['bio'] as String? ?? '');
    _locationCtrl = TextEditingController(text: widget.data['location'] as String? ?? '');
    final lat = widget.data['latitude'] as double?;
    final lng = widget.data['longitude'] as double?;
    final locName = widget.data['location'] as String?;
    _locationData = LocationPickerData(latitude: lat, longitude: lng, locationName: locName);
    _locationCtrl.addListener(_emit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gender.isEmpty) {
        _bioCtrl.addListener(_emit);
      }
    });
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final loc = _locationData;
    widget.onChanged({
      'gender': _gender,
      'age': _age,
      'years_experience': _yearsExp,
      'languages': _languages,
      'bio': _bioCtrl.text.trim(),
      'latitude': loc?.latitude,
      'longitude': loc?.longitude,
      'location': _locationCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(
          icon: Icons.person_outline_rounded,
          title: s[AppLocalization.about_you] ?? 'About You',
          subtitle: s[AppLocalization.basic_info_subtitle] ?? 'Tell parents about yourself',
        ),
        SizedBox(height: AppSpacing.xl),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(s[AppLocalization.gender] ?? 'Gender'),
              SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'male',
                      label: Text('  ${s['male'] ?? 'Male'}'),
                      icon: Icon(Icons.male_rounded),
                    ),
                    ButtonSegment(
                      value: 'female',
                      label: Text('  ${s['female'] ?? 'Female'}'),
                      icon: Icon(Icons.female_rounded),
                    ),
                  ],
                  selected: _gender.isEmpty ? {} : {_gender},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (v) => setState(() { _gender = v.first; _emit(); }),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    selectedBackgroundColor: cs.primary.withValues(alpha: 0.12),
                    selectedForegroundColor: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    foregroundColor: cs.onSurface.withValues(alpha: 0.6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.cake_outlined, color: cs.primary),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _FieldLabel(s[AppLocalization.age_hint] ?? 'Age')),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('$_age', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Spacer(),
                  _RoundButton(
                    icon: Icons.remove_rounded,
                    onTap: _age > 18 ? () => setState(() { _age--; _emit(); }) : null,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _RoundButton(
                    icon: Icons.add_rounded,
                    onTap: _age < 100 ? () => setState(() { _age++; _emit(); }) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.work_outline, color: cs.primary),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _FieldLabel(s[AppLocalization.years_experience] ?? 'Years of Experience')),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('$_yearsExp ${s[AppLocalization.years_short] ?? 'years'}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Spacer(),
                  _RoundButton(
                    icon: Icons.remove_rounded,
                    onTap: _yearsExp > 0 ? () => setState(() { _yearsExp--; _emit(); }) : null,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _RoundButton(
                    icon: Icons.add_rounded,
                    onTap: _yearsExp < 70 ? () => setState(() { _yearsExp++; _emit(); }) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.translate_rounded, color: cs.primary),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _FieldLabel(s[AppLocalization.languages] ?? 'Languages')),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: widget.availableLanguages.map((lang) {
                  final selected = _languages.contains(lang);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _languages.remove(lang);
                        } else {
                          _languages.add(lang);
                        }
                        _emit();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (selected) ...[
                            SizedBox(width: 4),
                            Icon(Icons.check_rounded, size: 16, color: cs.primary),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.location_on_outlined, color: cs.primary),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _FieldLabel(s[AppLocalization.location] ?? 'Location')),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              LocationPicker(
                initial: _locationData,
                strings: widget.strings,
                onChanged: (data) {
                  setState(() => _locationData = data);
                  _emit();
                },
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  hintText: s[AppLocalization.location_hint] ?? 'Location Detail',
                  hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.edit_location_alt_rounded, size: 20, color: cs.primary.withValues(alpha: 0.6)),
                ),
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.edit_note_rounded, color: cs.primary),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _FieldLabel(s[AppLocalization.about_you] ?? 'About You')),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _bioCtrl,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: s[AppLocalization.bio_hint] ?? 'Describe your experience with children...',
                  hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35), height: 1.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.5),
                onChanged: (_) => _emit(),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface));
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: onTap != null ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: onTap != null ? cs.primary : cs.onSurface.withValues(alpha: 0.2)),
        ),
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
            boxShadow: [
              BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
            ],
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
