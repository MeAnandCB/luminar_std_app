import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';
import 'package:luminar_std/repository/referral_status/model/referred_students_model.dart';
import 'package:luminar_std/repository/referral_status/service/referral_status_service.dart';
import 'package:provider/provider.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/referral_screen/referral_screen.dart';
class ReferralStatusScreen extends StatefulWidget {
  final String studentId;

  const ReferralStatusScreen({super.key, required this.studentId});

  @override
  State<ReferralStatusScreen> createState() => _ReferralStatusScreenState();
}

class _ReferralStatusScreenState extends State<ReferralStatusScreen> {
  final ReferralStatusService _service = ReferralStatusService();

  bool _isLoadingHistory = true;
  ReferredStudentsModel? _historyData;

  bool _isLoadingEnrolled = true;
  ReferredStudentsModel? _enrolledData;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _fetchEnrolled();
  }

  Future<void> _fetchHistory() async {
    if (mounted) setState(() => _isLoadingHistory = true);
    final data = await _service.getReferredStudentsHistory();
    if (mounted) {
      setState(() {
        _historyData = data;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _fetchEnrolled() async {
    if (mounted) setState(() => _isLoadingEnrolled = true);
    final data = await _service.getReferredStudentsEnrolled(widget.studentId);
    if (mounted) {
      setState(() {
        _enrolledData = data;
        _isLoadingEnrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Modern sleek background
        appBar: AppBar(
          title: const Text(
            'Referral Status',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: 'Leads'),
                  Tab(text: 'Enrolled'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabBody(_isLoadingHistory, _historyData, _fetchHistory),
            _buildTabBody(_isLoadingEnrolled, _enrolledData, _fetchEnrolled),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final profile = authProvider.studentData?.profile;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReferralScreen(
                  referrerName: profile?.fullName,
                  referrerPhone: profile?.phone,
                ),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabBody(
    bool isLoading,
    ReferredStudentsModel? data,
    VoidCallback onRetry,
  ) {
    if (isLoading) {
      return _buildShimmerLoading();
    }

    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load referrals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final results = data.results ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderSummary(data.count ?? results.length),
        ),
        if (results.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildStudentCard(results[index]);
              }, childCount: results.length),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderSummary(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Referrals',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.people_alt_rounded,
                size: 80,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Referrals Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your friends to get pocket money...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final profile = authProvider.studentData?.profile;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReferralScreen(
                      referrerName: profile?.fullName,
                      referrerPhone: profile?.phone,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Referral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(ReferredStudent student) {
    Color statusColor;

    if (student.statusColorHex != null && student.statusColorHex!.isNotEmpty) {
      try {
        final hexCode = student.statusColorHex!.replaceAll('#', '');
        statusColor = Color(int.parse('FF$hexCode', radix: 16));
      } catch (e) {
        statusColor = AppColors.primary;
      }
    } else {
      switch (student.status?.toLowerCase()) {
        case 'enrolled':
        case 'success':
        case 'active':
          statusColor = const Color(0xFF10B981); // Vibrant Emerald
          break;
        case 'pending':
        case 'new lead':
          statusColor = const Color(0xFFF59E0B); // Vibrant Amber
          break;
        case 'rejected':
        case 'failed':
          statusColor = const Color(0xFFEF4444); // Vibrant Red
          break;
        default:
          statusColor = AppColors.primary;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    student.name?.isNotEmpty == true
                        ? student.name![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name ?? 'Unknown Student',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.phone != null &&
                          student.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student.phone!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.status?.toUpperCase() ?? 'PENDING',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            if (student.courseName != null ||
                student.qualificationName != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                children: [
                  if (student.courseName != null &&
                      student.courseName!.isNotEmpty) ...[
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              student.courseName!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (student.qualificationName != null &&
                      student.qualificationName!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              student.qualificationName!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (student.createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Added on ${student.createdAt!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerWidget(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }
}
