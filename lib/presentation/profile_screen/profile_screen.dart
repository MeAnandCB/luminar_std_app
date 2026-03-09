import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';
import 'package:luminar_std/presentation/profile_edit_screen/profile_edit_screen.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/test_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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
                    // Header with back button and title
                    Padding(
                      padding: const EdgeInsets.all(20),
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
                              const SizedBox(width: 16),
                              const Text(
                                'My Profile',
                                style: TextStyle(
                                  fontSize: 22,
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
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.whiteWithOpacity20,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 20),
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
                                const SizedBox(height: 4),
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'This is also your referral code',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.whiteWithOpacity80,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
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

                    const SizedBox(height: 20),

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
                          profileProvider
                                  .profile
                                  ?.academicInfo
                                  ?.studentOrWorkingProfessional ??
                              "",
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

                    // Academic Information Card
                    _buildSectionCard(
                      title: 'Academic Information',
                      icon: Icons.school_rounded,
                      color: const Color(0xFFFF7675),
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
                        _buildInfoRow('CGPA', '1'),
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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

                    // Documents Card
                    _buildSectionCard(
                      title: 'Documents',
                      icon: Icons.folder_rounded,
                      color: AppColors.statsOrange,
                      children: [
                        _buildDocumentRow(
                          'ID Proof 1',
                          "VIEW",
                          proof1,
                          // profileProvider.profile?.personalInfo?.idProof ?? "",
                        ),
                        _buildDocumentRow('ID Proof 2', "VIEW", proof2),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.statLabel)),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.statsGreen.withOpacity(0.1)
                    : const Color(0xFFFF7675).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: isSuccess
                      ? AppColors.statsGreen
                      : const Color(0xFFFF7675),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          GestureDetector(
            onTap: () {
              _showFullScreenImage(context, proof);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  const SizedBox(width: 4),
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
}
