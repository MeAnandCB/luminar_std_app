import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/attandance_screen/attandance_screen.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/gallery_screen/views/gallery_screen.dart';
import 'package:luminar_std/presentation/live_class/view/live_class.dart';
import 'package:luminar_std/presentation/payment_screen/payment_screen.dart';
import 'package:luminar_std/presentation/test_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

// ─── palette ─────────────────────────────────────────────────────────────────
// ─── palette ─────────────────────────────────────────────────────────────────
final Color _kPrimary = AppColors.primary;
final Color _kPrimaryB = AppColors.primaryLight;

final _kHeaderGradient = LinearGradient(
  colors: [_kPrimary, _kPrimaryB],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── feature model ───────────────────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color colorA;
  final Color colorB;
  const _Feature(
    this.icon,
    this.title,
    this.subtitle,
    this.colorA,
    this.colorB,
  );
}

const _kFeatures = [
  _Feature(
    Icons.calendar_month_rounded,
    'Attendance',
    'Track your daily class attendance',
    Color(0xFF6C63FF),
    Color(0xFF9D73FF),
  ),
  _Feature(
    Icons.video_collection_rounded,
    'Recorded Videos',
    'Watch your recorded class videos',
    Color(0xFF3B82F6),
    Color(0xFF60A5FA),
  ),
  _Feature(
    Icons.videocam_rounded,
    'Live Class',
    'Join your live class instantly',
    Color(0xFF10B981),
    Color(0xFF34D399),
  ),
  _Feature(
    Icons.payment_rounded,
    'Payment',
    'Track and manage your fee payments',
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ),
  _Feature(
    Icons.payment_rounded,
    'Empty screens',
    'Track and manage your fee payments',
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class MoreEnrollmentScreen extends StatefulWidget {
  const MoreEnrollmentScreen({super.key});

  @override
  State<MoreEnrollmentScreen> createState() => _MoreEnrollmentScreenState();
}

class _MoreEnrollmentScreenState extends State<MoreEnrollmentScreen>
    with TickerProviderStateMixin {
  // Use TickerProviderStateMixin (not Single…) because we may rebuild the
  // TabController when data arrives.
  late final EnrollmentProvider _provider;
  TabController? _tabController;
  bool _loading = true;

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<EnrollmentProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ── data ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    await _provider.fetchEnrollData(context: context);
    _rebuildTabController();
    if (mounted) setState(() => _loading = false);
  }

  void _rebuildTabController() {
    _tabController?.dispose();
    _tabController = null;

    final count = _provider.enrollmentDataRes?.enrollments.length ?? 0;
    if (count > 1 && mounted) {
      _tabController = TabController(length: count, vsync: this)
        ..addListener(() {
          if (!_tabController!.indexIsChanging) setState(() {});
        });
    }
  }

  // ── shorthand ────────────────────────────────────────────────────────────────

  bool get _hasTabs =>
      (_provider.enrollmentDataRes?.enrollments.length ?? 0) > 1 &&
      _tabController != null;

  // ── root ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // Rebuild on theme change
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      // Column keeps the header fixed; the body below is scrollable per tab.
      body: Column(
        children: [
          _Header(
            loading: _loading,
            hasTabs: _hasTabs,
            tabController: _tabController,
            enrollments: _provider.enrollmentDataRes?.enrollments ?? [],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── body ─────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_loading) return _ShimmerBody();

    final enrollments = _provider.enrollmentDataRes?.enrollments ?? [];
    if (enrollments.isEmpty) return const _EmptyState();

    // Single enrollment – no TabBarView needed
    if (!_hasTabs) {
      return _EnrollmentPage(
        enrollment: enrollments[0],
        index: 0,
        provider: _provider,
      );
    }

    // Multiple enrollments – TabBarView handles swipe & sync with TabBar
    return TabBarView(
      controller: _tabController,
      children: List.generate(
        enrollments.length,
        (i) => _EnrollmentPage(
          enrollment: enrollments[i],
          index: i,
          provider: _provider,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER  (gradient bar + optional tab bar)
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.loading,
    required this.hasTabs,
    required this.tabController,
    required this.enrollments,
  });

  final bool loading;
  final bool hasTabs;
  final TabController? tabController;
  final List enrollments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: _kHeaderGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── title row ───────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 18,
                    child: Icon(
                      Icons.school_rounded,
                      color: AppColors.textWhite,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Learning',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Track your progress',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textWhite.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── tab bar or shimmer ───────────────────────────────────────────
            if (loading)
              _ShimmerTabBar()
            else if (hasTabs)
              _TabBar(controller: tabController!, enrollments: enrollments),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR  (pill style, auto-scroll when needed)
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller, required this.enrollments});

  final TabController controller;
  final List enrollments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: LayoutBuilder(
        builder: (context, box) {
          final count = enrollments.length;
          final available = box.maxWidth;
          final minTabW = 80.0;
          final needsScroll = (available / count) < minTabW;

          return Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: TabBar(
              controller: controller,
              isScrollable: needsScroll,
              // fill width when all tabs fit; start-align when scrollable
              tabAlignment: needsScroll
                  ? TabAlignment.start
                  : TabAlignment.fill,
              padding: EdgeInsets.all(4),
              // remove horizontal padding so label controls the width
              labelPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelColor: _kPrimary,
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              indicator: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: List.generate(count, (i) {
                final raw = enrollments[i].course?.courseName ?? 'Course';
                // When scrollable, cap at 14 chars to keep tab compact
                final label = needsScroll && raw.length > 14
                    ? '${raw.substring(0, 13)}…'
                    : raw;
                return Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENROLLMENT PAGE  (course card + feature list)
// ─────────────────────────────────────────────────────────────────────────────

class _EnrollmentPage extends StatelessWidget {
  const _EnrollmentPage({
    required this.enrollment,
    required this.index,
    required this.provider,
  });

  final dynamic enrollment;
  final int index;
  final EnrollmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final batchId = enrollment.batch?.uid ?? '';
    final batchName = enrollment.batch?.batchName ?? 'Batch';
    final enrollId = enrollment.uid ?? '';
    final courseName = enrollment.course?.courseName ?? '';
    final mode = enrollment.attendanceMode?.name ?? '';
    final status = enrollment.status?.value ?? '';

    final bool toEnrollDetails =
        status == 'admission_fee_paid' ||
        status == 'not_set' ||
        status == 'demo_expired';

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // course info card
        SliverToBoxAdapter(
          child: _CourseInfoCard(
            courseName: courseName,
            batchName: batchName,
            mode: mode,
          ),
        ),

        // section header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kPrimary, _kPrimaryB],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '4 features',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // feature cards
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _FeatureCard(
                feature: _kFeatures[0],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceScreen(
                      batchId: batchId,
                      batchName: batchName,
                      courseName: courseName,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              _FeatureCard(
                feature: _kFeatures[1],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalleryScreen(batchId: batchId),
                  ),
                ),
              ),
              SizedBox(height: 12),
              _FeatureCard(
                feature: _kFeatures[2],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DemoScreen()),
                ),
              ),
              SizedBox(height: 12),
              _FeatureCard(
                feature: _kFeatures[2],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LiveClassScreen()),
                ),
              ),
              SizedBox(height: 12),
              _FeatureCard(
                feature: _kFeatures[3],
                onTap: toEnrollDetails
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnrollmentDetailsScreen(
                            index: index,
                            backbuttonValue: true,
                          ),
                        ),
                      )
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            enrollmentId: enrollId,
                            uid: enrollment.uid ?? '',
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSE INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CourseInfoCard extends StatelessWidget {
  const _CourseInfoCard({
    required this.courseName,
    required this.batchName,
    required this.mode,
  });

  final String courseName;
  final String batchName;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimaryB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
          ),
          SizedBox(width: 14),
          // texts – Expanded stops overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Chip(icon: Icons.groups_rounded, label: batchName),
                    _Chip(icon: Icons.wifi_rounded, label: mode),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.35,
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textWhite),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final _Feature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: feature.colorA.withOpacity(0.08),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: feature.colorA.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // gradient icon box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [feature.colorA, feature.colorB],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    feature.icon,
                    color: AppColors.textWhite,
                    size: 22,
                  ),
                ),
                SizedBox(width: 14),
                // title + subtitle – Expanded prevents overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        feature.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.75),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // arrow button
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: feature.colorA.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: feature.colorA,
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

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPrimaryB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.school_rounded, size: 48, color: Colors.white),
            ),
            SizedBox(height: 28),
            Text(
              'No Enrollments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'You haven\'t enrolled in any courses yet.\nBrowse and start your learning journey today!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.7),
                height: 1.6,
              ),
            ),
            SizedBox(height: 32),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPrimaryB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Browse Courses',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Shimmer.fromColors(
        baseColor: AppColors.white.withOpacity(0.1),
        highlightColor: AppColors.white.withOpacity(0.2),
        child: Row(
          children: List.generate(
            3,
            (i) => Container(
              margin: EdgeInsets.only(right: 8),
              width: 88,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          // course card skeleton
          Shimmer.fromColors(
            baseColor: AppColors.isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: AppColors.isDark
                ? Colors.grey[700]!
                : Colors.grey[100]!,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          SizedBox(height: 20),
          // feature card skeletons
          ...List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Shimmer.fromColors(
                baseColor: AppColors.isDark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
                highlightColor: AppColors.isDark
                    ? Colors.grey[700]!
                    : Colors.grey[100]!,
                child: Container(
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
