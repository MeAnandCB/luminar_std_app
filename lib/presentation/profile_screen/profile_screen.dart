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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
      Navigator.pop(context); // Close loading dialog
      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showStudentIdCard(BuildContext context, ProfileController provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              'Student ID Card',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Show this card for identification',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),

            SizedBox(height: 20),

            // ID Card
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _buildStudentIdCard(provider),
                ),
              ),
            ),

            // Download button
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadIdCard(),
                      icon: Icon(Icons.download_rounded),
                      label: Text('Download ID Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

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

          Share.shareXFiles([XFile(file.path)], text: 'My Student ID Card');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStudentIdCard(ProfileController provider) {
    final fullName = provider.profile?.personalInfo?.fullName ?? '';
    final studentId = provider.profile?.personalInfo?.studentId ?? '';
    final course = widget.course;
    final email = provider.profile?.personalInfo?.email ?? '';
    final phone = provider.profile?.personalInfo?.phone ?? '';
    final profilePic = provider.profile?.personalInfo?.profilePicture;

    return Container(
      width: 320, // Reduced width
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background decorative elements
            CustomPaint(
              size: const Size(320, 450), // Fixed size
              painter: IdCardBackgroundPainter(),
            ),

            // Main content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Reduced height
                Container(
                  width: double.infinity,
                  height: 70, // Fixed height
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF8B7BF2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -15,
                        left: -15,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        right: -10,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Header text
                      Center(
                        child: Text(
                          'STUDENT ID CARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body - Reduced padding
                Padding(
                  padding: EdgeInsets.all(12), // Reduced padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile Image - Smaller
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image:
                                          profilePic != null &&
                                              profilePic.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(profilePic),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        profilePic == null || profilePic.isEmpty
                                        ? Icon(
                                            Icons.person_rounded,
                                            color: Color(0xFF6C5CE7),
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Name
                      Text(
                        fullName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4),

                      // ID Number
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF6C5CE7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: $studentId',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Details Container - Compact
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF6C5CE7).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactDetailRow(
                              Icons.school_rounded,
                              'COURSE',
                              course,
                            ),
                            Divider(height: 8),
                            _buildCompactDetailRow(
                              Icons.email_rounded,
                              'EMAIL',
                              email,
                            ),
                            Divider(height: 8),
                            _buildCompactDetailRow(
                              Icons.phone_rounded,
                              'PHONE',
                              phone,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12),

                      // Footer - Compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Luminar Technolab',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'Educational Institution',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFF6C5CE7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFF6C5CE7),
                              size: 16,
                            ),
                          ),
                        ],
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
  }

  Widget _buildIdDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16, // Reduced from 18
          color: Color(0xFF6C5CE7),
        ),
        SizedBox(width: 8), // Reduced from 12
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important!
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Reduced from 11
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12, // Reduced from 13
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    // Header with back button, title, ID card icon and logout
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
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

                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
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
                              onPressed: () {
                                // Logout Button
                                _showLogoutConfirmation(context);
                              },
                              icon: Icon(
                                Icons.logout,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Header Card
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
                              image: profileProvider.profile?.personalInfo
                                              ?.profilePicture !=
                                          null &&
                                      profileProvider.profile!.personalInfo!
                                          .profilePicture!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(profileProvider
                                          .profile!
                                          .personalInfo!
                                          .profilePicture!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profileProvider.profile?.personalInfo
                                            ?.profilePicture ==
                                        null ||
                                    profileProvider.profile!.personalInfo!
                                        .profilePicture!.isEmpty
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

                    // Personal Information Card
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
                            final status = profileProvider.profile?.academicInfo
                                ?.studentOrWorkingProfessional
                                ?.toLowerCase();
                            if (status == 'student') return 'Student';
                            if (status != null && status.isNotEmpty) {
                              return 'Working Professional';
                            }
                            return "";
                          })(),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Account Status Card
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

                    // Your Counselor Card
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

                    // Academic Information Card
                    _buildSectionCard(
                      title: 'Academic Information',
                      icon: Icons.school_rounded,
                      color: Color(0xFFFF7675),
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

                    // Contact Information Card
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

                    // Placement Information Card
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

                    // Documents Card
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

                    // App Theme Card
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildSectionCard(
                          title: 'App Theme',
                          icon: Icons.brightness_6_rounded,
                          color: AppColors.primary,
                          children: [
                            _buildThemeOption(
                              label: 'System Default',
                              icon: Icons.settings_suggest_rounded,
                              isSelected: themeProvider.themeMode == ThemeMode.system,
                              onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                            ),
                            Divider(height: 8),
                            _buildThemeOption(
                              label: 'Light Mode',
                              icon: Icons.light_mode_rounded,
                              isSelected: themeProvider.themeMode == ThemeMode.light,
                              onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                            ),
                            Divider(height: 8),
                            _buildThemeOption(
                              label: 'Dark Mode',
                              icon: Icons.dark_mode_rounded,
                              isSelected: themeProvider.themeMode == ThemeMode.dark,
                              onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // Quick Actions
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
                  color: isSuccess
                      ? AppColors.statsGreen
                      : AppColors.error,
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

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

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

// Compact detail row for better space management
Widget _buildCompactDetailRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: Color(0xFF6C5CE7)),
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

// Updated CustomPainter
class IdCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle circles pattern
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        canvas.drawCircle(Offset(40.0 + i * 100, 60.0 + j * 150), 20, paint);
      }
    }

    // Draw corner accents
    final cornerPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.1);

    // Top right corner
    canvas.drawCircle(Offset(size.width - 20, 20), 30, cornerPaint);

    // Bottom left corner
    canvas.drawCircle(Offset(20, size.height - 20), 40, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
