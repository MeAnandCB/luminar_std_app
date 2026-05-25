import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/exam_screen/model.dart';
import 'package:luminar_std/repository/exam_screen/service.dart';
import 'package:luminar_std/presentation/exam_screen/exam_result_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late Future<ApiResponse<ExamSessionsResponse>> _future;

  /// UIDs that have been tapped this session — treated as "seen" immediately.
  final Set<String> _seenUids = {};

  @override
  void initState() {
    super.initState();
    _future = ExamService().fetchExamSessions();
  }

  void _retry() {
    _seenUids.clear();
    setState(() => _future = ExamService().fetchExamSessions());
  }

  Future<void> _onCardTap(ExamSession session) async {
    final attemptUid = session.attemptUid;

    // Mark seen locally right away so UI updates immediately
    if (!_seenUids.contains(session.uid)) {
      setState(() => _seenUids.add(session.uid));
    }

    // Navigate first so the user isn't blocked
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExamDetailScreen(session: session)),
      );
    }

    // Call visibility API only if there is an attempt to mark
    if (attemptUid != null && attemptUid.isNotEmpty) {
      final payload = {
        'records': [
          {'attempt_uid': attemptUid, 'is_visible_to_student': false},
        ],
      };
      debugPrint('══════════════════════════════════════════');
      debugPrint('📤 VISIBILITY API — session: ${session.uid}');
      debugPrint('   Payload: $payload');

      final response = await ExamService().markVisibility(
        sessionUid: session.uid,
        attemptUid: attemptUid,
        isVisibleToStudent: false,
      );

      if (!mounted) return; // widget may have been disposed during the await

      debugPrint('📥 VISIBILITY API — response:');
      debugPrint('   success : ${response.success}');
      debugPrint('   status  : ${response.statusCode}');
      debugPrint('   data    : ${response.data}');
      debugPrint('   message : ${response.message}');
      debugPrint('══════════════════════════════════════════');
    } else {
      debugPrint('⚠️  VISIBILITY API skipped — no attemptUid for session ${session.uid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exam Results',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<ApiResponse<ExamSessionsResponse>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.success ||
              snapshot.data!.data == null) {
            return _ErrorState(onRetry: _retry);
          }

          final sessions = snapshot.data!.data!.data;

          if (sessions.isEmpty) {
            return _EmptyState();
          }

          final unreadCount = sessions
              .where((s) =>
                  !s.isVisibleToStudent && !_seenUids.contains(s.uid))
              .length;
          final hasUnread = unreadCount > 0;

          return Column(
            children: [
              // Count header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    // Total exams pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${sessions.length} Exam${sessions.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      // Unread count — highlighted
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$unreadCount New',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final isNew = !sessions[i].isVisibleToStudent &&
                        !_seenUids.contains(sessions[i].uid);
                    return _ExamCard(
                      session: sessions[i],
                      isNew: isNew,
                      onTap: () => _onCardTap(sessions[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exam card
// ─────────────────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.session,
    required this.onTap,
    required this.isNew,
  });
  final ExamSession session;
  final VoidCallback onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(session.examType?.code);
    final statusColor = _statusColor(session.status);
    final dateStr = session.scheduledDate != null
        ? DateFormat(
            'dd MMM yyyy • hh:mm a',
          ).format(session.scheduledDate!.toLocal())
        : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: isNew
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge with unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      Icon(Icons.assignment_rounded, color: typeColor, size: 22),
                ),
                if (isNew)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exam name + NEW badge + status chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.examName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      _StatusChip(status: session.status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Exam type + module
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (session.examType != null)
                        _Tag(label: session.examType!.name, color: typeColor),
                      if (session.module != null)
                        _Tag(
                          label: session.module!.name,
                          color: AppColors.statsOrange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Course name
                  Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.batch?.courseName ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String? code) {
    switch (code) {
      case 'FINAL':
        return const Color(0xFF6C63FF);
      case 'MOCK':
        return AppColors.statsOrange;
      default:
        return AppColors.primary;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return AppColors.statsGreen;
      case 'draft':
        return AppColors.textHint;
      case 'active':
        return AppColors.primary;
      default:
        return AppColors.textHint;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
    ),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.assignment_outlined, size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        Text(
          'No exam sessions found',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 56, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          'Failed to load exams',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
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
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail screen
// ─────────────────────────────────────────────────────────────────────────────

class ExamDetailScreen extends StatelessWidget {
  const ExamDetailScreen({super.key, required this.session});
  final ExamSession session;

  @override
  Widget build(BuildContext context) {
    final typeColor = session.examType?.code == 'FINAL'
        ? const Color(0xFF6C63FF)
        : session.examType?.code == 'MOCK'
        ? AppColors.statsOrange
        : AppColors.primary;

    final dateStr = session.scheduledDate != null
        ? DateFormat(
            'EEEE, dd MMMM yyyy',
          ).format(session.scheduledDate!.toLocal())
        : '—';
    final timeStr = session.scheduledDate != null
        ? DateFormat('hh:mm a').format(session.scheduledDate!.toLocal())
        : '—';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exam Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.examType?.name ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    session.examName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (session.module != null)
                    Text(
                      'Module: ${session.module!.name} (${session.module!.code})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Schedule card
            _SectionCard(
              title: 'Schedule',
              icon: Icons.calendar_today_rounded,
              children: [
                _DetailRow(label: 'Date', value: dateStr),
                _DetailRow(label: 'Time', value: timeStr),
              ],
            ),

            const SizedBox(height: 12),

            // Batch card
            if (session.batch != null)
              _SectionCard(
                title: 'Batch',
                icon: Icons.school_rounded,
                children: [
                  _DetailRow(label: 'Batch', value: session.batch!.batchName),
                  _DetailRow(label: 'Course', value: session.batch!.courseName),
                ],
              ),


            if (session.instructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Instructions',
                icon: Icons.info_outline_rounded,
                children: [
                  Text(
                    session.instructions,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
            
            if (session.canOpenResult && session.attemptUid != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamResultScreen(
                          attemptUid: session.attemptUid!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Exam Result',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
