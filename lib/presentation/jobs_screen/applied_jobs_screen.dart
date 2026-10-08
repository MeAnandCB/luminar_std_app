import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/jobs_screen/job_detail_screen.dart';
import 'package:luminar_std/repository/jobs/model/job_notification_model.dart';
import 'package:luminar_std/repository/jobs/service/jobs_service.dart';

final _dateFmt = DateFormat('MMM d, y');

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({super.key});

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['active', 'withdrawn'];

  final JobsService _service = JobsService();
  late final TabController _tabController;

  final Map<String, List<MyApplicationItem>> _items = {};
  final Map<String, String?> _errors = {};
  final Set<String> _loading = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    for (final t in _tabs) {
      _load(t);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load(String status) async {
    setState(() {
      _loading.add(status);
      _errors.remove(status);
    });
    final res = await _service.getMyApplications(status: status);
    if (!mounted) return;
    setState(() {
      _loading.remove(status);
      if (res.success && res.data != null) {
        _items[status] = res.data!.results;
      } else {
        _errors[status] = res.message ?? 'Failed to load applications';
      }
    });
  }

  Future<void> _open(MyApplicationItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          jobUid: item.jobUid,
          notification: item.toNotification(),
        ),
      ),
    );
    if (!mounted) return;
    for (final t in _tabs) {
      _load(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text(
          'Applied Jobs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Withdrawn')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [for (final t in _tabs) _buildTab(t)],
      ),
    );
  }

  Widget _buildTab(String status) {
    if (_loading.contains(status) && !_items.containsKey(status)) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _errors[status];
    if (error != null && !_items.containsKey(status)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _load(status),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final items = _items[status] ?? const [];
    return RefreshIndicator(
      onRefresh: () => _load(status),
      child: items.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      status == 'active'
                          ? 'No active applications'
                          : 'No withdrawn applications',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ApplicationTile(
                item: items[i],
                onTap: () => _open(items[i]),
              ),
            ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.item, required this.onTap});

  final MyApplicationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.isActive ? const Color(0xFF10B981) : Colors.orange;
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.isActive
                          ? (item.currentStageName ?? 'Active')
                          : 'Withdrawn',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.companyName,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.appliedAt != null)
                    Text(
                      'Applied ${_dateFmt.format(item.appliedAt!.toLocal())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (item.upcomingInterviewsCount > 0) ...[
                    const Spacer(),
                    const Icon(Icons.event_rounded,
                        size: 14, color: Color(0xFF533483)),
                    const SizedBox(width: 4),
                    Text(
                      '${item.upcomingInterviewsCount} upcoming interview'
                      '${item.upcomingInterviewsCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF533483),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
