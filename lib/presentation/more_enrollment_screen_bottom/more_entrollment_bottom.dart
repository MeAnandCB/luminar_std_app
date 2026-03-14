import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/attandance_screen/attandance_screen.dart';
import 'package:luminar_std/presentation/live_class/live_class.dart';
import 'package:luminar_std/presentation/payment_screen/payment_screen.dart';
import 'package:luminar_std/presentation/recorder_video_screen/recorder_video_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class MoreEnrollmentScreen extends StatefulWidget {
  const MoreEnrollmentScreen({super.key});

  @override
  State<MoreEnrollmentScreen> createState() => _MoreEnrollmentScreenState();
}

class _MoreEnrollmentScreenState extends State<MoreEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  late EnrollmentProvider enrollmentProvider;
  TabController? _tabController;
  int _selectedCourseIndex = 0;
  bool _isInitialLoading = true;

  // Selected course data
  Map<String, dynamic> _selectedCourse = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      enrollmentProvider = Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      );
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitialLoading = true;
    });

    await enrollmentProvider.fetchEnrollData(context: context);

    // Initialize TabController after data is loaded
    if (enrollmentProvider.enrollmentDataRes != null && mounted) {
      final enrollments = enrollmentProvider.enrollmentDataRes!.enrollments;

      if (enrollments.isNotEmpty) {
        _tabController = TabController(
          length: enrollments.length,
          vsync: this,
          initialIndex: 0,
        );

        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            setState(() {
              _selectedCourseIndex = _tabController!.index;
              _updateSelectedCourse(_selectedCourseIndex);
            });
          }
        });

        // Set initial selected course
        _updateSelectedCourse(0);
      }
    }

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _updateSelectedCourse(int index) {
    final enrollments = enrollmentProvider.enrollmentDataRes?.enrollments;
    if (enrollments == null ||
        enrollments.isEmpty ||
        index >= enrollments.length)
      return;

    setState(() {
      _selectedCourse = {
        'id': enrollments[index].uid ?? '',
        'batchId': enrollments[index].batch?.uid ?? '',
        'name': enrollments[index].course?.courseName ?? "Course Name",
        'batch': enrollments[index].batch?.batchName ?? "Batch Name",
        'mode': enrollments[index].attendanceMode?.name ?? "Regular",
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: const Text(
          'My Learning',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Consumer<EnrollmentProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading || _isInitialLoading) {
                return _buildShimmerTabBar();
              }

              if (provider.enrollmentDataRes == null) {
                return const SizedBox(height: 60);
              }

              final enrollments = provider.enrollmentDataRes!.enrollments;

              if (enrollments.isEmpty || _tabController == null) {
                return const SizedBox(height: 60);
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: AppColors.primaryGradient,
                      ),
                      dividerColor: Colors.transparent,
                      tabAlignment: TabAlignment.start,
                      padding: const EdgeInsets.all(4),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 15),
                      tabs: enrollments.map((enrollment) {
                        final courseName =
                            enrollment.course?.courseName ?? "Course";
                        // Get first word or shorten long names
                        String displayName = courseName.split(' ').first;
                        if (courseName.length > 15) {
                          displayName = '${courseName.substring(0, 20)}...';
                        }

                        return Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(
                        provider.enrollmentDataRes?.enrollments?.length != null
                            ? (provider.enrollmentDataRes!.enrollments!.length >
                                      3
                                  ? 3
                                  : provider
                                        .enrollmentDataRes!
                                        .enrollments!
                                        .length)
                            : 0,
                        (index) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: _isInitialLoading
            ? _buildShimmerFullScreen()
            : enrollmentProvider.enrollmentDataRes == null ||
                  enrollmentProvider.enrollmentDataRes!.enrollments.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  // Selected Course Info (square corners)
                  if (_selectedCourse.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCourse['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedCourse['batch']} • ${_selectedCourse['mode']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // More Menu Screen with ListView (Square corners)
                  Expanded(child: _buildMoreMenuScreen(_selectedCourseIndex)),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmerTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerFullScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Shimmer for course info
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.all(12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                children: [
                  Container(width: 40, height: 40, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(width: 150, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Shimmer for menu screen
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            color: Colors.white,
            child: Column(
              children: [
                // Header shimmer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 100,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        Container(width: 80, height: 24, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                // List items shimmer
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 80,
                            color: Colors.white,
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.all(10),
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 80,
                                        height: 12,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerMenuLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          // Header shimmer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(width: 100, height: 16, color: Colors.white),
                  ],
                ),
                Container(width: 80, height: 24, color: Colors.white),
              ],
            ),
          ),

          // List items shimmer
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 80,
                  color: Colors.white,
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.all(10),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Enrollments Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You haven\'t enrolled in any courses yet. Browse our courses and start learning today!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Navigate to browse courses
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // Square corners
              ),
            ),
            child: const Text(
              'Browse Courses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenuScreen(int index) {
    return Consumer<EnrollmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildShimmerMenuLoading();
        }

        final enrollments = provider.enrollmentDataRes?.enrollments;
        if (enrollments == null ||
            enrollments.isEmpty ||
            index >= enrollments.length) {
          return const SizedBox();
        }

        final currentEnrollment = enrollments[index];
        final batchId = currentEnrollment.batch?.uid ?? '';
        final batchName = currentEnrollment.batch?.batchName ?? 'Batch';
        final enrollmentId = currentEnrollment.uid ?? '';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              // Section Header (square corners)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        '6 features',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Features List
              Expanded(
                child: Column(
                  children: [
                    MoreCard(
                      icon: Icons.calendar_month_rounded,
                      title: "Attandance",
                      subtitle: "subtitle",
                      color: const Color(0xFF6C5CE7),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AttendanceScreen(batchId: batchId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              //   ListView(
              //     padding: const EdgeInsets.symmetric(horizontal: 20),
              //     children: [
              //       const SizedBox(height: 12),
              //       _buildFeatureItem(
              //         icon: Icons.calendar_month_rounded,
              //         title: 'Attendance',
              //         subtitle: 'Track daily attendance',
              //         color: const Color(0xFF6C5CE7),
              //         badge: _getAttendanceBadge(),
              //         onTap: () => _navigateToAttendance(
              //           batchId: batchId,
              //           batchName: batchName,
              //         ),
              //       ),
              //       const SizedBox(height: 12),
              //       _buildFeatureItem(
              //         icon: Icons.video_library_rounded,
              //         title: 'Videos',
              //         subtitle: 'Course recordings',
              //         color: const Color(0xFF00B894),
              //         badge: '12 new',
              //         onTap: () => _navigateToVideos(),
              //       ),
              //       const SizedBox(height: 12),
              //       _buildFeatureItem(
              //         icon: Icons.payment_rounded,
              //         title: 'Payments',
              //         subtitle: 'Fee details',
              //         color: const Color(0xFFF39C12),
              //         badge: 'Paid',
              //         onTap: () => _navigateToPayments(),
              //       ),
              //       const SizedBox(height: 12),
              //       _buildFeatureItem(
              //         icon: Icons.video_camera_front_rounded,
              //         title: 'Live Class',
              //         subtitle: 'Join now',
              //         color: const Color(0xFFFF7675),
              //         badge: 'LIVE',
              //         onTap: () => _navigateToLiveClass(),
              //       ),
              //       const SizedBox(height: 12),
              //       _buildFeatureItem(
              //         icon: Icons.assignment_rounded,
              //         title: 'Assignments',
              //         subtitle: 'Pending tasks',
              //         color: const Color(0xFF0984E3),
              //         badge: '3',
              //         onTap: () => _showComingSoon('Assignments'),
              //       ),
              //       const SizedBox(height: 12),
              //       _buildFeatureItem(
              //         icon: Icons.quiz_rounded,
              //         title: 'Tests',
              //         subtitle: 'Upcoming exams',
              //         color: const Color(0xFFE84393),
              //         badge: '2',
              //         onTap: () => _showComingSoon('Tests'),
              //       ),
              //       const SizedBox(height: 20),
              //     ],
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  //   String _getAttendanceBadge() {
  //     // This would come from your actual data
  //     return '85%';
  //   }

  //   void _navigateToAttendance({
  //     required String batchId,
  //     required String batchName,
  //   }) {
  //     if (_selectedCourse.isEmpty) return;

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => AttendanceScreen(
  //           batchId:
  //               enrollmentProvider?.enrollmentDataRes?.enrollments[0].uid ?? "",
  //         ),
  //       ),
  //     );
  //   }

  //   void _navigateToVideos() {
  //     if (_selectedCourse.isEmpty) return;
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const VideosScreen()),
  //     );
  //   }

  //   void _navigateToPayments() {
  //     if (_selectedCourse.isEmpty) return;
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const PaymentsScreen()),
  //     );
  //   }

  //   void _navigateToLiveClass() {
  //     if (_selectedCourse.isEmpty) return;
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const LiveClassScreen()),
  //     );
  //   }

  //   void _showComingSoon(String feature) {
  //     if (_selectedCourse.isEmpty) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '$feature feature coming soon for ${_selectedCourse['name'] ?? 'this course'}!',
  //         ),
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  //       ),
  //     );
  //   }
}

class MoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  final VoidCallback onTap;

  const MoreCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,

    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with background (square corners)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),

                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary.withOpacity(0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
