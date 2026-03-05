import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Text Controllers
  final _fullNameController = TextEditingController(text: 'amnanabeel');
  final _emailController = TextEditingController(text: 'test57@gmail.com');
  final _phoneController = TextEditingController(text: '+913434343435');
  final _whatsappController = TextEditingController(text: '+913434343435');
  final _dobController = TextEditingController(text: '12/03/2026');
  final _ageController = TextEditingController(text: '-1');
  final _qualificationController = TextEditingController(
    text: 'M.Sc-Chemistry',
  );
  final _collegeController = TextEditingController(text: 'EWREWR');
  final _passoutYearController = TextEditingController(text: '2028');
  final _specializationController = TextEditingController(text: 'CS');
  final _cgpaController = TextEditingController(text: '1');
  final _admissionDateController = TextEditingController(text: '02/03/2026');
  final _addressController = TextEditingController(text: 'B');
  final _districtController = TextEditingController(text: 'Out of State');
  final _pincodeController = TextEditingController(text: '345345');
  final _preferredLocationController = TextEditingController(text: 'Cochin');
  final _parentNameController = TextEditingController(text: 'WEREW');
  final _parentPhoneController = TextEditingController(text: '+915555555555');
  final _hearAboutController = TextEditingController(text: 'facebook');
  final _preferredJobLocationController = TextEditingController(text: 'WER');

  // Dropdown Values
  String _selectedStudentType = 'Student';
  String _selectedArrears = 'Yes';
  String _selectedPlacementAssistance = 'Yes';
  bool _isActive = true;
  bool _portalAccess = true;

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
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.white,
                              size: 50,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Tap to change photo', style: AppTextStyles.caption),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Personal Information Section
              _buildEditSection(
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
                color: AppColors.primary,
                children: [
                  _buildTextField('Full Name', _fullNameController),
                  _buildTextField(
                    'Email Address',
                    _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    'Phone Number',
                    _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    'WhatsApp Number',
                    _whatsappController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField('Date of Birth', _dobController),
                  _buildTextField(
                    'Age',
                    _ageController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildDropdownField(
                    'Student/Working Professional',
                    ['Student', 'Working Professional'],
                    _selectedStudentType,
                    (value) => setState(() => _selectedStudentType = value!),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Academic Information Section
              _buildEditSection(
                title: 'Academic Information',
                icon: Icons.school_rounded,
                color: const Color(0xFFFF7675),
                children: [
                  _buildTextField('Qualification', _qualificationController),
                  _buildTextField('College', _collegeController),
                  _buildTextField(
                    'Pass Out Year',
                    _passoutYearController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField('Specialization', _specializationController),
                  _buildTextField(
                    'CGPA',
                    _cgpaController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildDropdownField(
                    'Any Arrears',
                    ['Yes', 'No'],
                    _selectedArrears,
                    (value) => setState(() => _selectedArrears = value!),
                  ),
                  _buildTextField('Admission Date', _admissionDateController),
                ],
              ),

              const SizedBox(height: 16),

              // Contact Information Section
              _buildEditSection(
                title: 'Contact Information',
                icon: Icons.contact_phone_rounded,
                color: AppColors.statsGreen,
                children: [
                  _buildTextField('Address', _addressController),
                  _buildTextField('District', _districtController),
                  _buildTextField(
                    'Pincode',
                    _pincodeController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    'Preferred Location',
                    _preferredLocationController,
                  ),
                  _buildTextField(
                    'Parent/Guardian Name',
                    _parentNameController,
                  ),
                  _buildTextField(
                    'Parent/Guardian Phone',
                    _parentPhoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    'How did you hear about us?',
                    _hearAboutController,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Placement Information Section
              _buildEditSection(
                title: 'Placement Information',
                icon: Icons.work_rounded,
                color: AppColors.statsOrange,
                children: [
                  _buildDropdownField(
                    'Placement Assistance',
                    ['Yes', 'No'],
                    _selectedPlacementAssistance,
                    (value) =>
                        setState(() => _selectedPlacementAssistance = value!),
                  ),
                  _buildTextField(
                    'Preferred Job Location',
                    _preferredJobLocationController,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Save Button
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
                      _showSuccessDialog();
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
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditSection({
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.primary,
                ),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statValue),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.statsGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.statsGreen,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profile Updated!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your changes have been saved successfully.',
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // Return to profile screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
