import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/attandance_screen/controller/attandance_controller.dart';
import 'package:luminar_std/repository/attandance_screen/new_model.dart';
import 'package:provider/provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AttendanceProvider>().loadMore();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.statsGreen;
      case 'offline':
        return AppColors.textSecondary;
      case 'recording':
        return AppColors.statsOrange;
      case 'absent':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Icons.wifi_rounded;
      case 'offline':
        return Icons.wifi_off_rounded;
      case 'recording':
        return Icons.videocam_rounded;
      case 'absent':
        return Icons.person_off_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // rebuild on every theme change
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: provider.isLoadingDashboard
                  ? _buildFullLoadingState()
                  : provider.error != null && provider.batches.isEmpty
                  ? _buildErrorState(
                      provider.error!,
                      () => provider.loadDashboard(),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.cardBackground,
                      onRefresh: () => provider.loadDashboard(),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                if (provider.batches.isNotEmpty) ...[
                                  _buildBatchSelector(provider),
                                  if ((provider.selectedBatch?.sessions ?? [])
                                      .isNotEmpty)
                                    _buildSessionSelector(provider),
                                ],
                                if (provider.attendanceData != null)
                                  _buildStatsSection(
                                    provider.attendanceData!.summary,
                                  ),
                                _buildLegend(),
                                _buildRecordsHeader(provider),
                              ],
                            ),
                          ),
                          if (provider.isLoadingAttendance)
                            SliverToBoxAdapter(
                              child: _buildAttendanceLoadingState(),
                            )
                          else if (provider.allRecords.isEmpty)
                            SliverToBoxAdapter(child: _buildEmptyState())
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index < provider.allRecords.length) {
                                    return _buildAttendanceItem(
                                      provider.allRecords[index],
                                    );
                                  }
                                  return _buildLoadMoreIndicator();
                                },
                                childCount:
                                    provider.allRecords.length +
                                    (provider.hasMore ? 1 : 0),
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text('Attendance', style: AppTextStyles.heading2)),

          // Dark / Light mode toggle
        ],
      ),
    );
  }

  // ─── Batch selector ───────────────────────────────────────────────────────

  Widget _buildBatchSelector(AttendanceProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EnrollmentBatch>(
                value: provider.selectedBatch,
                isExpanded: true,
                icon: Icon(Icons.expand_more_rounded, color: AppColors.primary),
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                hint: Text(
                  'Select Batch',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
                items: provider.batches.map((batch) {
                  return DropdownMenuItem<EnrollmentBatch>(
                    value: batch,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          batch.batchName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          batch.courseName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (batch) {
                  if (batch != null) provider.selectBatch(batch);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Session selector ─────────────────────────────────────────────────────

  Widget _buildSessionSelector(AttendanceProvider provider) {
    final sessions = provider.selectedBatch?.sessions ?? [];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.layers_rounded, color: AppColors.statsBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BatchSession?>(
                value: provider.selectedSession,
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.statsBlue,
                ),
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                hint: Text(
                  'All Sessions',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
                items: [
                  DropdownMenuItem<BatchSession?>(
                    value: null,
                    child: Text(
                      'All Sessions',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...sessions.map(
                    (s) => DropdownMenuItem<BatchSession?>(
                      value: s,
                      child: Text(
                        s.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (session) => provider.selectSession(session),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats section ────────────────────────────────────────────────────────

  Widget _buildStatsSection(AttendanceSummary summary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
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
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Attendance Summary',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                'Total',
                summary.totalDays,
                AppColors.primary,
                Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                'Online',
                summary.online,
                AppColors.statsGreen,
                Icons.wifi_rounded,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                'Offline',
                summary.offline,
                AppColors.textSecondary,
                Icons.wifi_off_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatChip(
                'Recording',
                summary.recording,
                AppColors.statsOrange,
                Icons.videocam_rounded,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                'Absent',
                summary.absent,
                AppColors.error,
                Icons.person_off_rounded,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                'Present',
                summary.totalDays - summary.absent,
                AppColors.statsBlue,
                Icons.check_circle_rounded,
              ),
            ],
          ),
          if (summary.totalDays > 0) ...[
            const SizedBox(height: 16),
            _buildAttendanceBar(summary),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBar(AttendanceSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Rate',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                if (summary.online > 0)
                  Flexible(
                    flex: summary.online,
                    child: Container(color: AppColors.statsGreen),
                  ),
                if (summary.offline > 0)
                  Flexible(
                    flex: summary.offline,
                    child: Container(color: AppColors.textSecondary),
                  ),
                if (summary.recording > 0)
                  Flexible(
                    flex: summary.recording,
                    child: Container(color: AppColors.statsOrange),
                  ),
                if (summary.absent > 0)
                  Flexible(
                    flex: summary.absent,
                    child: Container(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(100 - summary.absentPercentage).toStringAsFixed(1)}% present rate',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.statsGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Online', AppColors.statsGreen),
          _buildLegendItem('Offline', AppColors.textSecondary),
          _buildLegendItem('Recording', AppColors.statsOrange),
          _buildLegendItem('Absent', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Records list ─────────────────────────────────────────────────────────

  Widget _buildRecordsHeader(AttendanceProvider provider) {
    if (provider.allRecords.isEmpty && !provider.isLoadingAttendance) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${provider.attendanceData?.count ?? 0} Records',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (provider.attendanceData != null &&
              provider.attendanceData!.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Page ${provider.attendanceData!.currentPage}'
                ' of ${provider.attendanceData!.totalPages}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceRecord record) {
    final statusColor = _getStatusColor(record.status);
    final statusIcon = _getStatusIcon(record.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date,
                  style: AppTextStyles.activityTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatTimestamp(record.timestamp),
                        style: AppTextStyles.activityTime,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (record.reason.isNotEmpty &&
                    record.reason != 'No Remark') ...[
                  const SizedBox(height: 3),
                  Text(
                    record.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.statusDisplay,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading / empty / error states ──────────────────────────────────────

  Widget _buildFullLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Loading attendance…', style: AppTextStyles.bodyText2),
        ],
      ),
    );
  }

  Widget _buildAttendanceLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text('No Records Found', style: AppTextStyles.activityTitle),
          const SizedBox(height: 8),
          Text(
            'No attendance records available for the selected batch and session.',
            style: AppTextStyles.activitySubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: AppTextStyles.activityTitle),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.activitySubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
