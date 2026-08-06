import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';

class StepExperience extends StatefulWidget {
  final Map<String, String> strings;
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onChanged;
  final Future<String?> Function(String fileName) onUploadFile;

  const StepExperience({
    super.key,
    required this.strings,
    required this.data,
    required this.onChanged,
    required this.onUploadFile,
  });

  @override
  State<StepExperience> createState() => _StepExperienceState();
}

class _StepExperienceState extends State<StepExperience> {
  final _descriptionCtrl = TextEditingController();
  final _certNameCtrl = TextEditingController();
  List<Map<String, dynamic>> _certificatesList = [];

  String? _selectedFileName;
  String? _selectedFileUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl.text = (widget.data['description'] as String?) ?? '';
    _certificatesList = _parseCertificates();
  }

  @override
  void didUpdateWidget(StepExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _certificatesList = _parseCertificates();
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _certNameCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseCertificates() {
    final raw = widget.data['certificates'];
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        if (e is String) return <String, dynamic>{'name': e};
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  void _emit() {
    widget.onChanged({
      'description': _descriptionCtrl.text.trim(),
      'certificates': _certificatesList,
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _isUploading = true;
    });

    final url = await widget.onUploadFile(file.name);
    setState(() {
      _isUploading = false;
      if (url != null) {
        _selectedFileName = file.name;
        _selectedFileUrl = url;
      } else {
        context.showErrorSnackBar(widget.strings[AppLocalization.upload_failed] ?? 'Upload failed. Try again.');
      }
    });
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFileUrl = null;
    });
  }

  void _addCertificate() {
    final name = _certNameCtrl.text.trim();
    if (name.isEmpty) return;

    final entry = <String, dynamic>{'name': name};
    if (_selectedFileUrl != null) {
      entry['file_url'] = _selectedFileUrl;
      entry['file_name'] = _selectedFileName ?? '';
    }
    setState(() {
      _certificatesList.add(entry);
    });
    _certNameCtrl.clear();
    _clearSelectedFile();
    _emit();
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificatesList.removeAt(index);
    });
    _emit();
  }

  void _replaceCertificateDoc(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final url = await widget.onUploadFile(file.name);
    if (url == null) return;

    setState(() {
      _certificatesList[index]['file_url'] = url;
      _certificatesList[index]['file_name'] = file.name;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final certs = _certificatesList;
    final canAdd = _certNameCtrl.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(
          icon: Icons.auto_stories_outlined,
          title: s['experience_certificates'] ?? 'Experience & Certificates',
          subtitle: s['exp_cert_subtitle'] ?? 'Show parents why they should trust you',
        ),
        const SizedBox(height: AppSpacing.xl),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.add_circle_outline_rounded, color: cs.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    s['add_certificate'] ?? 'Add Certificate',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _certNameCtrl,
                decoration: InputDecoration(
                  hintText: s['certificate_hint'] ?? 'e.g. First Aid Certified',
                  hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _certNameCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _certNameCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: _isUploading
                          ? SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                            )
                          : Icon(
                              _selectedFileName != null
                                  ? Icons.description_rounded
                                  : Icons.upload_file_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _selectedFileName != null
                            ? _selectedFileName!.length > 20
                                ? '${_selectedFileName!.substring(0, 18)}...'
                                : _selectedFileName!
                            : s['upload_document'] ?? 'Upload Document',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedFileName != null ? Colors.green.shade700 : null,
                        side: BorderSide(
                          color: _selectedFileName != null ? Colors.green.shade400 : cs.outline,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                    ),
                  ),
                  if (_selectedFileName != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: _clearSelectedFile,
                      icon: Icon(Icons.close_rounded, size: 18, color: cs.error),
                      tooltip: s['remove_file'] ?? 'Remove file',
                    ),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 100,
                    child: FilledButton(
                      onPressed: canAdd ? _addCertificate : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: Text(s['add'] ?? 'Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (certs.isNotEmpty)
          ...certs.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _CertificateCard(
              index: entry.key,
              entry: entry.value,
              onRemove: () => _removeCertificate(entry.key),
              onChangeDoc: () => _replaceCertificateDoc(entry.key),
              cs: cs,
              s: s,
            ),
          )),

        if (certs.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.auto_stories_outlined, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s['no_certificates_added'] ?? 'No certificates added yet',
                    style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.xl),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.edit_note_rounded, color: cs.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    s['description'] ?? 'Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: s['description_hint'] ?? 'Tell parents about your experience, skills, and approach to childcare...',
                  hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35)),
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
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> entry;
  final VoidCallback onRemove;
  final VoidCallback onChangeDoc;
  final ColorScheme cs;
  final Map<String, String> s;

  const _CertificateCard({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChangeDoc,
    required this.cs,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['name'] as String? ?? '';
    final fileName = entry['file_name'] as String? ?? '';
    final fileUrl = entry['file_url'] as String?;
    final hasDoc = fileUrl != null && fileUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(Icons.auto_stories_rounded, size: 18, color: cs.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                if (hasDoc)
                  InkWell(
                    onTap: onChangeDoc,
                    child: Row(
                      children: [
                        Icon(Icons.description_rounded, size: 13, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            fileName.isNotEmpty ? fileName : 'Document attached',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade600, decoration: TextDecoration.underline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: onChangeDoc,
                    child: Row(
                      children: [
                        Icon(Icons.upload_file_rounded, size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Text(
                          s['add_document'] ?? 'Add document',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4), decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: cs.error.withValues(alpha: 0.7)),
            ),
          ),
        ],
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
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ],
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
