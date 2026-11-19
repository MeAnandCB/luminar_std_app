import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// One enrollment's certificate tile — shared by the home card's bottom sheet
// and the More → Certificates page so both always look and behave the same:
// the request form, the status of a request already made, or (once issued)
// the certificate's numbers and a Download button.
// ─────────────────────────────────────────────────────────────────────────────

const Color certificatePendingColor = Color(0xFFF59E0B);
const Color certificateIssuedColor = Color(0xFF10B981);
const Color certificateRejectedColor = Color(0xFFEF4444);

/// `2026-11-07` -> `7 Nov 2026` (unparseable input is returned unchanged).
String formatCertificateYmd(String raw) {
  final d = DateTime.tryParse(raw);
  return d == null ? raw : DateFormat('d MMM yyyy').format(d);
}

String formatCertificateDate(DateTime? d) =>
    d == null ? '' : DateFormat('d MMM yyyy').format(d);

/// The colour that tells a student where this enrollment stands at a glance.
Color _accentFor(CertificateEnrollment e) {
  final req = e.request;
  if (req == null) {
    return e.eligible ? AppColors.primary : AppColors.textSecondary;
  }
  return switch (req.status) {
    'issued' => certificateIssuedColor,
    'rejected' => certificateRejectedColor,
    _ => certificatePendingColor,
  };
}

class CertificateTile extends StatefulWidget {
  final CertificateEnrollment enrollment;
  final Future<String?> Function(String enrollmentNumber, String note) onSubmit;
  final Future<String?> Function(CertificateEnrollment enrollment) onDownload;

  const CertificateTile({
    super.key,
    required this.enrollment,
    required this.onSubmit,
    required this.onDownload,
  });

  @override
  State<CertificateTile> createState() => _CertificateTileState();
}

class _CertificateTileState extends State<CertificateTile> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _downloading = false;
  String? _downloadError;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      widget.enrollment.enrollmentNumber,
      _noteCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _downloadError = null;
    });

    final error = await widget.onDownload(widget.enrollment);
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _downloadError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enrollment;
    final req = e.request;
    final accent = _accentFor(e);
    // Not eligible (dropped/removed): never a form. An existing pending or
    // issued request is still the whole story; otherwise say why.
    final showNotEligible = !e.eligible && (req == null || req.isRejected);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status accent: green issued, amber pending, red rejected.
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.45)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(e, accent),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: AppColors.borderColor),
                const SizedBox(height: 16),
                if (req != null) _statusBlock(e, req),
                if (showNotEligible) ...[
                  if (req != null) const SizedBox(height: 12),
                  _InfoBox(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    text: 'Not eligible for a certificate for this enrollment.',
                  ),
                ],
                if (e.canRequest) ...[
                  if (req != null) const SizedBox(height: 18),
                  _form(e),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Course, batch and enrollment number — one left edge for every line.
  Widget _header(CertificateEnrollment e, Color accent) {
    final subtitle = e.batchEndDate.isEmpty
        ? 'Batch ${e.batchName} · Completed'
        : 'Batch ${e.batchName} · Completed ${formatCertificateYmd(e.batchEndDate)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.workspace_premium_rounded, color: accent, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.courseName.isEmpty ? 'Course' : e.courseName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Text(
                  e.enrollmentNumber,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBlock(CertificateEnrollment e, CertificateRequestInfo req) {
    final (color, icon, label) = switch (req.status) {
      'issued' => (
        certificateIssuedColor,
        Icons.verified_rounded,
        'Issued on ${req.issuedDate != null ? formatCertificateYmd(req.issuedDate!) : '—'}',
      ),
      'rejected' => (
        certificateRejectedColor,
        Icons.cancel_rounded,
        'Rejected',
      ),
      _ => (
        certificatePendingColor,
        Icons.hourglass_top_rounded,
        'Requested on ${formatCertificateDate(req.requestedAt)}',
      ),
    };
    final typeLabel = req.certificateTypeLabel.isNotEmpty
        ? req.certificateTypeLabel
        : e.certificateTypeLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Pill(icon: icon, label: label, color: color),
            if (typeLabel.isNotEmpty) _TypeChip(label: typeLabel),
          ],
        ),
        if (req.isIssued) ..._issuedDetails(e, req),
        // The server only fills `remark` for a rejection; never show it
        // for any other status.
        if (req.isRejected && req.remark.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoBox(
            icon: Icons.chat_bubble_outline_rounded,
            color: certificateRejectedColor,
            text: 'Reason: ${req.remark}',
          ),
        ],
      ],
    );
  }

  /// Serial / register numbers and the Download button of an issued request.
  List<Widget> _issuedDetails(
    CertificateEnrollment e,
    CertificateRequestInfo req,
  ) {
    final rows = <(String, String)>[
      if (req.serialNo != null) ('Serial No.', '${req.serialNo}'),
      if (req.registerNo != null) ('Register No.', req.registerNo!),
    ];

    return [
      if (rows.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: certificateIssuedColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: certificateIssuedColor.withValues(alpha: 0.2),
            ),
          ),
          // A real two-column table: every value starts at the same x no
          // matter how long its label is.
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              for (var i = 0; i < rows.length; i++)
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        right: 20,
                        bottom: i == rows.length - 1 ? 0 : 8,
                      ),
                      child: Text(
                        rows[i].$1,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == rows.length - 1 ? 0 : 8,
                      ),
                      child: Text(
                        rows[i].$2,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
      if (req.downloadAvailable) ...[
        const SizedBox(height: 16),
        if (_downloadError != null) ...[
          _InfoBox(
            icon: Icons.error_outline_rounded,
            color: certificateRejectedColor,
            text: _downloadError!,
          ),
          const SizedBox(height: 12),
        ],
        _ActionButton(
          label: _downloading ? 'Downloading…' : 'Download Certificate',
          icon: Icons.download_rounded,
          color: certificateIssuedColor,
          busy: _downloading,
          onTap: _downloading ? null : _download,
        ),
      ],
    ];
  }

  Widget _form(CertificateEnrollment e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The batch decides which certificate it gives; nothing to choose.
        if (e.certificateTypeLabel.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CERTIFICATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.certificateTypeLabel,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _noteCtrl,
          enabled: !_submitting,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Add a note (optional) — e.g. needed for a job application',
            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _InfoBox(
            icon: Icons.error_outline_rounded,
            color: certificateRejectedColor,
            text: _error!,
          ),
        ],
        const SizedBox(height: 16),
        _ActionButton(
          label: _submitting ? 'Submitting…' : 'Request Certificate',
          icon: Icons.workspace_premium_rounded,
          color: AppColors.primary,
          busy: _submitting,
          onTap: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// A full-width gradient button.
///
/// Deliberately not an `ElevatedButton`: the app theme gives those a fixed
/// 16dp vertical padding, which leaves a fixed-height button too little room
/// for its label and clips the text. This one centres its content in an exact
/// height, so the label is always fully visible.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return AnimatedOpacity(
      opacity: busy ? 0.75 : 1,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(icon, size: 21, color: Colors.white),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The coloured status badge ("Issued on …", "Requested on …", "Rejected").
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Which certificate this is ("Course Completion", "Internship").
class _TypeChip extends StatelessWidget {
  final String label;

  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBox({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
