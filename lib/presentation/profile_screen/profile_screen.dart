import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/profile_edit_screen/profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                          const Text(
                            'Amnanabeel',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: LUM2026082',
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
                                child: const Text(
                                  'Active',
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
                  _buildInfoRow('Full Name', 'amnanabeel'),
                  _buildInfoRow('Email Address', 'test57@gmail.com'),
                  _buildInfoRow('Phone Number', '+913434343435'),
                  _buildInfoRow('WhatsApp Number', '+913434343435'),
                  _buildInfoRow('Date of Birth', '12/03/2026'),
                  _buildInfoRow('Age', '-1 years'),
                  _buildInfoRow('Student/Working Professional', 'Student'),
                ],
              ),

              const SizedBox(height: 16),

              // Account Status Card
              _buildSectionCard(
                title: 'Account Status',
                icon: Icons.account_circle_rounded,
                color: AppColors.statsGreen,
                children: [
                  _buildStatusRow('Current Status', 'Active', isSuccess: true),
                  _buildStatusRow(
                    'Placement Status',
                    'Not Placed',
                    isSuccess: false,
                  ),
                  _buildStatusRow('Portal Access', 'Enabled', isSuccess: true),
                  _buildStatusRow(
                    'Arrears Status',
                    'Has Arrears',
                    isSuccess: false,
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
                  _buildInfoRow('Name', 'Admission Counselor'),
                  _buildInfoRow('Email', 'admissioncounselor@gmail.com'),
                  _buildInfoRow('Phone', '912222233333'),
                ],
              ),

              const SizedBox(height: 16),

              // Academic Information Card
              _buildSectionCard(
                title: 'Academic Information',
                icon: Icons.school_rounded,
                color: const Color(0xFFFF7675),
                children: [
                  _buildInfoRow('Qualification', 'M.Sc-Chemistry'),
                  _buildInfoRow('College', 'EWREWR'),
                  _buildInfoRow('Pass Out Year', '2028'),
                  _buildInfoRow('Specialization', 'CS'),
                  _buildInfoRow('CGPA', '1'),
                  _buildStatusRow('Any Arrears', 'Yes', isSuccess: false),
                  _buildInfoRow('Admission Date', '02/03/2026'),
                ],
              ),

              const SizedBox(height: 16),

              // Contact Information Card
              _buildSectionCard(
                title: 'Contact Information',
                icon: Icons.contact_phone_rounded,
                color: AppColors.primary,
                children: [
                  _buildInfoRow('Address', 'B'),
                  _buildInfoRow('District', 'Out of State'),
                  _buildInfoRow('Pincode', '345345'),
                  _buildInfoRow('Preferred Location', 'Cochin'),
                  _buildInfoRow('Parent/Guardian Name', 'WEREW'),
                  _buildInfoRow('Parent/Guardian Phone', '+915555555555'),
                  _buildInfoRow('How did you hear about us?', 'facebook'),
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
                    'Yes',
                    isSuccess: true,
                  ),
                  _buildInfoRow('Preferred Job Location', 'WER'),
                ],
              ),

              const SizedBox(height: 16),

              // Documents Card
              _buildSectionCard(
                title: 'Documents',
                icon: Icons.folder_rounded,
                color: AppColors.statsOrange,
                children: [
                  _buildDocumentRow('ID Proof 1', 'View'),
                  _buildDocumentRow('ID Proof 2', 'View'),
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

  Widget _buildDocumentRow(String label, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $label...'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
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
}
