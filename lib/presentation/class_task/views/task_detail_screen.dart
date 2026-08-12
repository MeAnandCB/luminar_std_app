import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/class_task/class_task_model.dart';
import 'package:luminar_std/repository/class_task/class_task_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailScreen extends StatefulWidget {
  final StudentAssignment assignment;
  final String? batchName;
  final VoidCallback? onTaskUpdated;

  const TaskDetailScreen({
    super.key,
    required this.assignment,
    this.batchName,
    this.onTaskUpdated,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ClassTaskService _service = ClassTaskService();
  final TextEditingController _messageController = TextEditingController();

  late StudentAssignment _currentAssignment;
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _currentAssignment = widget.assignment;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _getEffectiveStatus(StudentAssignment a) {
    final status = a.status.toUpperCase();
    final lastVer = (a.lastVerificationResult ??
            a.latestSubmission?.verificationStatus ??
            '')
        .toUpperCase();

    if (status == 'PASSED' ||
        status == 'PASS' ||
        lastVer == 'PASS' ||
        lastVer == 'PASSED') {
      return 'PASSED';
    }
    if (status == 'FAILED' ||
        status == 'FAIL' ||
        status == 'REJECTED' ||
        lastVer == 'FAIL' ||
        lastVer == 'FAILED' ||
        lastVer == 'REJECTED') {
      return 'FAILED';
    }
    if (status == 'SUBMITTED') {
      return 'SUBMITTED';
    }
    return 'NOT_SUBMITTED';
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final combined = [..._selectedFiles, ...result.files];
        List<PlatformFile> filtered = combined;
        if (combined.length > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 10 files allowed per submission.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          filtered = combined.take(10).toList();
        }

        final totalBytes = filtered.fold<int>(0, (sum, f) => sum + f.size);
        const max20MB = 20 * 1024 * 1024;
        if (totalBytes > max20MB && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Selected files total ${_formatFileSize(totalBytes)}, exceeding the 20MB limit. Please remove some files.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          _selectedFiles = filtered;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitTask() async {
    final totalBytes = _selectedFiles.fold<int>(0, (sum, f) => sum + f.size);
    const max20MB = 20 * 1024 * 1024;

    if (totalBytes > max20MB) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Total file size (${_formatFileSize(totalBytes)}) exceeds the 20MB limit. Please remove some files before submitting.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hasNote = _messageController.text.trim().isNotEmpty;
    final hasAttachment = _selectedFiles.isNotEmpty;

    if (!hasNote && !hasAttachment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a note or attach a file before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final List<http.MultipartFile> multipartFiles = [];

      for (var pFile in _selectedFiles) {
        if (pFile.path != null && pFile.path!.isNotEmpty) {
          final file = File(pFile.path!);
          multipartFiles.add(
            await http.MultipartFile.fromPath(
              'attachments',
              file.path,
              filename: pFile.name,
            ),
          );
        } else if (pFile.bytes != null) {
          multipartFiles.add(
            http.MultipartFile.fromBytes(
              'attachments',
              pFile.bytes!,
              filename: pFile.name,
            ),
          );
        }
      }

      final res = await _service.submitTask(
        assignmentUid: _currentAssignment.uid,
        files: multipartFiles,
        message: _messageController.text,
      );

      if (!mounted) return;

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Task submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _messageController.clear();
        setState(() {
          _selectedFiles.clear();
          _isSubmitting = false;
        });

        widget.onTaskUpdated?.call();
        _refreshTaskDetail();
      } else {
        setState(() {
          _submitError = res.message ?? 'Failed to submit task.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = 'An error occurred during submission: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _refreshTaskDetail() async {
    final res =
        await _service.getMyTasks(taskUid: _currentAssignment.task.taskUid);
    if (res.success && res.data != null && res.data!.assignments.isNotEmpty) {
      final updated = res.data!.assignments.firstWhere(
        (a) => a.uid == _currentAssignment.uid,
        orElse: () => res.data!.assignments.first,
      );
      if (mounted) {
        setState(() {
          _currentAssignment = updated;
        });
      }
    }
  }

  Future<void> _openFileUrl(String rawUrl) async {
    String fullUrl = rawUrl;
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      fullUrl = '${GlobalLinks.baseUrl}$rawUrl';
    }
    final uri = Uri.parse(fullUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch URL: $fullUrl')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'No due date';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('EEE, dd MMM yyyy • hh:mm a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentAssignment.task;
    final effectiveStatus = _getEffectiveStatus(_currentAssignment);
    final latestSub = _currentAssignment.latestSubmission;
    bool isOverdue = false;
    if (task.dueAt != null && task.dueAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(task.dueAt!).toLocal();
        if (dt.isBefore(DateTime.now())) {
          isOverdue = true;
        }
      } catch (_) {}
    }

    final canSubmit = _currentAssignment.canResubmit &&
        effectiveStatus != 'PASSED' &&
        _currentAssignment.attemptsUsed < _currentAssignment.maxAttempts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Assignment Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference / Sample Files shared by the instructor
            if (task.attachments.isNotEmpty) ...[
              _buildReferenceAttachmentsCard(task.attachments),
              const SizedBox(height: 16),
            ],

            // Task Header Card
            _buildTaskHeaderCard(task),

            const SizedBox(height: 16),

            // Attempt Progress & Status Bar
            _buildStatusOverviewCard(effectiveStatus),

            // Latest Submission & Feedback section
            if (latestSub != null || effectiveStatus != 'NOT_SUBMITTED') ...[
              const SizedBox(height: 18),
              _buildLatestSubmissionCard(latestSub, effectiveStatus),
            ],

            const SizedBox(height: 18),

            // Form or Status Lock Banner
            if (canSubmit)
              _buildSubmissionFormCard(isOverdue: isOverdue)
            else
              _buildSubmissionLockedBanner(effectiveStatus, isOverdue),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceAttachmentsCard(List<TaskAttachmentInfo> attachments) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reference Files',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared by your instructor as a sample',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${attachments.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...attachments.map((att) => _buildReferenceAttachmentItem(att)),
        ],
      ),
    );
  }

  Widget _buildReferenceAttachmentItem(TaskAttachmentInfo att) {
    final isImage = att.contentType.startsWith('image/');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              isImage ? _showImagePreview(att) : _openFileUrl(att.url),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: isImage
                      ? SizedBox(
                          width: 42,
                          height: 42,
                          child: Image.network(
                            att.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _getFileIcon(att.originalName),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 42,
                                height: 42,
                                color: const Color(0xFFEDE9FE),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _getFileIcon(att.originalName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att.originalName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(att.fileSize),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isImage
                        ? Icons.zoom_in_rounded
                        : Icons.open_in_new_rounded,
                    size: 16,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(TaskAttachmentInfo att) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    att.url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Preview not available for this file',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: InkWell(
                onTap: () => Navigator.of(dialogContext).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 60,
              top: 44,
              child: Text(
                att.originalName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _openFileUrl(att.url),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open in browser'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeaderCard(StudentTaskInfo task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.batchName != null &&
                        widget.batchName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.batchName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: const [
                Icon(
                  Icons.article_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                task.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusOverviewCard(String effectiveStatus) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (effectiveStatus) {
      case 'PASSED':
        statusColor = const Color(0xFF10B981);
        statusText = 'Passed';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'SUBMITTED':
        statusColor = const Color(0xFF3B82F6);
        statusText = 'Submitted (Under Review)';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'FAILED':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Failed / Needs Resubmission';
        statusIcon = Icons.error_rounded;
        break;
      case 'NOT_SUBMITTED':
      default:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Pending Submission';
        statusIcon = Icons.pending_actions_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Attempts: ${_currentAssignment.attemptsUsed}/${_currentAssignment.maxAttempts}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Due Date: ${_formatDate(_currentAssignment.task.dueAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
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

  Widget _buildLatestSubmissionCard(
    TaskSubmissionInfo? submission,
    String effectiveStatus,
  ) {
    if (submission == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'No submission details recorded yet.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    final hasFeedback =
        submission.feedback != null && submission.feedback!.isNotEmpty;
    final verStatus =
        (submission.verificationStatus ?? effectiveStatus).toUpperCase();
    final isFailedVer =
        verStatus == 'FAIL' || verStatus == 'FAILED' || verStatus == 'REJECTED';
    final isPassedVer = verStatus == 'PASSED' || verStatus == 'PASS';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_edu_rounded,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Latest Submission (Attempt #${submission.attemptNumber})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (verStatus.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPassedVer
                        ? const Color(0xFFDCFCE7)
                        : isFailedVer
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPassedVer
                          ? const Color(0xFF86EFAC)
                          : isFailedVer
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFF7DD3FC),
                    ),
                  ),
                  child: Text(
                    verStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPassedVer
                          ? const Color(0xFF166534)
                          : isFailedVer
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF075985),
                    ),
                  ),
                ),
            ],
          ),
          if (submission.submittedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Submitted on: ${_formatDate(submission.submittedAt)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],

          if (submission.message != null &&
              submission.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Note:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submission.message!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Staff Feedback alert box
          if (hasFeedback) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isFailedVer
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFailedVer
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rate_review_rounded,
                        size: 18,
                        color:
                            isFailedVer ? Colors.red : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Staff Feedback:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isFailedVer
                              ? Colors.red.shade900
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    submission.feedback!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isFailedVer
                          ? Colors.red.shade900
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Attachments list
          if (submission.attachments.isNotEmpty ||
              submission.attachmentUrl != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Submitted Attachments:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            if (submission.attachments.isNotEmpty)
              ...submission.attachments.map((att) => _buildAttachmentItem(att))
            else if (submission.attachmentUrl != null)
              _buildSingleAttachmentItem(submission.attachmentUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(TaskAttachmentInfo att) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _getFileIcon(att.originalName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.originalName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(att.fileSize),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
            ),
            onPressed: () => _openFileUrl(att.url),
            tooltip: 'View File',
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAttachmentItem(String url) {
    final fileName = url.split('/').last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _getFileIcon(fileName),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
            ),
            onPressed: () => _openFileUrl(url),
            tooltip: 'View File',
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionFormCard({bool isOverdue = false}) {
    final totalSelectedBytes =
        _selectedFiles.fold<int>(0, (sum, f) => sum + f.size);
    const max20MB = 20 * 1024 * 1024;
    final isExceeding20MB = totalSelectedBytes > max20MB;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Submit Your Work',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload your solution files (ZIP, PDF, images, source code, etc.). Maximum 10 files allowed.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Overdue / Late Submission Warning Banner
          if (isOverdue) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.timer_off_rounded,
                    size: 20,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Late Submission Notice: This assignment is past its due date. Your submission will be recorded as overdue.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 20MB Limit Warning Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Note: Maximum total size limit is 20MB for all selected files combined (up to 10 files max).',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // File Picker Box
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSubmitting ? null : _pickFiles,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isExceeding20MB
                        ? Colors.red
                        : AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 32,
                      color: isExceeding20MB ? Colors.red : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFiles.isEmpty
                          ? 'Tap to Browse & Attach Files'
                          : 'Add More Files (${_selectedFiles.length}/10)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isExceeding20MB ? Colors.red : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedFiles.isEmpty
                          ? 'Supports any file type up to 20MB total'
                          : 'Total selected size: ${_formatFileSize(totalSelectedBytes)} / 20 MB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isExceeding20MB
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isExceeding20MB
                            ? Colors.red
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Files:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  'Total: ${_formatFileSize(totalSelectedBytes)} / 20 MB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isExceeding20MB ? Colors.red : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _getFileIcon(file.name),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatFileSize(file.size),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed:
                            _isSubmitting ? null : () => _removeFile(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // Message Field
          TextField(
            controller: _messageController,
            enabled: !_isSubmitting,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add an optional note or comment for the instructor...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          if (_submitError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // High-End Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Submit Assignment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionLockedBanner(
    String effectiveStatus,
    bool isOverdue,
  ) {
    String text;
    IconData icon;
    Color iconColor;

    if (effectiveStatus == 'PASSED') {
      text =
          '🎉 Assignment marked as PASSED! No further submissions are needed.';
      icon = Icons.stars_rounded;
      iconColor = const Color(0xFF10B981);
    } else if (isOverdue) {
      text =
          '⏰ This assignment is past its due date. Submissions are closed.';
      icon = Icons.timer_off_rounded;
      iconColor = const Color(0xFFEF4444);
    } else if (_currentAssignment.attemptsUsed >=
        _currentAssignment.maxAttempts) {
      text =
          'Maximum attempts limit reached (${_currentAssignment.maxAttempts}/${_currentAssignment.maxAttempts}). Resubmission is disabled.';
      icon = Icons.block_rounded;
      iconColor = const Color(0xFFEF4444);
    } else {
      text = 'Resubmission is currently locked for this assignment.';
      icon = Icons.lock_rounded;
      iconColor = const Color(0xFF64748B);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData icon;
    Color color;

    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      icon = Icons.folder_zip_rounded;
      color = Colors.amber.shade700;
    } else if (['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext)) {
      icon = Icons.image_rounded;
      color = Colors.blue;
    } else if (['pdf'].contains(ext)) {
      icon = Icons.picture_as_pdf_rounded;
      color = Colors.red;
    } else if (['dart', 'js', 'py', 'java', 'html', 'css', 'json', 'cpp'].contains(ext)) {
      icon = Icons.code_rounded;
      color = Colors.purple;
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
