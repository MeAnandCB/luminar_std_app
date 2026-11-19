import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/certificate/certificate_controller.dart';
import 'package:luminar_std/presentation/certificate/certificate_tile.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';

/// More → Certificates. The same functionality as the home card's sheet, on
/// its own page: every completed batch with either its request form, the
/// status of the request already made, or the issued certificate to download.
///
/// State comes from the shared [CertificateController], so anything done here
/// is reflected on the home card (and vice versa). The list is re-read each
/// time the page opens because staff can issue or reject a request at any
/// moment.
class CertificateScreen extends StatefulWidget {
  final CertificateController controller;

  /// The course the student opened this from. Only used to word the "nothing
  /// here yet" message: someone who just tapped a *completed* course must not
  /// be told to come back once their batch is completed.
  final String courseName;

  const CertificateScreen({
    super.key,
    required this.controller,
    this.courseName = '',
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  CertificateController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    // Show what is already known straight away; this updates it in place.
    _c.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        // Left-aligned next to the back arrow on every platform (the theme
        // centres titles, which on iOS floats it away from the arrow).
        centerTitle: false,
        title: const Text(
          'Certificates',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
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
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (_c.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final error = _c.error;
          if (error != null) {
            return _Message(
              icon: Icons.cloud_off_rounded,
              text: error,
              actionLabel: 'Try again',
              onAction: _c.refresh,
            );
          }

          final enrollments =
              _c.data?.enrollments ?? const <CertificateEnrollment>[];
          return RefreshIndicator(
            onRefresh: _c.refresh,
            color: AppColors.primary,
            child: enrollments.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _Message(
                        icon: Icons.workspace_premium_rounded,
                        text: widget.courseName.trim().isEmpty
                            ? 'Certificates can be requested after your batch '
                                  'is completed.'
                            : 'We couldn\'t find a certificate for '
                                  '${widget.courseName.trim()} yet.\n\n'
                                  'If your course has just finished, check '
                                  'again in a little while. If it still '
                                  'doesn\'t appear, please contact your '
                                  'academic counselor.',
                        actionLabel: 'Refresh',
                        onAction: _c.refresh,
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _SummaryBanner(enrollments: enrollments),
                      const SizedBox(height: 18),
                      for (final e in enrollments)
                        CertificateTile(
                          key: ValueKey(e.enrollmentNumber),
                          enrollment: e,
                          onSubmit: _c.submit,
                          onDownload: _c.download,
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// The page's hero: what this page is for, and where every course stands.
class _SummaryBanner extends StatelessWidget {
  final List<CertificateEnrollment> enrollments;

  const _SummaryBanner({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    int count(bool Function(CertificateEnrollment) test) =>
        enrollments.where(test).length;

    final stats = <(String, Color)>[
      if (count((e) => e.request?.isIssued == true) > 0)
        (
          '${count((e) => e.request?.isIssued == true)} issued',
          certificateIssuedColor,
        ),
      if (count((e) => e.request?.isPending == true) > 0)
        (
          '${count((e) => e.request?.isPending == true)} in review',
          certificatePendingColor,
        ),
      if (count((e) => e.request?.isRejected == true) > 0)
        (
          '${count((e) => e.request?.isRejected == true)} rejected',
          certificateRejectedColor,
        ),
      if (count((e) => e.request == null && e.eligible) > 0)
        (
          '${count((e) => e.request == null && e.eligible)} ready to request',
          const Color(0xFFFFC24B),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFC24B),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your certificates',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Each course is requested separately',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, color) in stats)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
