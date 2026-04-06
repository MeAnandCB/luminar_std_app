import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';
import 'package:luminar_std/presentation/profile_edit_screen/views/profile_edit_screen.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:share_plus/share_plus.dart';

// ── ID Card brand colours ──────────────────────────────────────────────────
const _kCardDark = Color(0xFF1E163A);
const _kCardMid = Color(0xFF2E2075);
const _kCardAccent = Color(0xFF4A35B0);
const _kCardLight = Color(0xFF7C6BE8);
const _kCardPale = Color(0xFFECE9FF);
const _kCardPaleTx = Color(0xFFB8AAFF);
const _kCardLabel = Color(0xFF9C8FC8);
const _kCardBody = Color(0xFF1A1235);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.course});

  final String course;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Provider.of<ProfileController>(
        context,
        listen: false,
      ).getProfileData(context: context);
    });
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (context.mounted) {
      Provider.of<ChatProvider>(context, listen: false).reset();
    }

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // ─── Student ID Card bottom sheet ──────────────────────────────────────────

  void _showStudentIdCard(BuildContext context, ProfileController provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Student ID Card',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kCardBody,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Official Luminar identification',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kCardLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _kCardPale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D9E75),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Active',
                          style: TextStyle(
                            color: _kCardAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildStudentIdCard(provider),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadIdCard(),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kCardDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadIdCard(),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kCardPale,
                        foregroundColor: _kCardAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _kCardAccent.withOpacity(0.18),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Download / Share ───────────────────────────────────────────────────────

  Future<void> _downloadIdCard() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/student_id_card.png').create();
        await file.writeAsBytes(pngBytes);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('ID Card downloaded successfully!')),
                ],
              ),
              backgroundColor: AppColors.statsGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Share.shareXFiles([
            XFile(file.path),
          ], text: 'My Luminar Technolab Student ID Card');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Portrait ID Card ───────────────────────────────────────────────────────

  Widget _buildStudentIdCard(ProfileController provider) {
    final fullName = provider.profile?.personalInfo?.fullName ?? '';
    final studentId = provider.profile?.personalInfo?.studentId ?? '';
    final course = widget.course;
    final email = provider.profile?.personalInfo?.email ?? '';
    final phone = provider.profile?.personalInfo?.phone ?? '';
    final profilePic = provider.profile?.personalInfo?.profilePicture;
    final admDate = provider.profile?.academicInfo?.admissionDate;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kCardAccent.withOpacity(0.14),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Curved arc header ───────────────────────────────────
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ClipPath(
                    clipper: _IdCardArcClipper(),
                    child: Container(
                      height: 210,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kCardDark, _kCardMid, _kCardAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SizedBox(
                      width: 130,
                      height: 120,
                      child: CustomPaint(painter: _IdCardDotPatternPainter()),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    left: 18,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kCardLight.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Luminar Technolab',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    'Accredited Technical Institute',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 9,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.13),
                                ),
                              ),
                              child: Text(
                                'STUDENT',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_kCardLight, _kCardAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kCardAccent.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Container(
                              color: const Color(0xFFC4B8FF),
                              child: profilePic != null && profilePic.isNotEmpty
                                  ? Image.network(profilePic, fit: BoxFit.cover)
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: _kCardAccent,
                                      size: 36,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── ID pill ─────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _kCardDark,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _kCardLight.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _kCardLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    studentId.isNotEmpty ? studentId : '—',
                    style: const TextStyle(
                      color: _kCardPaleTx,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),

            // ── Name + course tag ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  Text(
                    fullName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kCardBody,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _kCardPale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course,
                      style: const TextStyle(
                        color: _kCardAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Gradient divider ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kCardLabel.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Info rows ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  _buildCardInfoRow(
                    iconData: Icons.school_rounded,
                    iconColor: _kCardAccent,
                    iconBg: _kCardPale,
                    label: 'Course',
                    value: course,
                  ),
                  Divider(color: _kCardPale, height: 1, thickness: 0.5),
                  _buildCardInfoRow(
                    iconData: Icons.email_rounded,
                    iconColor: const Color(0xFF185FA5),
                    iconBg: const Color(0xFFE6F1FB),
                    label: 'Email',
                    value: email,
                  ),
                  Divider(color: _kCardPale, height: 1, thickness: 0.5),
                  _buildCardInfoRow(
                    iconData: Icons.phone_rounded,
                    iconColor: const Color(0xFF0F6E56),
                    iconBg: const Color(0xFFE1F5EE),
                    label: 'Mobile',
                    value: phone,
                  ),
                  if (admDate != null) ...[
                    Divider(color: _kCardPale, height: 1, thickness: 0.5),
                    _buildCardInfoRow(
                      iconData: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF854F0B),
                      iconBg: const Color(0xFFFAEEDA),
                      label: 'Admission Date',
                      value: DateFormat('dd MMMM yyyy').format(admDate),
                    ),
                  ],
                ],
              ),
            ),

            // ── Dark footer ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kCardDark, _kCardMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACADEMIC YEAR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '2025 – 2026 Batch',
                        style: TextStyle(
                          color: _kCardPaleTx,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7C6BE8),
                          Color(0xFFB8AAFF),
                          Color(0xFF4A35B0),
                          Color(0xFFE8D5A3),
                          Color(0xFF7C6BE8),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white.withOpacity(0.55),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Validity strip ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              color: const Color(0xFFF7F5FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Validity: December 2026',
                    style: TextStyle(
                      color: _kCardLabel,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D9E75),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF0F6E56),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
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

  Widget _buildCardInfoRow({
    required IconData iconData,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _kCardLabel,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _kCardBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    final profileProvider = Provider.of<ProfileController>(context);
    final String proof1 = profileProvider.profile?.personalInfo?.idProof ?? "";
    final String proof2 = profileProvider.profile?.personalInfo?.idProof2 ?? "";

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: profileProvider.isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'My Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // ID Card button
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () => _showStudentIdCard(
                                    context,
                                    profileProvider,
                                  ),
                                  icon: Icon(
                                    Icons.badge_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'View ID Card',
                                ),
                              ),
                              SizedBox(width: 8),
                              // Logout button
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () =>
                                      _showLogoutConfirmation(context),
                                  icon: Icon(
                                    Icons.logout,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Profile Header Card ─────────────────────────────
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.splashGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.whiteWithOpacity20,
                              shape: BoxShape.circle,
                              image:
                                  profileProvider
                                              .profile
                                              ?.personalInfo
                                              ?.profilePicture !=
                                          null &&
                                      profileProvider
                                          .profile!
                                          .personalInfo!
                                          .profilePicture!
                                          .isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        profileProvider
                                            .profile!
                                            .personalInfo!
                                            .profilePicture!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                profileProvider
                                            .profile
                                            ?.personalInfo
                                            ?.profilePicture ==
                                        null ||
                                    profileProvider
                                        .profile!
                                        .personalInfo!
                                        .profilePicture!
                                        .isEmpty
                                ? Icon(
                                    Icons.person_rounded,
                                    color: AppColors.white,
                                    size: 40,
                                  )
                                : null,
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profileProvider
                                          .profile
                                          ?.personalInfo
                                          ?.fullName ??
                                      "",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  profileProvider
                                          .profile
                                          ?.personalInfo
                                          ?.studentId ??
                                      "",
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.whiteWithOpacity90,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'This is also your referral code',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.whiteWithOpacity80,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.statsGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        profileProvider
                                                .profile
                                                ?.statusInfo
                                                ?.status
                                                ?.value ??
                                            "",
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // ── Personal Information ────────────────────────────
                    _buildSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      color: AppColors.primary,
                      children: [
                        _buildInfoRow(
                          'Full Name',
                          profileProvider.profile?.personalInfo?.fullName ?? "",
                        ),
                        _buildInfoRow(
                          'Email Address',
                          profileProvider.profile?.personalInfo?.email ?? "",
                        ),
                        _buildInfoRow(
                          'Phone Number',
                          profileProvider.profile?.personalInfo?.phone ?? "",
                        ),
                        _buildInfoRow(
                          'WhatsApp Number',
                          profileProvider
                                  .profile
                                  ?.personalInfo
                                  ?.whatsappNumber ??
                              "",
                        ),
                        _buildInfoRow(
                          'Date of Birth',
                          profileProvider.profile?.personalInfo?.dateOfBirth !=
                                  null
                              ? DateFormat('dd MM yyyy').format(
                                  profileProvider
                                      .profile!
                                      .personalInfo!
                                      .dateOfBirth!,
                                )
                              : "",
                        ),
                        _buildInfoRow(
                          'Age',
                          profileProvider.profile?.personalInfo?.age
                                  .toString() ??
                              "",
                        ),
                        _buildInfoRow(
                          'Student/Working Professional',
                          (() {
                            final status = profileProvider
                                .profile
                                ?.academicInfo
                                ?.studentOrWorkingProfessional
                                ?.toLowerCase();
                            if (status == 'student') return 'Student';
                            if (status != null && status.isNotEmpty)
                              return 'Working Professional';
                            return "";
                          })(),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Account Status ──────────────────────────────────
                    _buildSectionCard(
                      title: 'Account Status',
                      icon: Icons.account_circle_rounded,
                      color: AppColors.statsGreen,
                      children: [
                        _buildStatusRow(
                          'Current Status',
                          profileProvider.profile?.statusInfo?.status?.name ??
                              "",
                          isSuccess: true,
                        ),
                        _buildStatusRow(
                          'Placement Status',
                          profileProvider.profile?.statusInfo?.isPlaced == true
                              ? "Placed"
                              : "Not Placed",
                          isSuccess:
                              profileProvider.profile?.statusInfo?.isPlaced ??
                              false,
                        ),
                        _buildStatusRow(
                          'Portal Access',
                          profileProvider
                                      .profile
                                      ?.statusInfo
                                      ?.portalAccessEnabled ==
                                  true
                              ? 'Enabled'
                              : 'Disabled',
                          isSuccess:
                              profileProvider
                                  .profile
                                  ?.statusInfo
                                  ?.portalAccessEnabled ??
                              false,
                        ),
                        _buildStatusRow(
                          'Arrears Status',
                          profileProvider.profile?.academicInfo?.anyArrears ==
                                  true
                              ? 'No Arrears (Papers Cleared)'
                              : 'Has Arrears',
                          isSuccess:
                              profileProvider
                                  .profile
                                  ?.academicInfo
                                  ?.anyArrears ??
                              false,
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Your Counselor ──────────────────────────────────
                    _buildSectionCard(
                      title: 'Your Counselor',
                      icon: Icons.support_agent_rounded,
                      color: AppColors.statsOrange,
                      children: [
                        _buildInfoRow(
                          'Name',
                          profileProvider.profile?.counselor?.name ?? "",
                        ),
                        _buildInfoRow(
                          'Email',
                          profileProvider.profile?.counselor?.email ?? "",
                        ),
                        _buildInfoRow(
                          'Phone',
                          profileProvider.profile?.counselor?.phone ?? "",
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Academic Information ────────────────────────────
                    _buildSectionCard(
                      title: 'Academic Information',
                      icon: Icons.school_rounded,
                      color: AppColors.error,
                      children: [
                        _buildInfoRow(
                          'Qualification',
                          profileProvider
                                  .profile
                                  ?.academicInfo
                                  ?.qualification
                                  ?.name ??
                              "",
                        ),
                        _buildInfoRow(
                          'College',
                          profileProvider.profile?.academicInfo?.college ?? "",
                        ),
                        _buildInfoRow(
                          'Pass Out Year',
                          profileProvider.profile?.academicInfo?.passOutYear
                                  .toString() ??
                              "",
                        ),
                        _buildInfoRow(
                          'Specialization',
                          profileProvider
                                  .profile
                                  ?.academicInfo
                                  ?.specialization ??
                              "",
                        ),
                        _buildInfoRow(
                          'CGPA',
                          profileProvider.profile?.academicInfo?.cgpa
                                  ?.toString() ??
                              "",
                        ),
                        _buildStatusRow(
                          'Any Arrears',
                          profileProvider.profile?.academicInfo?.anyArrears ==
                                  true
                              ? 'Yes'
                              : "NO",
                          isSuccess:
                              profileProvider
                                      .profile
                                      ?.academicInfo
                                      ?.anyArrears ==
                                  true
                              ? false
                              : true,
                        ),
                        _buildInfoRow(
                          'Admission Date',
                          profileProvider
                                      .profile
                                      ?.academicInfo
                                      ?.admissionDate !=
                                  null
                              ? DateFormat('dd MM yyyy').format(
                                  profileProvider
                                      .profile!
                                      .academicInfo!
                                      .admissionDate!,
                                )
                              : "",
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Contact Information ─────────────────────────────
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_rounded,
                      color: AppColors.primary,
                      children: [
                        _buildInfoRow(
                          'Address',
                          profileProvider.profile?.contactInfo?.address ?? "",
                        ),
                        _buildInfoRow(
                          'District',
                          profileProvider.profile?.contactInfo?.district ?? "",
                        ),
                        _buildInfoRow(
                          'Pincode',
                          profileProvider.profile?.contactInfo?.pincode ?? "",
                        ),
                        _buildInfoRow(
                          'Preferred Location',
                          profileProvider
                                  .profile
                                  ?.contactInfo
                                  ?.preferredLocation
                                  ?.name ??
                              "",
                        ),
                        _buildInfoRow(
                          'Parent/Guardian Name',
                          profileProvider.profile?.contactInfo?.parentName ??
                              "",
                        ),
                        _buildInfoRow(
                          'Parent/Guardian Phone',
                          profileProvider.profile?.contactInfo?.parentPhone ??
                              "",
                        ),
                        _buildInfoRow(
                          'How did you hear about us?  ',
                          profileProvider.profile?.contactInfo?.howDidYouHear ??
                              "",
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Placement Information ───────────────────────────
                    _buildSectionCard(
                      title: 'Placement Information',
                      icon: Icons.work_rounded,
                      color: AppColors.statsGreen,
                      children: [
                        _buildStatusRow(
                          'Placement Assistance',
                          profileProvider
                                      .profile
                                      ?.placementInfo
                                      ?.placementAssistance ==
                                  true
                              ? "YES"
                              : "NO",
                          isSuccess:
                              profileProvider
                                  .profile
                                  ?.placementInfo
                                  ?.placementAssistance ??
                              true,
                        ),
                        _buildInfoRow(
                          'Preferred Job Location',
                          profileProvider
                                  .profile
                                  ?.placementInfo
                                  ?.preferredJobLocation ??
                              "",
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // ── Documents ───────────────────────────────────────
                    _buildSectionCard(
                      title: 'Documents',
                      icon: Icons.folder_rounded,
                      color: AppColors.statsOrange,
                      children: [
                        _buildDocumentRow('ID Proof 1', "VIEW", proof1),
                        _buildDocumentRow('ID Proof 2', "VIEW", proof2),
                      ],
                    ),

                    SizedBox(height: 20),

                    // ── App Theme (attractive new design) ───────────────
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section header
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.brightness_6_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'App Theme',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),

                              // System Default
                              _buildThemeOption(
                                label: 'System Default',
                                subtitle: 'Follows your device setting',
                                icon: Icons.settings_suggest_rounded,
                                selectedBg: [
                                  Color(0xFFF7F5FF),
                                  Color(0xFFEDE9FE),
                                ],
                                iconColor: AppColors.primary,
                                iconBg: AppColors.primary.withOpacity(0.12),
                                isDark: false,
                                isSelected:
                                    themeProvider.themeMode == ThemeMode.system,
                                onTap: () => themeProvider.setThemeMode(
                                  ThemeMode.system,
                                ),
                              ),
                              SizedBox(height: 10),

                              // Light Mode
                              _buildThemeOption(
                                label: 'Light Mode',
                                subtitle: 'Bright & clean interface',
                                icon: Icons.light_mode_rounded,
                                selectedBg: [
                                  Color(0xFFFFFBF0),
                                  Color(0xFFFEF3C7),
                                ],
                                iconColor: Color(0xFFF59E0B),
                                iconBg: Color(0xFFF59E0B).withOpacity(0.15),
                                isDark: false,
                                isSelected:
                                    themeProvider.themeMode == ThemeMode.light,
                                onTap: () =>
                                    themeProvider.setThemeMode(ThemeMode.light),
                              ),
                              SizedBox(height: 10),

                              // Dark Mode
                              _buildThemeOption(
                                label: 'Dark Mode',
                                subtitle: 'Easy on the eyes',
                                icon: Icons.dark_mode_rounded,
                                selectedBg: [
                                  Color(0xFF1E163A),
                                  Color(0xFF2E2075),
                                ],
                                iconColor: Color(0xFFB8AAFF),
                                iconBg: Colors.white.withOpacity(0.10),
                                isDark: true,
                                isSelected:
                                    themeProvider.themeMode == ThemeMode.dark,
                                onTap: () =>
                                    themeProvider.setThemeMode(ThemeMode.dark),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // ── Update Profile ──────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Update Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Reusable section widgets ───────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.statLabel)),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.statValue.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value, {
    required bool isSuccess,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.statLabel)),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.statsGreen.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: isSuccess ? AppColors.statsGreen : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String action, String proof) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          GestureDetector(
            onTap: () {
              _showFullScreenImage(context, proof);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.remove_red_eye_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    action,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  // ─── Attractive theme option tile ──────────────────────────────────────────

  Widget _buildThemeOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required List<Color> selectedBg,
    required Color iconColor,
    required Color iconBg,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? selectedBg
                : isDark
                ? [const Color(0xFF1E163A), const Color(0xFF1E163A)]
                : [AppColors.cardBackground, AppColors.cardBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark
                      ? Colors.white.withOpacity(0.12)
                      : AppColors.primary.withOpacity(0.22))
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.borderColor.withOpacity(0.3)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Animated check circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06)),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.10)),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen image viewer ────────────────────────────────────────────────

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Compact detail row (kept for backward compatibility) ────────────────────

Widget _buildCompactDetailRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.primary),
      SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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

// ── ID card arc clipper ─────────────────────────────────────────────────────

class _IdCardArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── ID card dot pattern painter ─────────────────────────────────────────────

class _IdCardDotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    const spacing = 11.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Original background painter (kept for compatibility) ────────────────────

class IdCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        canvas.drawCircle(Offset(40.0 + i * 100, 60.0 + j * 150), 20, paint);
      }
    }
    final cornerPaint = Paint()..color = AppColors.primary.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width - 20, 20), 30, cornerPaint);
    canvas.drawCircle(Offset(20, size.height - 20), 40, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
