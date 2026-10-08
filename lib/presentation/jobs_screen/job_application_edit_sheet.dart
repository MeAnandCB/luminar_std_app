import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/jobs_screen/job_apply_sheet.dart';
import 'package:luminar_std/repository/jobs/model/job_notification_model.dart';
import 'package:luminar_std/repository/jobs/service/jobs_service.dart';

/// Shows the edit sheet for an active application. Returns true when saved.
Future<bool> showJobApplicationEditSheet(
  BuildContext context, {
  required JobApplicationDetail application,
  required String jobTitle,
  required List<Color> gradient,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JobApplicationEditSheet(
      application: application,
      jobTitle: jobTitle,
      gradient: gradient,
    ),
  );
  return result ?? false;
}

class _JobApplicationEditSheet extends StatefulWidget {
  const _JobApplicationEditSheet({
    required this.application,
    required this.jobTitle,
    required this.gradient,
  });

  final JobApplicationDetail application;
  final String jobTitle;
  final List<Color> gradient;

  @override
  State<_JobApplicationEditSheet> createState() =>
      _JobApplicationEditSheetState();
}

class _JobApplicationEditSheetState extends State<_JobApplicationEditSheet> {
  final _service = JobsService();
  final Map<String, TextEditingController> _textAnswers = {};
  final Map<String, Set<String>> _selectAnswers = {};
  final Map<String, String?> _errors = {};

  String? _resumeUrl;
  String? _pickedFileName;
  String? _pickedPath;
  bool _isSaving = false;

  static bool _isSelect(JobCustomField f) =>
      f.fieldType == 'multi_select' || f.fieldType == 'single_select';

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    final saved = {for (final a in app.answers) a.fieldUid: a};
    final file = app.resumeFile;
    _resumeUrl = (file != null && file.isNotEmpty) ? file : app.resumeUrl;
    if (_resumeUrl != null && _resumeUrl!.isEmpty) _resumeUrl = null;

    for (final f in app.customFields) {
      final a = saved[f.uid];
      if (_isSelect(f)) {
        _selectAnswers[f.uid] = {
          if (a != null && a.valueJson.isNotEmpty)
            ...a.valueJson
          else if (a?.valueText != null && a!.valueText!.isNotEmpty)
            a.valueText!,
        };
      } else {
        _textAnswers[f.uid] = TextEditingController(text: a?.valueText ?? '')
          ..addListener(() {
            if (_errors.containsKey(f.uid)) {
              setState(() => _errors.remove(f.uid));
            }
          });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textAnswers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.path == null) return;
    setState(() {
      _pickedFileName = file.name;
      _pickedPath = file.path;
      _errors.remove('resume');
    });
  }

  bool _validate() {
    final next = <String, String?>{};
    if (_resumeUrl == null && _pickedPath == null) {
      next['resume'] = 'Please attach a resume.';
    }
    for (final f in widget.application.customFields) {
      if (!f.isRequired) continue;
      final empty = _isSelect(f)
          ? (_selectAnswers[f.uid]?.isEmpty ?? true)
          : (_textAnswers[f.uid]?.text.trim().isEmpty ?? true);
      if (empty) next[f.uid] = '${f.label} is required.';
    }
    setState(() => _errors
      ..clear()
      ..addAll(next));
    return next.isEmpty;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final answers = widget.application.customFields.map((f) {
      dynamic value;
      if (f.fieldType == 'multi_select') {
        value = (_selectAnswers[f.uid] ?? {}).toList();
      } else if (f.fieldType == 'single_select') {
        value = (_selectAnswers[f.uid] ?? {}).firstOrNull ?? '';
      } else {
        value = _textAnswers[f.uid]?.text.trim() ?? '';
      }
      return {'field_uid': f.uid, 'value': value};
    }).toList();

    final res = await _service.updateApplication(
      widget.application.applicationUid,
      resumePath: _pickedPath,
      answers: answers.isEmpty ? null : answers,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Failed to update application.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final fields = widget.application.customFields;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Application',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 100),
                children: [
                  const SizedBox(height: 16),
                  const SectionLabel(label: 'Resume *'),
                  const SizedBox(height: 12),
                  ResumeSection(
                    resumeUrl: _resumeUrl,
                    pickedFileName: _pickedFileName,
                    gradient: widget.gradient,
                    onPickFile: _pickFile,
                    errorText: _errors['resume'],
                    onClear: () => setState(() {
                      _pickedFileName = null;
                      _pickedPath = null;
                    }),
                  ),
                  if (fields.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionLabel(label: 'Application Questions'),
                    const SizedBox(height: 12),
                    ...fields.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CustomFieldInput(
                          field: f,
                          textController: _textAnswers[f.uid],
                          selected: _selectAnswers[f.uid] ?? {},
                          gradient: widget.gradient,
                          errorText: _errors[f.uid],
                          onSelectChanged: (val) => setState(() {
                            _selectAnswers[f.uid] = val;
                            _errors.remove(f.uid);
                          }),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.gradient.first,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
