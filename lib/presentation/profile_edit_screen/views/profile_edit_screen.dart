import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/profile_edit_screen/controller/profile_edit_controller.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final profileController = Provider.of<ProfileController>(context, listen: false);
      if (profileController.profileData == null) {
        await profileController.getProfileData(context: context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditController(),
      child: Consumer2<ProfileController, ProfileEditController>(
        builder: (context, profileController, editController, child) {
          if (profileController.profileData != null && !_initialized) {
            editController.init(profileController.profileData, notify: false);
            _initialized = true;
          }

          if (profileController.isLoading && !_initialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
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
                              icon: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),

                    // Profile Picture
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
                                  image: profileController.profileData?.personalInfo?.profilePicture != null
                                    ? DecorationImage(
                                        image: NetworkImage(profileController.profileData!.personalInfo!.profilePicture!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                ),
                                child: profileController.profileData?.personalInfo?.profilePicture == null
                                  ? const Center(child: Icon(Icons.person_rounded, color: AppColors.white, size: 50))
                                  : null,
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
                                          blurRadius: 5)
                                    ],
                                  ),
                                  child: Icon(Icons.camera_alt_rounded,
                                      color: AppColors.primary, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Tap to change photo',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Information
                    _buildEditSection(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      color: AppColors.primary,
                      children: [
                        _buildTextField('Full Name', editController.fullNameController,
                            isEditable: false),
                        _buildTextField('Email Address', editController.emailController,
                            keyboardType: TextInputType.emailAddress, isEditable: false),
                        _buildTextField('Phone Number', editController.phoneController,
                            keyboardType: TextInputType.phone, isEditable: false),
                        _buildTextField('WhatsApp Number', editController.whatsappController,
                            keyboardType: TextInputType.phone),
                        _buildDatePicker('Date of Birth', editController.dobController, () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) editController.updateDob(date);
                        }),
                        _buildTextField('Age', editController.ageController,
                            keyboardType: TextInputType.number, isEditable: false),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Academic Information
                    _buildEditSection(
                      title: 'Academic Information',
                      icon: Icons.school_rounded,
                      color: const Color(0xFFFF7675),
                    children: [
                        _buildTextField('Qualification', editController.qualificationController),
                        _buildTextField('College', editController.collegeController),
                        _buildTextField('Pass Out Year', editController.passoutYearController,
                            keyboardType: TextInputType.number),
                        _buildTextField('Specialization', editController.specializationController),
                        _buildTextField('CGPA', editController.cgpaController,
                            keyboardType: TextInputType.number),
                        _buildDropdownField(
                          'Student/Working Professional',
                          ['student', 'working_professional'],
                          editController.selectedStudentType,
                          (value) => editController.selectedStudentType = value!,
                        ),
                        _buildDropdownField(
                          'Any Arrears',
                          ['Yes', 'No'],
                          editController.anyArrears ? 'Yes' : 'No',
                          (value) => editController.anyArrears = value == 'Yes',
                        ),
                        _buildDatePicker('Admission Date', editController.admissionDateController,
                            () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) editController.updateAdmissionDate(date);
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Contact Information
                    _buildEditSection(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_rounded,
                      color: AppColors.statsGreen,
                      children: [
                        _buildTextField('Address', editController.addressController),
                        _buildTextField('District', editController.districtController),
                        _buildTextField('Pincode', editController.pincodeController,
                            keyboardType: TextInputType.number),
                        _buildTextField('Preferred Location',
                            editController.preferredLocationController),
                        _buildTextField('Parent/Guardian Name', editController.parentNameController),
                        _buildTextField('Parent/Guardian Phone', editController.parentPhoneController,
                            keyboardType: TextInputType.phone),
                        _buildTextField('How did you hear about us?', editController.hearAboutController),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Placement Information
                    _buildEditSection(
                      title: 'Placement Information',
                      icon: Icons.work_rounded,
                      color: AppColors.statsOrange,
                      children: [
                        _buildDropdownField(
                          'Placement Assistance',
                          ['Yes', 'No'],
                          editController.placementAssistance ? 'Yes' : 'No',
                          (value) => editController.placementAssistance = value == 'Yes',
                        ),
                        _buildTextField('Preferred Job Location',
                            editController.preferredJobLocationController),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Save Button
                    if (editController.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(editController.error!, style: const TextStyle(color: Colors.red)),
                      ),
                    
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
                          onPressed: editController.isSubmitting
                              ? null
                              : () async {
                                  final success = await editController.updateProfile(
                                      context, profileController.profileData);
                                  if (success && mounted) {
                                    _showSuccessDialog();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: editController.isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
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
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
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
                    color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.statLabel),
              if (!isEditable) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSecondary),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isEditable ? const Color(0xFFF1F3FA) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isEditable ? AppColors.borderLight : Colors.grey.shade300),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: isEditable,
              style: TextStyle(
                fontSize: 14,
                color: isEditable ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                hintText: isEditable ? 'Enter $label' : 'Cannot edit',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Select $label' : controller.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: controller.text.isEmpty
                            ? AppColors.textSecondary.withOpacity(0.5)
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                ],
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
    Function(String?) onChanged, {
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.statLabel),
              if (!isEditable) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSecondary),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isEditable ? const Color(0xFFF1F3FA) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isEditable ? AppColors.borderLight : Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isEditable ? AppColors.primary : AppColors.textSecondary,
                ),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 14,
                        color: isEditable ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: isEditable ? onChanged : null,
              ),
            ),
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
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.statsGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: AppColors.statsGreen, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profile Updated!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your changes have been saved successfully.',
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close edit screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
