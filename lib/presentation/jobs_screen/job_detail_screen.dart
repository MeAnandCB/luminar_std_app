import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/jobs_screen/job_apply_sheet.dart';
import 'package:luminar_std/repository/jobs/model/job_notification_model.dart';
import 'package:luminar_std/repository/jobs/service/jobs_service.dart';
import 'package:provider/provider.dart';

final _historyDateFmt = DateFormat('MMM d, y • h:mm a');

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.jobUid,
    required this.notification,
  });

  final String jobUid;
  final JobNotification notification;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final JobsService _service = JobsService();

  JobDetailResponse? _detail;
  JobApplicationDetail? _appDetail;
  bool _isLoading = true;
  bool _isLoadingApp = false;
  String? _error;

  static const List<List<Color>> _gradients = [
    [Color(0xFF533483), Color(0xFF7B52AB)],
    [Color(0xFF0F3460), Color(0xFF1A6FA0)],
    [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    [Color(0xFF6D1E1E), Color(0xFFA03434)],
    [Color(0xFF1A1A5E), Color(0xFF2D2DA0)],
  ];

  List<Color> get _gradient {
    final name = widget.notification.companyName;
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % _gradients.length;
    return _gradients[idx];
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
    // Start fetching application detail in parallel if UID already known
    final appUid = widget.notification.application.applicationUid;
    if (widget.notification.application.hasApplication && appUid != null) {
      _loadApplicationDetail(appUid);
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await _service.getJobDetail(widget.jobUid);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _detail = res.data;
        _isLoading = false;
      });
      // Mark as viewed and decrement dashboard badge
      if (!res.data!.notification.isViewed) {
        _service.markJobAsViewed(widget.jobUid);
        if (mounted) {
          Provider.of<DashboardController>(context, listen: false)
              .decrementUnviewedJobNotifications();
        }
      }
      // Fetch application detail if not already loaded
      final appUid = res.data!.application.applicationUid;
      if (res.data!.application.hasApplication &&
          appUid != null &&
          _appDetail == null) {
        _loadApplicationDetail(appUid);
      }
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load job details';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApplicationDetail(String applicationUid) async {
    if (_isLoadingApp) return;
    setState(() => _isLoadingApp = true);
    final res = await _service.getApplicationDetail(applicationUid);
    if (!mounted) return;
    setState(() {
      if (res.success && res.data != null) {
        _appDetail = res.data!.application;
      }
      _isLoadingApp = false;
    });
  }

  Future<void> _openApplySheet() async {
    final applied = await showJobApplySheet(
      context,
      jobDetail: _detail!.job,
      notification: widget.notification,
      gradient: _gradient,
    );
    if (!mounted) return;
    if (applied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      // Reload to reflect applied status
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final applied = _detail?.application.hasApplication ??
        notification.application.hasApplication;
    final gradient = _gradient;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(notification, gradient),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorBody(error: _error!, onRetry: _loadDetail),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _buildInfoChips(_detail!.job, gradient),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(_detail!.job),
                  if (applied) ...[
                    // 2. Application Status
                    const SizedBox(height: 16),
                    _buildApplicationStatusSection(gradient),
                    // 3. Interviews
                    if (_appDetail != null && _appDetail!.interviews.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInterviewsSection(_appDetail!.interviews, gradient),
                    ],
                    // 4. Stage History
                    if (_appDetail != null && _appDetail!.stageHistory.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Stage History',
                        icon: Icons.history_rounded,
                        child: _buildStageHistory(_appDetail!.stageHistory),
                      ),
                    ],
                  ],
                ]),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(applied, gradient),
    );
  }

  Widget _buildAppBar(JobNotification notification, List<Color> gradient) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gradient[0].withValues(alpha: 0.2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _CompanyAvatar(
                      logoUrl: _detail?.job.company.logo,
                      name: notification.companyName,
                      gradient: gradient,
                      size: 64,
                      radius: 18,
                      fontSize: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.companyName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.jobTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isViewed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Text(
          notification.jobTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
      ),
    );
  }

  Widget _buildInfoChips(JobDetail job, List<Color> gradient) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (job.location.isNotEmpty)
          _InfoChip(
            icon: Icons.location_on_rounded,
            label: job.location,
            color: gradient[0],
          ),
        if (job.publishedAt != null)
          _InfoChip(
            icon: Icons.calendar_today_rounded,
            label: 'Posted ${dateFormat.format(job.publishedAt!.toLocal())}',
            color: AppColors.textSecondary,
          ),
        if (job.expiresAt != null)
          _InfoChip(
            icon: job.isExpired
                ? Icons.event_busy_rounded
                : Icons.event_available_rounded,
            label: job.isExpired
                ? 'Expired ${dateFormat.format(job.expiresAt!.toLocal())}'
                : 'Apply by ${dateFormat.format(job.expiresAt!.toLocal())}',
            color: job.isExpired
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
          ),
        _InfoChip(
          icon: Icons.groups_2_rounded,
          label: widget.notification.batchName,
          color: gradient[0],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(JobDetail job) {
    return _SectionCard(
      title: 'About This Role',
      icon: Icons.description_rounded,
      child: Text(
        job.description.isEmpty ? 'No description provided.' : job.description,
        style: TextStyle(
          fontSize: 14,
          color: job.description.isEmpty
              ? AppColors.textSecondary
              : AppColors.textPrimary,
          height: 1.65,
        ),
      ),
    );
  }

  // ── Rich application status section ───────────────────────────────────────

  Widget _buildApplicationStatusSection(List<Color> gradient) {
    // Loading state
    if (_isLoadingApp && _appDetail == null) {
      return _SectionCard(
        title: 'Application Status',
        icon: Icons.assignment_rounded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    // Fallback to basic if detail API failed
    if (_appDetail == null) {
      return _buildBasicStatusCard(_detail!.application);
    }

    final d = _appDetail!;
    final stage = d.currentStage;
    final code = stage?.code ?? '';
    final isRejected = code.contains('reject');
    final isSelected = code.contains('select');

    final Color stageColor;
    final IconData stageIcon;
    final String stageLabel;
    final String stageDesc;

    if (isRejected) {
      stageColor = const Color(0xFFEF4444);
      stageIcon = Icons.cancel_rounded;
      stageLabel = stage?.name ?? 'Not Selected';
      stageDesc = 'Thank you for applying. Keep exploring other opportunities.';
    } else if (isSelected) {
      stageColor = const Color(0xFF10B981);
      stageIcon = Icons.verified_rounded;
      stageLabel = stage?.name ?? 'Selected';
      stageDesc = 'Congratulations! You have been selected.';
    } else {
      stageColor = const Color(0xFF10B981);
      stageIcon = Icons.task_alt_rounded;
      stageLabel = stage?.name ?? 'Applied';
      stageDesc = 'Your application has been submitted successfully.';
    }

    final rejectionNote = d.rejectionNote;

    return _SectionCard(
      title: 'Application Status',
      icon: Icons.assignment_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current stage header ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(stageIcon, color: stageColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: stageColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stageDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (d.appliedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Applied ${DateFormat('MMM d, yyyy').format(d.appliedAt!.toLocal())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Rejection reason box ─────────────────────────────────
          if (isRejected &&
              rejectionNote != null &&
              rejectionNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rejectionNote,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Resume ──────────────────────────────────────────────
          if ((d.resumeFile ?? d.resumeUrl) != null) ...[
            const SizedBox(height: 16),
            _buildResumeExpansionTile(d.resumeFile ?? d.resumeUrl!, gradient),
          ],

          // ── Submitted answers ────────────────────────────────────
          if (d.answers.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildAnswersExpansionTile(d.answers, gradient),
          ],

        ],
      ),
    );
  }

  Widget _buildResumeExpansionTile(String url, List<Color> gradient) {
    final fileName = url.split('/').last.split('?').first;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final uri = Uri.tryParse(url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: gradient[0].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.picture_as_pdf_rounded, color: gradient[0], size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileName.isNotEmpty ? fileName : 'Tap to open',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.open_in_new_rounded, size: 16, color: gradient[0]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewsSection(List<JobInterview> interviews, List<Color> gradient) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return _SectionCard(
      title: 'Interviews',
      icon: Icons.event_note_rounded,
      child: Column(
        children: interviews.asMap().entries.map((entry) {
          final iv = entry.value;
          final isLast = entry.key == interviews.length - 1;
          final attendanceColor = _attendanceColor(iv.attendance);

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: attendanceColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: gradient[0].withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iv.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                            color: gradient[0],
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mode label — fully from API
                              Text(
                                iv.isOnline ? 'Online Interview' : 'Offline Interview',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Stage name badge — dynamic from API
                              if (iv.stageName.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: gradient[0].withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    iv.stageName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: gradient[0],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Attendance badge — fully from API
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: attendanceColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: attendanceColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            iv.attendance.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: attendanceColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.borderColor.withValues(alpha: 0.4)),
                  // ── Detail grid ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        if (iv.scheduledAt != null) ...[
                          _ivChip(Icons.calendar_today_rounded, dateFmt.format(iv.scheduledAt!.toLocal())),
                          _ivChip(Icons.access_time_rounded, timeFmt.format(iv.scheduledAt!.toLocal())),
                        ],
                        if ((iv.location ?? '').isNotEmpty)
                          _ivChip(Icons.place_rounded, iv.location!),
                        if ((iv.meetingLink ?? '').isNotEmpty)
                          _ivChip(Icons.link_rounded, 'Join Link'),
                        if ((iv.score ?? '').isNotEmpty)
                          _ivChip(Icons.star_rounded, 'Score: ${iv.score}'),
                      ],
                    ),
                  ),
                  if ((iv.feedback ?? '').isNotEmpty) ...[
                    Divider(height: 1, color: AppColors.borderColor.withValues(alpha: 0.3)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.comment_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              iv.feedback!,
                              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _ivChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      ],
    );
  }

  Color _attendanceColor(String attendance) {
    switch (attendance.toLowerCase()) {
      case 'attended':
      case 'present':     return const Color(0xFF10B981);
      case 'missed':
      case 'absent':
      case 'cancelled':   return const Color(0xFFEF4444);
      case 'rescheduled': return const Color(0xFFF59E0B);
      default:            return const Color(0xFF6366F1); // scheduled
    }
  }

  Widget _buildAnswersExpansionTile(List<ApplicationAnswer> answers, List<Color> gradient) {
    final visible = answers.where((a) => a.displayValue.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: gradient[0].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.quiz_rounded, color: gradient[0], size: 20),
          ),
          title: Text(
            'Your Answers',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${visible.length} ${visible.length == 1 ? 'response' : 'responses'}',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          children: visible.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.displayValue,
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradient[0].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.fieldType.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: gradient[0],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }


  Widget _buildStageHistory(List<StageHistory> history) {
    return Column(
      children: history.map((h) {
        final stageName = h.toStage?.name ?? '';
        final stageCode = h.toStage?.code ?? '';
        final note = h.cleanedNote ?? '';
        final isRejected = stageCode.contains('reject');
        final isSelected = stageCode.contains('select');

        final Color color = isRejected
            ? const Color(0xFFEF4444)
            : isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFF10B981);

        final date = h.changedAt != null
            ? _historyDateFmt.format(h.changedAt!.toLocal())
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              stageName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBasicStatusCard(JobApplication application) {
    final code = application.currentStage?.toLowerCase() ?? '';
    final status = application.applicationStatus?.toLowerCase() ?? '';
    final isRejected = code.contains('reject') || status.contains('reject');
    final isSelected = code.contains('select') || status.contains('select');

    final Color color;
    final IconData icon;
    final String label;
    final String desc;

    if (isRejected) {
      color = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
      label = 'Not Selected';
      desc = 'Thank you for applying. Keep exploring other opportunities.';
    } else if (isSelected) {
      color = const Color(0xFF10B981);
      icon = Icons.verified_rounded;
      label = 'Selected';
      desc = 'Congratulations! You have been selected.';
    } else {
      color = const Color(0xFF10B981);
      icon = Icons.task_alt_rounded;
      label = application.currentStage ?? 'Applied';
      desc = 'Your application has been submitted successfully.';
    }

    return _SectionCard(
      title: 'Application Status',
      icon: Icons.assignment_rounded,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(bool applied, List<Color> gradient) {
    if (_isLoading || _error != null) return null;

    final isExpired = _detail?.job.isExpired ?? false;

    if (applied) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'You have already applied for this position',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              'This job posting has expired',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton(
            onPressed: _openApplySheet,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Apply Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Company avatar (logo → initials fallback) ────────────────────────────────

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({
    required this.name,
    required this.gradient,
    this.logoUrl,
    this.size = 48,
    this.radius = 14,
    this.fontSize = 16,
  });

  final String? logoUrl;
  final String name;
  final List<Color> gradient;
  final double size;
  final double radius;
  final double fontSize;

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials(),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.borderColor.withValues(alpha: 0.5),
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Could not load job details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
