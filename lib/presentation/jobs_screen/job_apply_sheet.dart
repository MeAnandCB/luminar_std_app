import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/repository/jobs/model/job_notification_model.dart';
import 'package:luminar_std/repository/jobs/service/jobs_service.dart';

Future<bool> showJobApplySheet(
  BuildContext context, {
  required JobDetail jobDetail,
  required JobNotification notification,
  required List<Color> gradient,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JobApplySheet(
      jobDetail: jobDetail,
      notification: notification,
      gradient: gradient,
    ),
  );
  return result ?? false;
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _JobApplySheet extends StatefulWidget {
  const _JobApplySheet({
    required this.jobDetail,
    required this.notification,
    required this.gradient,
  });

  final JobDetail jobDetail;
  final JobNotification notification;
  final List<Color> gradient;

  @override
  State<_JobApplySheet> createState() => _JobApplySheetState();
}

class _JobApplySheetState extends State<_JobApplySheet> {
  final _service = JobsService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final Map<String, TextEditingController> _textAnswers = {};
  final Map<String, Set<String>> _selectAnswers = {};

  String? _resumeUrl;
  String? _pickedFileName;
  String? _pickedBase64;

  bool _loadingProfile = true;
  bool _isSubmitting = false;

  // Per-field error messages — keyed by 'email','phone','resume', or field uid
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    for (final f in widget.jobDetail.customFields) {
      if (f.fieldType == 'multi_select' || f.fieldType == 'single_select') {
        _selectAnswers[f.uid] = {};
      } else {
        final ctrl = TextEditingController();
        ctrl.addListener(() => _clearError(f.uid));
        _textAnswers[f.uid] = ctrl;
      }
    }
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _textAnswers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      // Share the cached fetch instead of hitting the profile endpoint
      // again — most of the time this sheet opens right after the profile
      // screen or home dashboard has already loaded it.
      final profileController = context.read<ProfileController>();
      if (profileController.profileData == null) {
        await profileController.getProfileData(context: context);
      }
      final p = profileController.profileData?.personalInfo;
      if (p != null) {
        _nameCtrl.text = p.fullName ?? '';
        _emailCtrl.text = p.email ?? '';
        _phoneCtrl.text = p.phone ?? '';
        final raw = p.resume;
        if (raw != null && raw.toString().isNotEmpty) {
          _resumeUrl = raw.toString();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    final bytes = await File(file.path!).readAsBytes();
    setState(() {
      _pickedFileName = file.name;
      _pickedBase64 = base64Encode(bytes);
      _resumeUrl = null;
      _errors.remove('resume');
    });
  }

  bool _hasResume() => _resumeUrl != null || _pickedBase64 != null;

  /// Validates all fields, populates [_errors], returns true if valid.
  bool _validate() {
    final next = <String, String?>{};
    if (_emailCtrl.text.trim().isEmpty) next['email'] = 'Email is required.';
    if (_phoneCtrl.text.trim().isEmpty) next['phone'] = 'Phone number is required.';
    if (!_hasResume()) next['resume'] = 'Please attach a resume.';
    for (final f in widget.jobDetail.customFields) {
      if (!f.isRequired) continue;
      if (f.fieldType == 'multi_select' || f.fieldType == 'single_select') {
        if (_selectAnswers[f.uid]?.isEmpty ?? true) {
          next[f.uid] = '${f.label} is required.';
        }
      } else {
        if (_textAnswers[f.uid]?.text.trim().isEmpty ?? true) {
          next[f.uid] = '${f.label} is required.';
        }
      }
    }
    setState(() => _errors
      ..clear()
      ..addAll(next));
    return next.isEmpty;
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  void _showConfirmation() {
    if (!_validate()) return;

    final answers = widget.jobDetail.customFields.map((f) {
      dynamic val;
      if (f.fieldType == 'multi_select' || f.fieldType == 'single_select') {
        val = (_selectAnswers[f.uid] ?? {}).join(', ');
      } else {
        val = _textAnswers[f.uid]?.text.trim() ?? '';
      }
      return {'label': f.label, 'value': val.toString()};
    }).where((e) => e['value']!.isNotEmpty).toList();

    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        resumeLabel: _pickedFileName ??
            (_resumeUrl != null
                ? _resumeUrl!.split('/').last.split('?').first
                : ''),
        answers: answers,
        gradient: widget.gradient,
        onConfirm: _submit,
      ),
    );
  }

  Future<void> _submit() async {
    Navigator.pop(context); // close dialog
    setState(() => _isSubmitting = true);

    final apiAnswers = widget.jobDetail.customFields.map((f) {
      dynamic val;
      if (f.fieldType == 'multi_select' || f.fieldType == 'single_select') {
        val = (_selectAnswers[f.uid] ?? {}).toList();
      } else {
        val = _textAnswers[f.uid]?.text.trim() ?? '';
      }
      return {'field_uid': f.uid, 'value': val};
    }).toList();

    final res = await _service.applyForJob(
      widget.jobDetail.uid,
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      resumeUrl: _resumeUrl,
      resumeBase64: _pickedBase64,
      resumeFilename: _pickedFileName,
      answers: apiAnswers,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Failed to submit application.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
            // ── drag handle ───────────────────────────────────────────────
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── header ────────────────────────────────────────────────────
            _SheetHeader(
              jobTitle: widget.notification.jobTitle,
              companyName: widget.notification.companyName,
              logoUrl: widget.jobDetail.company.logo,
              gradient: widget.gradient,
            ),

            // ── body ──────────────────────────────────────────────────────
            Expanded(
              child: _loadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 100),
                      children: [
                        const SizedBox(height: 16),
                        _SectionLabel(label: 'Personal Information'),
                        const SizedBox(height: 12),
                        _ApplyField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_rounded,
                          gradient: widget.gradient,
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        _ApplyField(
                          controller: _emailCtrl,
                          label: 'Email *',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          gradient: widget.gradient,
                          readOnly: true,
                          errorText: _errors['email'],
                        ),
                        const SizedBox(height: 12),
                        _ApplyField(
                          controller: _phoneCtrl,
                          label: 'Phone *',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          gradient: widget.gradient,
                          readOnly: true,
                          errorText: _errors['phone'],
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(label: 'Resume *'),
                        const SizedBox(height: 12),
                        _ResumeSection(
                          resumeUrl: _resumeUrl,
                          pickedFileName: _pickedFileName,
                          gradient: widget.gradient,
                          onPickFile: _pickFile,
                          errorText: _errors['resume'],
                          onClear: () => setState(() {
                            _pickedFileName = null;
                            _pickedBase64 = null;
                          }),
                        ),
                        if (widget.jobDetail.customFields.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionLabel(label: 'Application Questions'),
                          const SizedBox(height: 12),
                          ...widget.jobDetail.customFields.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CustomFieldInput(
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

            // ── sticky footer ─────────────────────────────────────────────
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient[0].withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _showConfirmation,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Review & Apply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

// ─── Sheet header ─────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.jobTitle,
    required this.companyName,
    required this.gradient,
    this.logoUrl,
  });

  final String jobTitle;
  final String companyName;
  final List<Color> gradient;
  final String? logoUrl;

  String _initials() {
    final parts = companyName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _avatar() {
    final url = logoUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsBox(),
          ),
        ),
      );
    }
    return _initialsBox();
  }

  Widget _initialsBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _initials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apply for Position',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jobTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  companyName,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Apply field ──────────────────────────────────────────────────────────────

class _ApplyField extends StatelessWidget {
  const _ApplyField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.gradient,
    this.keyboardType,
    this.readOnly = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final TextInputType? keyboardType;
  final bool readOnly;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: hasError ? Colors.red.shade600 : AppColors.textSecondary,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: hasError
                  ? Colors.red.shade400
                  : readOnly
                      ? AppColors.textSecondary
                      : gradient[0],
            ),
            suffixIcon: readOnly
                ? const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey)
                : hasError
                    ? Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade400)
                    : null,
            filled: true,
            fillColor: hasError
                ? Colors.red.withValues(alpha: 0.04)
                : readOnly
                    ? AppColors.surface
                    : AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red.shade400
                    : AppColors.borderColor.withValues(alpha: readOnly ? 0.3 : 0.5),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade400 : readOnly ? AppColors.borderColor : gradient[0],
                width: readOnly ? 1.0 : 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 12, color: Colors.red.shade600),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: TextStyle(fontSize: 11, color: Colors.red.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Resume section ───────────────────────────────────────────────────────────

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({
    required this.resumeUrl,
    required this.pickedFileName,
    required this.gradient,
    required this.onPickFile,
    required this.onClear,
    this.errorText,
  });

  final String? resumeUrl;
  final String? pickedFileName;
  final List<Color> gradient;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final String? errorText;

  String get _displayName {
    if (pickedFileName != null) return pickedFileName!;
    if (resumeUrl != null) {
      return resumeUrl!.split('/').last.split('?').first;
    }
    return '';
  }

  bool get _hasFile => resumeUrl != null || pickedFileName != null;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    Widget card;
    if (_hasFile) {
      card = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: gradient[0].withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gradient[0].withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradient[0].withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description_rounded, color: gradient[0], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName.isEmpty ? 'Resume attached' : _displayName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pickedFileName != null ? 'Newly uploaded' : 'From your profile',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onPickFile,
              style: TextButton.styleFrom(
                foregroundColor: gradient[0],
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      card = GestureDetector(
        onTap: onPickFile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: hasError ? Colors.red.withValues(alpha: 0.04) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : AppColors.borderColor.withValues(alpha: 0.5),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file_rounded, color: hasError ? Colors.red.shade400 : gradient[0], size: 32),
              const SizedBox(height: 8),
              Text(
                'Upload Resume',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasError ? Colors.red.shade600 : gradient[0],
                ),
              ),
              const SizedBox(height: 4),
              Text('PDF, DOC or DOCX', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card,
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 12, color: Colors.red.shade600),
              const SizedBox(width: 4),
              Text(errorText!, style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Custom field input ───────────────────────────────────────────────────────

class _CustomFieldInput extends StatelessWidget {
  const _CustomFieldInput({
    required this.field,
    required this.textController,
    required this.selected,
    required this.gradient,
    required this.onSelectChanged,
    this.errorText,
  });

  final JobCustomField field;
  final TextEditingController? textController;
  final Set<String> selected;
  final List<Color> gradient;
  final ValueChanged<Set<String>> onSelectChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isSelect = field.fieldType == 'multi_select' || field.fieldType == 'single_select';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ────────────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              field.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasError ? Colors.red.shade700 : AppColors.textPrimary,
              ),
            ),
            if (field.isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: hasError ? Colors.red.shade600 : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Input ────────────────────────────────────────────────────────────
        if (isSelect)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: field.options.map((opt) {
              final isOn = selected.contains(opt);
              return GestureDetector(
                onTap: () {
                  final next = Set<String>.from(selected);
                  if (field.fieldType == 'single_select') {
                    next.clear();
                    if (!isOn) next.add(opt);
                  } else {
                    if (isOn) next.remove(opt);
                    else next.add(opt);
                  }
                  onSelectChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isOn ? LinearGradient(colors: gradient) : null,
                    color: isOn ? null : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOn
                          ? gradient[0]
                          : hasError
                              ? Colors.red.shade300
                              : AppColors.borderColor.withValues(alpha: 0.5),
                      width: isOn || hasError ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOn) ...[
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOn ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        else
          TextField(
            controller: textController,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter ${field.label.toLowerCase()}',
              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: hasError ? Colors.red.withValues(alpha: 0.04) : AppColors.cardBackground,
              suffixIcon: hasError
                  ? Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade400)
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: hasError ? Colors.red.shade400 : AppColors.borderColor.withValues(alpha: 0.5),
                  width: hasError ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: hasError ? Colors.red.shade400 : gradient[0],
                  width: 1.5,
                ),
              ),
            ),
          ),

        // ── Inline error ─────────────────────────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 4),
              Icon(Icons.info_outline_rounded, size: 12, color: Colors.red.shade600),
              const SizedBox(width: 4),
              Text(errorText!, style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Confirmation dialog ──────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.name,
    required this.email,
    required this.phone,
    required this.resumeLabel,
    required this.answers,
    required this.gradient,
    required this.onConfirm,
  });

  final String name;
  final String email;
  final String phone;
  final String resumeLabel;
  final List<Map<String, String>> answers;
  final List<Color> gradient;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fact_check_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Review Your Application',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(
                    icon: Icons.person_rounded,
                    label: 'Full Name',
                    value: name.isEmpty ? '—' : name,
                  ),
                  _ReviewRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: email,
                  ),
                  _ReviewRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: phone,
                  ),
                  _ReviewRow(
                    icon: Icons.description_rounded,
                    label: 'Resume',
                    value: resumeLabel.isEmpty ? 'Attached' : resumeLabel,
                  ),
                  if (answers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(
                      color: AppColors.borderColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Application Answers',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...answers.map(
                      (a) => _ReviewRow(
                        icon: Icons.quiz_rounded,
                        label: a['label']!,
                        value: a['value']!.isEmpty ? '—' : a['value']!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.borderColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: onConfirm,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Confirm & Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
