import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/job_community/views/community_detail_screen.dart';
import 'package:luminar_std/repository/job_community/job_community_model.dart';
import 'package:luminar_std/repository/job_community/job_community_service.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final _service = JobCommunityService();

  bool _loading = true;
  String? _error;
  List<JobCommunity> _communities = [];

  static const List<List<Color>> _gradients = [
    [Color(0xFF533483), Color(0xFF7B52AB)],
    [Color(0xFF0F3460), Color(0xFF1A6FA0)],
    [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    [Color(0xFF6D1E1E), Color(0xFFA03434)],
    [Color(0xFF1A1A5E), Color(0xFF2D2DA0)],
  ];

  List<Color> _gradientFor(String name) {
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % _gradients.length;
    return _gradients[idx];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.getMyCommunities();
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _communities = res.data!.results;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load communities';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Job Community',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Try again')),
          ),
        ],
      );
    }
    if (_communities.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.groups_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No communities yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              "You'll see your job communities here once you join one.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _communities.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 78,
        color: AppColors.borderColor.withValues(alpha: 0.4),
      ),
      itemBuilder: (context, index) => _CommunityRow(
        community: _communities[index],
        gradient: _gradientFor(_communities[index].name),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityDetailScreen(community: _communities[index]),
          ),
        ),
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.community,
    required this.gradient,
    required this.onTap,
  });

  final JobCommunity community;
  final List<Color> gradient;
  final VoidCallback onTap;

  String _initials() {
    final parts = community.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get _subtitle {
    final batch = community.activeBatches.isNotEmpty
        ? community.activeBatches.first.batchName
        : community.courseName;
    final memberPart = '${community.memberCount} members';
    return batch.isEmpty ? memberPart : '$batch · $memberPart';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
