import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/chat_screen/widgets/preseigner_url.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/repository/job_community/job_community_model.dart';
import 'package:luminar_std/repository/job_community/job_community_service.dart';

const List<Color> _kApplyGradient = [Color(0xFF533483), Color(0xFF7B52AB)];

Future<void> openCommunityApplySheet(
  BuildContext context, {
  required String communityUid,
  required String jobUid,
  required String jobTitle,
  required String companyName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommunityApplySheet(
      communityUid: communityUid,
      jobUid: jobUid,
      jobTitle: jobTitle,
      companyName: companyName,
    ),
  );
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Application submitted!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}

class _CommunityApplySheet extends StatefulWidget {
  const _CommunityApplySheet({
    required this.communityUid,
    required this.jobUid,
    required this.jobTitle,
    required this.companyName,
  });

  final String communityUid;
  final String jobUid;
  final String jobTitle;
  final String companyName;

  @override
  State<_CommunityApplySheet> createState() => _CommunityApplySheetState();
}

class _CommunityApplySheetState extends State<_CommunityApplySheet> {
  final _service = JobCommunityService();

  late final TextEditingController _nameCtrl = TextEditingController();
  late final TextEditingController _emailCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl = TextEditingController();

  final Map<String, TextEditingController> _textAnswers = {};
  final Map<String, Set<String>> _selectAnswers = {};
  final Map<String, DateTime?> _dateAnswers = {};
  final Map<String, String?> _fileAnswers = {};
  final Map<String, bool> _fileUploading = {};

  final Map<String, String?> _errors = {};

  String? _resumeUrl;
  File? _pickedResume;
  String? _pickedResumeName;

  CommunityJobDetail? _jobDetail;
  bool _loading = true;
  String? _loadError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _textAnswers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
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

    final res = await _service.getJobDetail(widget.jobUid);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final detail = res.data!;
      for (final f in detail.customFields) {
        if (f.isSelect) {
          _selectAnswers[f.uid] = {};
        } else if (f.fieldType == 'date') {
          _dateAnswers[f.uid] = null;
        } else if (f.fieldType == 'file') {
          _fileAnswers[f.uid] = null;
        } else {
          final ctrl = TextEditingController();
          ctrl.addListener(() => _clearError(f.uid));
          _textAnswers[f.uid] = ctrl;
        }
      }
      setState(() {
        _jobDetail = detail;
        _loading = false;
      });
    } else {
      setState(() {
        _loadError = res.message ?? 'Failed to load this job.';
        _loading = false;
      });
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() {
      _pickedResume = File(path);
      _pickedResumeName = result.files.first.name;
      _resumeUrl = null;
      _errors.remove('resume');
    });
  }

  Future<void> _pickCustomFile(String fieldUid) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    setState(() => _fileUploading[fieldUid] = true);
    try {
      final token = await AppUtils.getAccessKey();
      final uploader = FileUploadService(
        baseUrl: GlobalLinks.baseUrl,
        token: token ?? '',
      );
      final uploaded = await uploader.uploadFile(File(path), folder: 'community');
      if (!mounted) return;
      setState(() {
        _fileAnswers[fieldUid] = uploaded.finalUrl;
        _fileUploading[fieldUid] = false;
        _errors.remove(fieldUid);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _fileUploading[fieldUid] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDate(String fieldUid) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateAnswers[fieldUid] ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _dateAnswers[fieldUid] = picked;
        _errors.remove(fieldUid);
      });
    }
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  bool _hasResume() => _resumeUrl != null || _pickedResume != null;

  bool _validate() {
    final next = <String, String?>{};
    if (_emailCtrl.text.trim().isEmpty) next['email'] = 'Email is required.';
    if (_phoneCtrl.text.trim().isEmpty) next['phone'] = 'Phone number is required.';
    if (!_hasResume()) next['resume'] = 'Please attach a resume.';

    for (final f in _jobDetail!.customFields) {
      if (!f.isRequired) continue;
      if (f.isSelect) {
        if (_selectAnswers[f.uid]?.isEmpty ?? true) next[f.uid] = '${f.label} is required.';
      } else if (f.fieldType == 'date') {
        if (_dateAnswers[f.uid] == null) next[f.uid] = '${f.label} is required.';
      } else if (f.fieldType == 'file') {
        if (_fileAnswers[f.uid] == null) next[f.uid] = '${f.label} is required.';
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

  List<Map<String, dynamic>> _buildAnswers() {
    return _jobDetail!.customFields.map((f) {
      dynamic value;
      if (f.isMulti) {
        value = (_selectAnswers[f.uid] ?? {}).toList();
      } else if (f.isSelect) {
        value = (_selectAnswers[f.uid] ?? {}).isEmpty
            ? ''
            : (_selectAnswers[f.uid] ?? {}).first;
      } else if (f.fieldType == 'date') {
        final d = _dateAnswers[f.uid];
        value = d == null ? '' : DateFormat('yyyy-MM-dd').format(d);
      } else if (f.fieldType == 'file') {
        value = _fileAnswers[f.uid] ?? '';
      } else {
        value = _textAnswers[f.uid]?.text.trim() ?? '';
      }
      return {'field_uid': f.uid, 'value': value};
    }).toList();
  }

  void _showConfirmation() {
    if (!_validate()) return;

    final reviewAnswers = _jobDetail!.customFields.map((f) {
      String display;
      if (f.isMulti) {
        display = (_selectAnswers[f.uid] ?? {}).join(', ');
      } else if (f.isSelect) {
        display = (_selectAnswers[f.uid] ?? {}).isEmpty
            ? ''
            : (_selectAnswers[f.uid] ?? {}).first;
      } else if (f.fieldType == 'date') {
        final d = _dateAnswers[f.uid];
        display = d == null ? '' : DateFormat('dd MMM yyyy').format(d);
      } else if (f.fieldType == 'file') {
        display = (_fileAnswers[f.uid] ?? '').split('/').last;
      } else {
        display = _textAnswers[f.uid]?.text.trim() ?? '';
      }
      return {'label': f.label, 'value': display};
    }).where((e) => (e['value'] ?? '').isNotEmpty).toList();

    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        resumeLabel: _pickedResumeName ??
            (_resumeUrl != null ? _resumeUrl!.split('/').last.split('?').first : ''),
        answers: reviewAnswers,
        onConfirm: _submit,
      ),
    );
  }

  Future<void> _submit() async {
    Navigator.pop(context); // close confirm dialog
    setState(() => _isSubmitting = true);

    final res = await _service.applyToJob(
      communityUid: widget.communityUid,
      jobUid: widget.jobUid,
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      answers: _buildAnswers(),
      resumeFilePath: _pickedResume?.path,
      resumeUrl: _pickedResume == null ? _resumeUrl : null,
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
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetHeader(jobTitle: widget.jobTitle, companyName: widget.companyName),
            Expanded(child: _buildBody(scrollCtrl, bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollCtrl, double bottomInset) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 100),
            children: [
              const _SectionLabel(label: 'Personal Information'),
              const SizedBox(height: 12),
              _ApplyField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_rounded,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              _ApplyField(
                controller: _emailCtrl,
                label: 'Email *',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                errorText: _errors['email'],
              ),
              const SizedBox(height: 12),
              _ApplyField(
                controller: _phoneCtrl,
                label: 'Phone *',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                readOnly: true,
                errorText: _errors['phone'],
              ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'Resume *'),
              const SizedBox(height: 12),
              _ResumeSection(
                resumeUrl: _resumeUrl,
                pickedFileName: _pickedResumeName,
                onPickFile: _pickResume,
                errorText: _errors['resume'],
                onClear: () => setState(() {
                  _pickedResume = null;
                  _pickedResumeName = null;
                }),
              ),
              if (_jobDetail!.customFields.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionLabel(label: 'Application Questions'),
                const SizedBox(height: 12),
                ..._jobDetail!.customFields.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CustomFieldInput(
                      field: f,
                      textController: _textAnswers[f.uid],
                      selected: _selectAnswers[f.uid] ?? {},
                      selectedDate: _dateAnswers[f.uid],
                      fileUrl: _fileAnswers[f.uid],
                      fileUploading: _fileUploading[f.uid] ?? false,
                      errorText: _errors[f.uid],
                      onSelectChanged: (val) => setState(() {
                        _selectAnswers[f.uid] = val;
                        _errors.remove(f.uid);
                      }),
                      onPickDate: () => _pickDate(f.uid),
                      onPickFile: () => _pickCustomFile(f.uid),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _kApplyGradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kApplyGradient[0].withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _isSubmitting ? null : _showConfirmation,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Review & Apply',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.jobTitle, required this.companyName});

  final String jobTitle;
  final String companyName;

  String _initials() {
    final parts = companyName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _kApplyGradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initials(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apply for Position',
                  style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  jobTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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

// ─────────────────────────────────────────────────────────────────────────────
// Basic field
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyField extends StatelessWidget {
  const _ApplyField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
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
          style: TextStyle(fontSize: 14, color: readOnly ? AppColors.textSecondary : AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: hasError ? Colors.red.shade600 : AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: hasError
                  ? Colors.red.shade400
                  : readOnly
                      ? AppColors.textSecondary
                      : _kApplyGradient[0],
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
                color: hasError ? Colors.red.shade400 : AppColors.borderColor.withValues(alpha: readOnly ? 0.3 : 0.5),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade400 : (readOnly ? AppColors.borderColor : _kApplyGradient[0]),
                width: readOnly ? 1.0 : 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          _ErrorLine(text: errorText!),
        ],
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Icon(Icons.info_outline_rounded, size: 12, color: Colors.red.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resume section
// ─────────────────────────────────────────────────────────────────────────────

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({
    required this.resumeUrl,
    required this.pickedFileName,
    required this.onPickFile,
    required this.onClear,
    this.errorText,
  });

  final String? resumeUrl;
  final String? pickedFileName;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final String? errorText;

  String get _displayName {
    if (pickedFileName != null) return pickedFileName!;
    if (resumeUrl != null) return resumeUrl!.split('/').last.split('?').first;
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
          color: _kApplyGradient[0].withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kApplyGradient[0].withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kApplyGradient[0].withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description_rounded, color: _kApplyGradient[0], size: 20),
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
                foregroundColor: _kApplyGradient[0],
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
              Icon(Icons.upload_file_rounded, color: hasError ? Colors.red.shade400 : _kApplyGradient[0], size: 32),
              const SizedBox(height: 8),
              Text(
                'Upload Resume',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: hasError ? Colors.red.shade600 : _kApplyGradient[0]),
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
        if (hasError) ...[const SizedBox(height: 4), _ErrorLine(text: errorText!)],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom field input — text | select | multi_select | date | number | url | file
// ─────────────────────────────────────────────────────────────────────────────

class _CustomFieldInput extends StatelessWidget {
  const _CustomFieldInput({
    required this.field,
    required this.textController,
    required this.selected,
    required this.selectedDate,
    required this.fileUrl,
    required this.fileUploading,
    required this.onSelectChanged,
    required this.onPickDate,
    required this.onPickFile,
    this.errorText,
  });

  final CommunityCustomField field;
  final TextEditingController? textController;
  final Set<String> selected;
  final DateTime? selectedDate;
  final String? fileUrl;
  final bool fileUploading;
  final ValueChanged<Set<String>> onSelectChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickFile;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                style: TextStyle(color: hasError ? Colors.red.shade600 : const Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInput(context, hasError),
        if (hasError) ...[const SizedBox(height: 4), _ErrorLine(text: errorText!)],
      ],
    );
  }

  Widget _buildInput(BuildContext context, bool hasError) {
    switch (field.fieldType) {
      case 'select':
      case 'multi_select':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: field.options.map((opt) {
            final isOn = selected.contains(opt);
            return GestureDetector(
              onTap: () {
                final next = Set<String>.from(selected);
                if (field.fieldType == 'select') {
                  next.clear();
                  if (!isOn) next.add(opt);
                } else {
                  if (isOn) {
                    next.remove(opt);
                  } else {
                    next.add(opt);
                  }
                }
                onSelectChanged(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isOn ? const LinearGradient(colors: _kApplyGradient) : null,
                  color: isOn ? null : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOn
                        ? _kApplyGradient[0]
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOn ? Colors.white : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );

      case 'date':
        return GestureDetector(
          onTap: onPickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: hasError ? Colors.red.withValues(alpha: 0.04) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? Colors.red.shade400 : AppColors.borderColor.withValues(alpha: 0.5),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: hasError ? Colors.red.shade400 : _kApplyGradient[0]),
                const SizedBox(width: 10),
                Text(
                  selectedDate == null ? 'Select date' : DateFormat('dd MMM yyyy').format(selectedDate!),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

      case 'file':
        if (fileUploading) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        }
        if (fileUrl != null && fileUrl!.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kApplyGradient[0].withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kApplyGradient[0].withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: _kApplyGradient[0]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileUrl!.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: onPickFile,
                  style: TextButton.styleFrom(foregroundColor: _kApplyGradient[0], padding: EdgeInsets.zero),
                  child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return GestureDetector(
          onTap: onPickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: hasError ? Colors.red.withValues(alpha: 0.04) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? Colors.red.shade400 : AppColors.borderColor.withValues(alpha: 0.5),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file_rounded, size: 16, color: hasError ? Colors.red.shade400 : _kApplyGradient[0]),
                  const SizedBox(width: 8),
                  Text(
                    'Upload file',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasError ? Colors.red.shade600 : _kApplyGradient[0]),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'number':
        return _plainTextField(hint: 'Enter ${field.label.toLowerCase()}', hasError: hasError, keyboardType: const TextInputType.numberWithOptions(decimal: true));

      case 'url':
        return _plainTextField(hint: 'https://…', hasError: hasError, keyboardType: TextInputType.url);

      case 'text':
      default:
        return _plainTextField(hint: 'Enter ${field.label.toLowerCase()}', hasError: hasError);
    }
  }

  Widget _plainTextField({required String hint, required bool hasError, TextInputType? keyboardType}) {
    return TextField(
      controller: textController,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: hasError ? Colors.red.withValues(alpha: 0.04) : AppColors.cardBackground,
        suffixIcon: hasError ? Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade400) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hasError ? Colors.red.shade400 : AppColors.borderColor.withValues(alpha: 0.5), width: hasError ? 1.5 : 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hasError ? Colors.red.shade400 : _kApplyGradient[0], width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.name,
    required this.email,
    required this.phone,
    required this.resumeLabel,
    required this.answers,
    required this.onConfirm,
  });

  final String name;
  final String email;
  final String phone;
  final String resumeLabel;
  final List<Map<String, String>> answers;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: _kApplyGradient),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.fact_check_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('Review Your Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(icon: Icons.person_rounded, label: 'Full Name', value: name.isEmpty ? '—' : name),
                  _ReviewRow(icon: Icons.email_rounded, label: 'Email', value: email),
                  _ReviewRow(icon: Icons.phone_rounded, label: 'Phone', value: phone),
                  _ReviewRow(icon: Icons.description_rounded, label: 'Resume', value: resumeLabel.isEmpty ? 'Attached' : resumeLabel),
                  if (answers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: AppColors.borderColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('Application Answers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.4)),
                    const SizedBox(height: 8),
                    ...answers.map((a) => _ReviewRow(icon: Icons.quiz_rounded, label: a['label']!, value: a['value']!.isEmpty ? '—' : a['value']!)),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: _kApplyGradient), borderRadius: BorderRadius.circular(12)),
                    child: TextButton(
                      onPressed: onConfirm,
                      style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Confirm & Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
  const _ReviewRow({required this.icon, required this.label, required this.value});

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
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
