import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_config.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:luminar_std/presentation/home_screen/widget/natet_certificate.dart';
import 'package:luminar_std/presentation/enrollment_screen/view/entrollment_screen.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';

import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/profile_screen/profile_screen.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/home_screen/widget/header_card.dart';
import 'package:luminar_std/presentation/global_widget/festival_overlay.dart';
import 'package:luminar_std/presentation/home_screen/widget/top_status_card.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/instagram_view_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:luminar_std/presentation/nactet_registration/view/nactet_registration_screen.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_check_display_model.dart';
import 'package:luminar_std/presentation/jobs_screen/jobs_screen.dart';
import 'package:luminar_std/presentation/referral_screen/referral_screen.dart';
import 'package:luminar_std/presentation/home_screen/widget/onam_event_card.dart';
import 'package:luminar_std/presentation/home_screen/widget/birthday_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _displayName = 'Loading...';
  bool _showInstaSection = true;

  @override
  void initState() {
    super.initState();
    // Data is fetched by BottomNavScreen._loadData() — no duplicate calls here.
    // Only load the display name once the frame is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserName();
    });
  }

  Future<void> _loadUserName() async {
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final name = authProvider.studentData?.profile.fullName ?? 'Guest';
      if (name != _displayName) {
        setState(() {
          _displayName = name;
        });
      }
      LoggerUtils.info('📝 Name loaded: $_displayName', tag: 'Dashboard');
    }
  }

  String _formatCurrency(int? amount) {
    if (amount == null) return '₹0';
    return '₹${NumberFormat('#,##,###').format(amount)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final dashboardProvider = Provider.of<DashboardController>(context);
    final profileProvider = Provider.of<ProfileController>(context);
    final dashboard = dashboardProvider.dashboard;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Get student name directly from provider — no setState needed
        final studentName =
            (authProvider.studentData?.profile.fullName ?? '').isNotEmpty
            ? authProvider.studentData!.profile.fullName
            : _displayName;

        final themeInfo = FestivalDateManager.getCurrentThemeInfo();

        return FestivalOverlay(
          theme: themeInfo.theme,
          titleOverride: themeInfo.titleOverride,
          defaultBackgroundColor: AppColors.scaffoldBackground,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: dashboardProvider.isLoading
                ? const DashboardShimmer()
                : dashboardProvider.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppUtils.friendlyError(
                                  dashboardProvider.error!,
                                ).contains('internet')
                                ? Icons.wifi_off_rounded
                                : Icons.error_outline_rounded,
                            size: 72,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppUtils.friendlyError(
                                  dashboardProvider.error!,
                                ).contains('internet')
                                ? 'No Internet Connection'
                                : 'Something Went Wrong',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headerName.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppUtils.friendlyError(dashboardProvider.error!),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.activitySubtitle,
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () => dashboardProvider.refreshDashboard(
                              context: context,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size(180, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : AppColors.variant == AppThemeVariant.ocean
                    ? _buildOceanBody(
                        dashboard: dashboard,
                        studentName: studentName,
                        dashboardProvider: dashboardProvider,
                        profileProvider: profileProvider,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        HeaderWidget(
                          courseName:
                              dashboard
                                      ?.enrollmentDetails
                                      ?.enrollments
                                      ?.isNotEmpty ==
                                  true
                              ? dashboard
                                        ?.enrollmentDetails
                                        ?.enrollments
                                        ?.first
                                        .courseInfo
                                        ?.courseName ??
                                    ''
                              : '',
                          studentName: studentName,
                          provider: dashboardProvider,
                        ),
                        const SizedBox(height: 12),
                        StatusCard(
                          status:
                              dashboard
                                  ?.studentDetails
                                  ?.statusInfo
                                  ?.currentStatus
                                  ?.name ??
                              'Active',
                        ),

                        // ── ONAM EVENT NOTICE CARD ─────────────────────────────────
                        Builder(builder: (_) {
                          // Detect branch from active enrollment's batch location
                          final enrollments = dashboard
                              ?.enrollmentDetails?.enrollments;
                          String? locationValue;
                          if (enrollments != null && enrollments.isNotEmpty) {
                            // Prefer first active/payment_completed enrollment
                            final active = enrollments.firstWhere(
                              (e) =>
                                  e.status?.value == 'active' ||
                                  e.status?.value == 'payment_completed' ||
                                  e.status?.value == 'admission_fee_paid' ||
                                  (e.batchInfo?.isActive ?? false),
                              orElse: () => enrollments.first,
                            );
                            locationValue =
                                active.batchInfo?.location?.value ??
                                active.batchInfo?.location?.name;
                          }
                          final branch =
                              OnamEventHelper.detectBranch(locationValue);
                          final eventInfo =
                              OnamEventHelper.getEventForBranch(branch);
                          if (eventInfo == null) return const SizedBox.shrink();
                          return Column(children: [
                            const SizedBox(height: 16),
                            OnamNoticeCard(event: eventInfo),
                          ]);
                        }),

                        // ── BIRTHDAY CARD ──────────────────────────────────────────
                        // Dashboard data is always loaded on this screen; the
                        // ProfileController's copy only gets fetched once the
                        // user visits the Profile tab, so relying on it alone
                        // left the card never showing for anyone who hadn't
                        // been there yet this session. Dashboard's DOB is
                        // checked first, falling back to Profile's.
                        if (_isBirthday(
                          dashboard?.studentDetails?.personalInfo?.dateOfBirth ??
                              profileProvider.profileData?.personalInfo?.dateOfBirth,
                        )) ...[
                          const SizedBox(height: 20),
                          BirthdayCard(name: studentName.split(' ').first),
                        ],

                        if (dashboardProvider.shouldShowNactetBanner) ...[
                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            'NACTET Registration',
                            'Complete your registration below',
                          ),
                          const SizedBox(height: 14),
                          NactetBanner(
                            pendingCount: dashboardProvider.pendingNactetCount,
                            onFormTap: () => _onNactetFormTap(
                              context,
                              dashboardProvider.nactetStatus?.enrollments ?? [],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildSectionHeading(
                          'My Courses',
                          'Your active enrollments',
                        ),
                        const SizedBox(height: 14),
                        if (dashboard != null) ...[
                          _buildCourseCard(dashboard),

                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            'Financial Overview',
                            'Fees & payment summary',
                          ),
                          const SizedBox(height: 14),
                          _buildQuickStatsGrid(dashboard),
                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            'Job Opportunities',
                            'Openings shared with your batch',
                          ),
                          const SizedBox(height: 14),
                          _buildJobsCard(
                            dashboardProvider.unviewedJobNotificationsCount,
                          ),
                          const SizedBox(height: 28),
                          _buildSectionHeading('Referral', 'Earn rewards'),
                          const SizedBox(height: 14),
                          _buildReferralCard(),
                          const SizedBox(height: 28),
                          if (_showInstaSection) ...[
                            _buildSectionHeading(
                              'Latest Updates',
                              'News & announcements',
                            ),
                            const SizedBox(height: 14),
                          ],
                          AdvancedInstaCarousel(
                            onAvailabilityChanged: (hasContent) {
                              if (mounted && _showInstaSection != hasContent) {
                                setState(() => _showInstaSection = hasContent);
                              }
                            },
                          ),
                          if (_showInstaSection) const SizedBox(height: 28),
                          _buildSectionHeading(
                            'Follow Us',
                            'Stay connected with Luminar',
                          ),
                          const SizedBox(height: 14),
                          _buildSocialSection(),

                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ============== NACTET FORM NAVIGATION ==============

  // Uses the status field returned directly by the NACTET check-display API —
  // the same values (not_set / admission_fee_paid / demo_expired) as the
  // dashboard enrollment status, so no UID cross-reference is needed.
  bool _isPaymentMethodNotSet(NactetCheckDisplayEnrollment enrollment) {
    final status = enrollment.status;
    debugPrint('[NactetPayCheck] enrollment.status="$status"');
    return status == 'not_set' ||
        status == 'admission_fee_paid' ||
        status == 'demo_expired';
  }

  // Compares admissionFee vs amountPaid from the dashboard financial data.
  // Returns true only when the student has paid exactly the admission fee
  // (i.e., no EMI instalments have been paid yet).
  bool _isFirstEmiPending(BuildContext context, String enrollmentUid) {
    final dashboard =
        Provider.of<DashboardController>(context, listen: false).dashboard;
    if (dashboard == null || enrollmentUid.isEmpty) return false;

    final list = dashboard.enrollmentDetails?.enrollments ?? [];
    for (final e in list) {
      if ((e.basicInfo?.uid ?? '') == enrollmentUid) {
        final admissionFee = e.batchInfo?.admissionFees ?? 0;
        final amountPaid =
            e.paymentDetails?.financialBreakdown?.amountPaid ?? 0;
        debugPrint(
          '[NactetPayCheck] admissionFee=$admissionFee  amountPaid=$amountPaid',
        );
        if (admissionFee > 0) return amountPaid == admissionFee;
      }
    }

    // Also try matching by enrollment number as a fallback
    final enrollmentFromDashboard = Provider.of<DashboardController>(
      context,
      listen: false,
    ).enrollmentsFromDashboard;
    for (final e in enrollmentFromDashboard) {
      if (e.uid == enrollmentUid) {
        // uid matched via enrollmentsFromDashboard — financial data already
        // checked above through the raw dashboard list, so nothing more to do.
        break;
      }
    }
    return false;
  }

  void _showNactetBlockDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK, Got it',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNactetFormTap(
    BuildContext context,
    List<NactetCheckDisplayEnrollment> enrollments,
  ) {
    if (enrollments.length == 1) {
      final uid = enrollments.first.enrollmentUid;

      if (_isPaymentMethodNotSet(enrollments.first) ||
          _isFirstEmiPending(context, uid)) {
        _showNactetBlockDialog(
          context,
          title: 'Payment Required',
          message:
              'Full payment or first EMI payment is required to access the NACTET registration form.',
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NactetRegistrationScreen(nactetEnrollment: enrollments.first),
        ),
      ).then((_) {
        if (context.mounted) {
          Provider.of<DashboardController>(
            context,
            listen: false,
          ).getNactetStatus();
        }
      });
    } else {
      _showEnrollmentSelectionSheet(context, enrollments);
    }
  }

  void _showEnrollmentSelectionSheet(
    BuildContext context,
    List<NactetCheckDisplayEnrollment> enrollments,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnrollmentSelectionSheet(enrollments: enrollments),
    );
  }

  // ============== COURSE CARD SECTION ==============

  Widget _buildCourseCard(Dashboard dashboard) {
    final enrollmentsList = dashboard.enrollmentDetails?.enrollments ?? [];

    if (enrollmentsList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CURRENT ENROLLMENT', style: AppTextStyles.courseCardLabel),
            const SizedBox(height: 8),
            Text('No Course Enrolled', style: AppTextStyles.courseCardTitle),
          ],
        ),
      );
    }

    return _EnrollmentCardStack(
      enrollments: enrollmentsList,
      studentName: _displayName,
    );
  }

  // ============== EXISTING METHODS (KEPT EXACTLY AS THEY WERE) ==============

  Widget _buildQuickStatsGrid(Dashboard dashboard) {
    final financial = dashboard.financialSummary?.overview;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              "Total Fees",
              _formatCurrency(financial?.totalFeesAmount),
              Icons.account_balance_wallet,
              AppColors.statsBlue,
            ),
            _buildStatCard(
              "Paid",
              _formatCurrency(financial?.totalFeesPaid),
              Icons.check_circle,
              AppColors.statsGreen,
            ),
            _buildStatCard(
              "Pending",
              _formatCurrency(financial?.totalFeesPending),
              Icons.pending_actions,
              AppColors.statsOrange,
            ),
            _buildStatCard(
              "Progress",
              "${financial?.paymentCompletionPercentage ?? 0}%",
              Icons.speed,
              AppColors.statsPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.statLabel),
              Text(value, style: AppTextStyles.statValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, [String? subtitle]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: subtitle != null ? 42 : 26,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ============== SOCIAL MEDIA SECTION ==============

  Future<void> _launchSocial(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSocialSection() {
    final platforms = [
      _SocialPlatform(
        label: 'Website',
        handle: 'luminartechnolab.com',
        tag: 'Visit us online',
        url: 'https://www.luminartechnolab.com/',
        gradientColors: [
          Color(0xFF1E3A5F),
          Color(0xFF1565C0),
          Color(0xFF2196F3),
        ],
        icon: Icons.language_rounded,
        accentIcon: Icons.open_in_new_rounded,
      ),
      _SocialPlatform(
        label: 'LinkedIn',
        handle: 'luminartechnolab',
        tag: 'Connect & network',
        url:
            'https://www.linkedin.com/company/luminartechnolab/posts/?feedView=all',
        gradientColors: [
          Color(0xFF003C71),
          Color(0xFF0072B1),
          Color(0xFF0A88D1),
        ],
        icon: Icons.work_rounded,
        accentIcon: Icons.people_rounded,
        badge: 'in',
      ),
      _SocialPlatform(
        label: 'Instagram',
        handle: '@luminartechnolab',
        tag: 'Photos & Reels',
        url: 'https://www.instagram.com/luminartechnolab',
        gradientColors: [
          Color(0xFF833AB4),
          Color(0xFFE1306C),
          Color(0xFFF77737),
        ],
        icon: Icons.camera_alt_rounded,
        accentIcon: Icons.favorite_rounded,
      ),
      _SocialPlatform(
        label: 'YouTube',
        handle: '@LuminarTechnolab',
        tag: 'Tutorials & Demos',
        url: 'https://www.youtube.com/@LuminarTechnolab',
        gradientColors: [
          Color(0xFF7F0000),
          Color(0xFFCC0000),
          Color(0xFFFF3D3D),
        ],
        icon: Icons.play_circle_filled_rounded,
        accentIcon: Icons.subscriptions_rounded,
      ),
    ];

    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        itemCount: platforms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _SocialCard(
          platform: platforms[i],
          onTap: () => _launchSocial(platforms[i].url),
        ),
      ),
    );
  }

  // ============== REFERRAL CARD SECTION ==============

  Widget _buildReferralCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final profile = authProvider.studentData?.profile;
        return GestureDetector(
          onTap: () {
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -10,
                  bottom: -15,
                  child: Icon(
                    Icons.redeem_rounded,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD700),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'REFER & EARN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Refer your friend,\nearn your pocket money!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Invite Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============== JOBS CARD ==============

  Widget _buildJobsCard(int unviewedCount) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JobsScreen()),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3460).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF533483).withValues(alpha: 0.25),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top row: icon + badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF533483).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.work_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Job Opportunities',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unviewedCount > 0
                                  ? '$unviewedCount new opening${unviewedCount == 1 ? '' : 's'} for you'
                                  : 'Explore openings from your batch',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // unviewed badge
                      if (unviewedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '$unviewedCount NEW',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Explore button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore Jobs',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F3460),
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: Color(0xFF0F3460),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.business_center_rounded,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(Dashboard dashboard) {
    final activities = dashboard.recentActivities?.recentActivities ?? [];

    if (activities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No recent activities',
            style: AppTextStyles.activitySubtitle,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 4 ? 4 : activities.length,
      separatorBuilder: (context, index) =>
          Divider(color: AppColors.borderColor.withOpacity(0.5)),
      itemBuilder: (context, index) {
        final item = activities[index];

        IconData getIconForType(String? type) {
          switch (type) {
            case 'payment':
              return Icons.payment;
            case 'enrollment':
              return Icons.app_registration;
            case 'academic':
              return Icons.school;
            default:
              return Icons.notifications_none;
          }
        }

        Color getColorForPriority(String? priority) {
          switch (priority?.toLowerCase()) {
            case 'high':
              return Colors.red;
            case 'medium':
              return Colors.orange;
            case 'low':
              return Colors.green;
            default:
              return AppColors.info;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: getColorForPriority(
                item.priority?.toString(),
              ).withOpacity(0.1),
              child: Icon(
                getIconForType(item.type),
                color: getColorForPriority(item.priority?.toString()),
                size: 20,
              ),
            ),
            title: Text(
              item.title ?? 'Activity',
              style: AppTextStyles.activityTitle.copyWith(fontSize: 14),
            ),
            subtitle: Text(
              item.description ?? '',
              style: AppTextStyles.activitySubtitle.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.amount != null)
                  Text(
                    _formatCurrency(item.amount),
                    style: AppTextStyles.statValue.copyWith(
                      fontSize: 12,
                      color: AppColors.statsGreen,
                    ),
                  ),
                Text(
                  _formatDateForActivity(item.date),
                  style: AppTextStyles.activityTime,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateForActivity(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  // ============== BIRTHDAY CARD ==============
  bool _isBirthday(DateTime? dob) {
    if (dob == null) {
      debugPrint('🎉 Birthday Check: DOB from Profile API is NULL!');
      return false;
    }

    final now = DateTime.now();
    debugPrint(
      '🎉 Birthday Check: DOB = ${dob.month}/${dob.day} | Today = ${now.month}/${now.day}',
    );
    return dob.month == now.month && dob.day == now.day;
  }

  // ══════════════════════════════════════════════════════
  //  OCEAN THEME LAYOUT
  // ══════════════════════════════════════════════════════

  Widget _buildOceanBody({
    required Dashboard? dashboard,
    required String studentName,
    required DashboardController dashboardProvider,
    required ProfileController profileProvider,
  }) {
    final financial = dashboard?.financialSummary?.overview;
    final enrollments = dashboard?.enrollmentDetails?.enrollments ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Flat teal header ──────────────────────────
          _buildOceanHeader(studentName, dashboard),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Financial stats (horizontal scroll) ──
                _buildOceanLabel('Financial Summary'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _oceanStatChip('Total Fees',
                          _formatCurrency(financial?.totalFeesAmount),
                          Icons.account_balance_wallet_rounded,
                          AppColors.statsBlue),
                      _oceanStatChip('Paid',
                          _formatCurrency(financial?.totalFeesPaid),
                          Icons.check_circle_rounded,
                          AppColors.statsGreen),
                      _oceanStatChip('Pending',
                          _formatCurrency(financial?.totalFeesPending),
                          Icons.timer_rounded,
                          AppColors.statsOrange),
                      _oceanStatChip('Progress',
                          '${financial?.paymentCompletionPercentage ?? 0}%',
                          Icons.speed_rounded,
                          AppColors.statsPurple),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Enrollments as compact list ───────────
                _buildOceanLabel('My Enrollments'),
                const SizedBox(height: 12),
                if (enrollments.isEmpty)
                  _oceanEmptyCard('No enrollments found')
                else
                  ...enrollments.asMap().entries.map((entry) =>
                    _oceanEnrollmentTile(entry.value, entry.key)),

                const SizedBox(height: 28),

                // ── Jobs + Referral side-by-side ──────────
                _buildOceanLabel('Quick Access'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _oceanJobsMiniCard(
                          dashboardProvider.unviewedJobNotificationsCount),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _oceanReferralMiniCard()),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Social links ──────────────────────────
                _buildOceanLabel('Connect With Us'),
                const SizedBox(height: 12),
                _buildSocialSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOceanHeader(String studentName, Dashboard? dashboard) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';
    final courseName = dashboard?.enrollmentDetails?.enrollments?.isNotEmpty == true
        ? dashboard!.enrollmentDetails!.enrollments!.first.courseInfo?.courseName ?? ''
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (courseName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            courseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(course: courseName),
                  ),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showOceanThemePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.palette_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOceanThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final tp = ctx.watch<ThemeProvider>();
          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('App Theme',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Choose a design for the entire app',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _oceanThemeCard(
                      context: context,
                      themeProvider: tp,
                      label: 'Luminar',
                      subtitle: 'Purple classic',
                      gradientColors: const [
                        Color(0xFF6C5CE7),
                        Color(0xFF8B7BF2)
                      ],
                      variant: AppThemeVariant.luminar,
                    ),
                    const SizedBox(width: 12),
                    _oceanThemeCard(
                      context: context,
                      themeProvider: tp,
                      label: 'Ocean',
                      subtitle: 'Teal modern',
                      gradientColors: const [
                        Color(0xFF00897B),
                        Color(0xFF26A69A)
                      ],
                      variant: AppThemeVariant.ocean,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _oceanThemeCard({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required AppThemeVariant variant,
  }) {
    final isActive = themeProvider.variant == variant;
    final primary = gradientColors.first;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          themeProvider.setVariant(variant);
          Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? primary.withValues(alpha: 0.07)
                : AppColors.cardBackground,
            border: Border.all(
              color: isActive ? primary : AppColors.borderColor,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              if (isActive) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.check_circle_rounded, color: primary, size: 15),
                  const SizedBox(width: 4),
                  Text('Active',
                      style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOceanLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _oceanStatChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _oceanEnrollmentTile(dynamic enrollment, int index) {
    final palettes = _oceanPalettes();
    final color = palettes[index % palettes.length];
    final courseName =
        enrollment?.courseInfo?.courseName ?? 'No Course';
    final batchName = enrollment?.batchInfo?.batchName ?? 'N/A';
    final statusValue = enrollment?.status?.value ?? '';
    final isActive = statusValue.contains('paid') || statusValue == 'active';

    return GestureDetector(
      onTap: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => BottomNavScreen(initialIndex: 3)),
        (r) => false,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courseName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 3),
                    Text(batchName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.statsGreen : AppColors.statsOrange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.statsGreen
                        : AppColors.statsOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _oceanPalettes() => [
        AppColors.primary,
        AppColors.statsBlue,
        AppColors.statsGreen,
        AppColors.statsOrange,
        const Color(0xFF7B1FA2),
      ];

  Widget _oceanJobsMiniCard(int unviewedCount) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const JobsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: const Offset(0, 2)),
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
                  child: Icon(Icons.work_rounded,
                      color: AppColors.primary, size: 18),
                ),
                if (unviewedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$unviewedCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text('Jobs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 2),
            Text('View openings',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Explore',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded,
                    size: 13, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _oceanReferralMiniCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Consumer<AuthProvider>(
                    builder: (ctx, auth, _) => ReferralScreen(
                      referrerName: auth.studentData?.profile.fullName,
                      referrerPhone: auth.studentData?.profile.phone,
                    ),
                  ))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.redeem_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            const Text('Referral',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
            const SizedBox(height: 2),
            Text('Refer & earn',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Start',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_rounded,
                    size: 13, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _oceanEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(message,
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center),
    );
  }
}

// ============================================================
//  Horizontal Swipe Credit-Card Enrollment Widget
// ============================================================

class _EnrollmentCardStack extends StatefulWidget {
  final List enrollments;
  final String studentName;

  const _EnrollmentCardStack({
    required this.enrollments,
    required this.studentName,
  });

  @override
  State<_EnrollmentCardStack> createState() => _EnrollmentCardStackState();
}

class _EnrollmentCardStackState extends State<_EnrollmentCardStack>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Per-card tap ripple controllers
  final Map<int, AnimationController> _rippleControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onScroll);
  }

  AnimationController _getRipple(int index) {
    return _rippleControllers.putIfAbsent(
      index,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onScroll() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage && mounted) {
      setState(() => _currentPage = newPage);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    for (final c in _rippleControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card PageView ─────────────────────────────────────
        SizedBox(
          height: (MediaQuery.of(context).size.height * 0.42).clamp(
            290.0,
            370.0,
          ),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.enrollments.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (ctx, child) {
                  double offset = 0.0;
                  if (_pageController.position.haveDimensions) {
                    offset = _pageController.page! - index;
                  }
                  // Active card full size; side cards shrink + drop
                  final scale = (1.0 - offset.abs() * 0.06).clamp(0.88, 1.0);
                  final translateY = offset.abs() * 12;
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: child,
                    ),
                  );
                },
                child: _buildEnrollmentCard(context, index),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ── Bottom row: count + dots + swipe hint ─────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} of ${widget.enrollments.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // Animated pill dots
              if (widget.enrollments.length > 1)
                Row(
                  children: List.generate(
                    widget.enrollments.length.clamp(0, 6),
                    (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),

              // Swipe hint
              Row(
                children: [
                  Icon(
                    Icons.swipe_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'swipe',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Enrollment Card  (premium redesign)
  // ════════════════════════════════════════════════════════════

  Widget _buildEnrollmentCard(BuildContext context, int index) {
    final enrollment = widget.enrollments[index];

    final cardPalettes = [
      [
        AppColors.primaryDark,
        AppColors.primary,
        AppColors.primaryLighter,
      ], // Theme primary
      [Color(0xFF0A3D62), Color(0xFF1565C0), Color(0xFF42A5F5)], // Royal Blue
      [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF26A69A)], // Teal
      [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFAB47BC)], // Violet
      [Color(0xFF7B1A1A), Color(0xFFC62828), Color(0xFFEF5350)], // Crimson
    ];
    final palette = cardPalettes[index % cardPalettes.length];
    final accentColor = palette[2];

    final courseName =
        enrollment?.courseInfo?.courseName ?? 'No Course Enrolled';
    final batchName = enrollment?.batchInfo?.batchName ?? 'N/A';
    final startDate = enrollment?.batchInfo?.startDate;
    final batchTime = enrollment?.batchInfo?.time ?? '';
    // Use dashboard status directly — enrollment provider may not have loaded yet on iOS
    final status = enrollment?.status;
    final statusValue = status?.value ?? '';
    final isNavigatable =
        statusValue == 'admission_fee_paid' ||
        statusValue == 'not_set' ||
        statusValue == 'demo_expired';

    final ripple = _getRipple(index);

    void navigate() {
      ripple.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        final bool shouldGoToDetails = isNavigatable && !AppConfig.hidePayments;

        if (shouldGoToDetails) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EnrollmentDetailsScreen(index: index, backbuttonValue: true),
            ),
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BottomNavScreen(initialIndex: 3)),
            (route) => false,
          );
        }
      });
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => BottomNavScreen(initialIndex: 3)),
          (route) => false,
        );
      },
      child: AnimatedBuilder(
        animation: ripple,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - ripple.value * 0.016, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: palette[0].withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── Decorative blobs ──────────────────────────
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // ── Main content ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // ── Header: logo + brand + status ────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://d3eqn3hw2x95rk.cloudfront.net/seo/og_images/logo_without_divide_page-0001.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.school_rounded,
                                  color: palette[0],
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          if (status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    (status.name ?? '').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Gradient divider ──────────────────────
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Course ───────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COURSE',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  courseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Batch (full width) ────────────────────
                      _cardInfoTile(
                        icon: Icons.group_outlined,
                        label: 'BATCH',
                        value: batchName,
                      ),

                      const SizedBox(height: 14),

                      // ── Starts | Timing ──────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _cardInfoTile(
                              icon: Icons.calendar_month_outlined,
                              label: 'STARTS',
                              value: startDate != null
                                  ? '${_monthName(startDate.month)} ${startDate.year}'
                                  : 'N/A',
                            ),
                          ),
                          if (batchTime.isNotEmpty) ...[
                            Container(
                              width: 1,
                              height: 38,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            Expanded(
                              child: _cardInfoTile(
                                icon: Icons.schedule_rounded,
                                label: 'TIMING',
                                value: _formatBatchTime(batchTime),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const Spacer(),

                      // ── Continue button ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: navigate,
                          icon: const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('Continue Learning'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: palette[0],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _cardInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBatchTime(String time) {
    if (time.isEmpty) return 'Not specified';
    try {
      // Handle range format like "09:00-11:00" or "09:00 - 11:00"
      final rangeSeparator = RegExp(r'\s*-\s*');
      final parts = time.split(rangeSeparator);
      if (parts.length == 2) {
        final start = _parseTimeTo12h(parts[0].trim());
        final end = _parseTimeTo12h(parts[1].trim());
        return '$start - $end';
      }
      return _parseTimeTo12h(time.trim());
    } catch (e) {
      return time;
    }
  }

  String _parseTimeTo12h(String time) {
    final normalized = time.replaceAll('.', ':');
    final parts = normalized.split(':');
    if (parts.length >= 2) {
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
    return time;
  }

  String _formatTimeDetailed(String time) {
    try {
      final parts = time.replaceAll('.', ':').split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

// ── CustomPainters ────────────────────────────────────────────

/// Gold chip circuit lines
class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC09000).withValues(alpha: 0.5)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.82,
        height: size.height * 0.78,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rRect, paint);
    // Vertical centre line
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.39),
      Offset(cx, cy + size.height * 0.39),
      paint,
    );
    // Two horizontal lines
    canvas.drawLine(
      Offset(cx - size.width * 0.35, cy - size.height * 0.12),
      Offset(cx + size.width * 0.35, cy - size.height * 0.12),
      paint,
    );
    canvas.drawLine(
      Offset(cx - size.width * 0.35, cy + size.height * 0.12),
      Offset(cx + size.width * 0.35, cy + size.height * 0.12),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Social Media Data Model ────────────────────────────────────────────────────

class _SocialPlatform {
  final String label;
  final String handle;
  final String tag;
  final String url;
  final List<Color> gradientColors;
  final IconData icon;
  final IconData accentIcon;
  final String? badge;

  const _SocialPlatform({
    required this.label,
    required this.handle,
    required this.tag,
    required this.url,
    required this.gradientColors,
    required this.icon,
    required this.accentIcon,
    this.badge,
  });
}

// ── Social Card Widget ─────────────────────────────────────────────────────────

class _SocialCard extends StatelessWidget {
  final _SocialPlatform platform;
  final VoidCallback onTap;

  const _SocialCard({required this.platform, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = platform;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 158,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: p.gradientColors.first.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: p.badge != null
                  ? Center(
                      child: Text(
                        p.badge!,
                        style: TextStyle(
                          color: p.gradientColors.first,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Icon(p.icon, color: p.gradientColors.first, size: 20),
            ),
            const Spacer(),
            Text(
              p.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              p.handle,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.gradientColors.first,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: p.gradientColors.first,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle dot-grid texture for card background

// ── NACTET Enrollment Selection Sheet ─────────────────────────────────────────

class _EnrollmentSelectionSheet extends StatelessWidget {
  final List<NactetCheckDisplayEnrollment> enrollments;

  const _EnrollmentSelectionSheet({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    final submitted = enrollments.where((e) => e.hasCertificateData).length;
    final total = enrollments.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NACTET Registration ($total Enrollments)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Select an enrollment to begin',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.borderColor),
          const SizedBox(height: 12),

          // ── Overall Progress ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$submitted / $total submitted',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? submitted / total : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Section label ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.layers_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'SELECT ENROLLMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'You have ${enrollments.where((e) => !e.hasCertificateData).length} enrollment${enrollments.where((e) => !e.hasCertificateData).length == 1 ? '' : 's'} requiring NACTET registration. Select one to fill the form.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Enrollment cards ─────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: enrollments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final e = enrollments[i];
              final done = e.hasCertificateData;
              return GestureDetector(
                onTap: done
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NactetRegistrationScreen(nactetEnrollment: e),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            Provider.of<DashboardController>(
                              context,
                              listen: false,
                            ).getNactetStatus();
                          }
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      // number badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: done
                              ? Colors.green.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: done
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                                size: 18,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.courseName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.batchName,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  e.enrollmentNumber,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: done
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : AppColors.primary.withValues(
                                            alpha: 0.10,
                                          ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    done ? 'Submitted' : e.statusDisplay,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: done
                                          ? Colors.green
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!done)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Close button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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
