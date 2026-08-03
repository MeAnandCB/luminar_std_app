import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/class_task/views/task_detail_screen.dart';
import 'package:luminar_std/repository/class_task/class_task_model.dart';
import 'package:luminar_std/repository/class_task/class_task_service.dart';
import 'package:shimmer/shimmer.dart';

class ClassTaskScreen extends StatefulWidget {
  final String? batchUid;
  final String? batchName;

  const ClassTaskScreen({
    super.key,
    this.batchUid,
    this.batchName,
  });

  @override
  State<ClassTaskScreen> createState() => _ClassTaskScreenState();
}

class _ClassTaskScreenState extends State<ClassTaskScreen> {
  final ClassTaskService _service = ClassTaskService();

  List<StudentAssignment> _assignments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'ALL'; // ALL, PENDING, SUBMITTED, FAILED, PASSED

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await _service.getMyTasks(batchUid: widget.batchUid);

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _assignments = res.data!.assignments;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load class tasks';
        _isLoading = false;
      });
    }
  }

  String _getEffectiveStatus(StudentAssignment a) {
    final status = a.status.toUpperCase();
    final lastVer =
        (a.lastVerificationResult ?? a.latestSubmission?.verificationStatus ?? '')
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

  List<StudentAssignment> get _filteredAssignments {
    if (_selectedFilter == 'PENDING') {
      return _assignments
          .where((a) => _getEffectiveStatus(a) == 'NOT_SUBMITTED')
          .toList();
    } else if (_selectedFilter == 'SUBMITTED') {
      return _assignments
          .where((a) => _getEffectiveStatus(a) == 'SUBMITTED')
          .toList();
    } else if (_selectedFilter == 'FAILED') {
      return _assignments
          .where((a) => _getEffectiveStatus(a) == 'FAILED')
          .toList();
    } else if (_selectedFilter == 'PASSED') {
      return _assignments
          .where((a) => _getEffectiveStatus(a) == 'PASSED')
          .toList();
    }
    return _assignments;
  }

  int get _pendingCount =>
      _assignments.where((a) => _getEffectiveStatus(a) == 'NOT_SUBMITTED').length;
  int get _submittedCount =>
      _assignments.where((a) => _getEffectiveStatus(a) == 'SUBMITTED').length;
  int get _failedCount =>
      _assignments.where((a) => _getEffectiveStatus(a) == 'FAILED').length;
  int get _passedCount =>
      _assignments.where((a) => _getEffectiveStatus(a) == 'PASSED').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Class Tasks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            if (widget.batchName != null && widget.batchName!.isNotEmpty)
              Text(
                widget.batchName!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
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
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        color: AppColors.primary,
        child: Column(
          children: [
            // Premium Header with Stats Banner
            _buildHeaderBanner(),

            // Filter Tabs
            _buildFilterTabs(),

            // Tasks List
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _error != null
                      ? _buildErrorWidget()
                      : _filteredAssignments.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                              itemCount: _filteredAssignments.length,
                              itemBuilder: (context, index) {
                                final assignment = _filteredAssignments[index];
                                return _buildTaskCard(assignment);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatMetric(
                  'Total',
                  '${_assignments.length}',
                  Colors.white,
                  Icons.assignment_outlined,
                ),
                _buildDivider(),
                _buildStatMetric(
                  'Pending',
                  '$_pendingCount',
                  const Color(0xFFFCD34D),
                  Icons.pending_actions_rounded,
                ),
                _buildDivider(),
                _buildStatMetric(
                  'Submitted',
                  '$_submittedCount',
                  const Color(0xFF60A5FA),
                  Icons.hourglass_top_rounded,
                ),
                _buildDivider(),
                _buildStatMetric(
                  'Failed',
                  '$_failedCount',
                  const Color(0xFFFCA5A5),
                  Icons.warning_amber_rounded,
                ),
                _buildDivider(),
                _buildStatMetric(
                  'Passed',
                  '$_passedCount',
                  const Color(0xFF34D399),
                  Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatMetric(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterPill('ALL', 'All (${_assignments.length})', Icons.dashboard_rounded),
          _buildFilterPill('PENDING', 'Pending ($_pendingCount)', Icons.timer_outlined),
          _buildFilterPill('SUBMITTED', 'Submitted ($_submittedCount)', Icons.send_rounded),
          _buildFilterPill('FAILED', 'Failed ($_failedCount)', Icons.cancel_outlined),
          _buildFilterPill('PASSED', 'Passed ($_passedCount)', Icons.verified_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, IconData icon) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = key;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(StudentAssignment assignment) {
    final task = assignment.task;
    final effectiveStatus = _getEffectiveStatus(assignment);

    Color gradientStart;
    Color gradientEnd;
    String statusLabel;
    IconData statusIcon;

    switch (effectiveStatus) {
      case 'PASSED':
        gradientStart = const Color(0xFF059669);
        gradientEnd = const Color(0xFF34D399);
        statusLabel = 'PASSED';
        statusIcon = Icons.verified_rounded;
        break;
      case 'SUBMITTED':
        gradientStart = const Color(0xFF2563EB);
        gradientEnd = const Color(0xFF60A5FA);
        statusLabel = 'UNDER REVIEW';
        statusIcon = Icons.hourglass_bottom_rounded;
        break;
      case 'FAILED':
        gradientStart = const Color(0xFFDC2626);
        gradientEnd = const Color(0xFFF87171);
        statusLabel = 'FAILED';
        statusIcon = Icons.highlight_off_rounded;
        break;
      case 'NOT_SUBMITTED':
      default:
        gradientStart = const Color(0xFFD97706);
        gradientEnd = const Color(0xFFFBBF24);
        statusLabel = 'PENDING';
        statusIcon = Icons.pending_actions_rounded;
        break;
    }

    String formattedDue = 'No due date';
    bool isOverdue = false;

    if (task.dueAt != null && task.dueAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(task.dueAt!).toLocal();
        formattedDue = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        if (effectiveStatus == 'NOT_SUBMITTED' && dt.isBefore(DateTime.now())) {
          isOverdue = true;
        }
      } catch (_) {
        formattedDue = task.dueAt!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Gradient Bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Main Card Content
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(
                            assignment: assignment,
                            batchName: widget.batchName,
                            onTaskUpdated: _loadTasks,
                          ),
                        ),
                      );
                      _loadTasks();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      gradientStart.withValues(alpha: 0.15),
                                      gradientEnd.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.assignment_rounded,
                                  color: gradientStart,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (task.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        task.description,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),

                          // Footer Info Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Due Date Badge
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 14,
                                        color: isOverdue
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        formattedDue,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isOverdue
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isOverdue
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Status Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          gradientStart.withValues(alpha: 0.12),
                                          gradientEnd.withValues(alpha: 0.12),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: gradientStart.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 12,
                                          color: gradientStart,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: gradientStart,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Attempts Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Attempts: ${assignment.attemptsUsed}/${assignment.maxAttempts}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.white,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    String displayMsg = _error ?? 'Failed to load tasks';
    if (displayMsg.contains('Module student_tasks not found') ||
        displayMsg.contains('not found')) {
      displayMsg = 'No class tasks assigned yet for your batch.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Class Tasks Available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primaryLight.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Class Tasks Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Assigned class tasks and homework will appear here for your batch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
