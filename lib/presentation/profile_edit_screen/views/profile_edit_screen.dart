import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Provider.of<ProfileController>(context, listen: false).getProfileData(context: context);
    });
    super.initState();
  }

  // Text Controllers
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _whatsappController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _qualificationController = TextEditingController();
  TextEditingController _collegeController = TextEditingController();
  TextEditingController _passoutYearController = TextEditingController();
  TextEditingController _specializationController = TextEditingController();
  TextEditingController _cgpaController = TextEditingController();
  TextEditingController _admissionDateController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _districtController = TextEditingController();
  TextEditingController _pincodeController = TextEditingController();
  TextEditingController _preferredLocationController = TextEditingController();
  TextEditingController _parentNameController = TextEditingController();
  TextEditingController _parentPhoneController = TextEditingController();
  TextEditingController _hearAboutController = TextEditingController();
  TextEditingController _preferredJobLocationController = TextEditingController();

  // ── Per-field "has data from API" booleans ──────────────────────────────
  // Personal Info
  bool _hasFullName = false;
  bool _hasEmail = false;
  bool _hasPhone = false;
  bool _hasWhatsapp = false;
  bool _hasDob = false;
  bool _hasAge = false;

  // Academic Info
  bool _hasQualification = false;
  bool _hasCollege = false;
  bool _hasPassoutYear = false;
  bool _hasSpecialization = false;
  bool _hasCgpa = false;
  bool _hasStudentType = false;
  bool _hasArrears = false;
  bool _hasAdmissionDate = false;

  // Contact Info
  bool _hasAddress = false;
  bool _hasDistrict = false;
  bool _hasPincode = false;
  bool _hasPreferredLocation = false;
  bool _hasParentName = false;
  bool _hasParentPhone = false;
  bool _hasHearAbout = false;

  // Placement Info
  bool _hasPlacementAssistance = false;
  bool _hasPreferredJobLocation = false;
  // ────────────────────────────────────────────────────────────────────────

  // Dropdown Values
  String _selectedStudentType = 'Student';
  String _selectedArrears = 'Yes';
  String _selectedPlacementAssistance = 'Yes';
  bool _isActive = true;
  bool _portalAccess = true;

  // Section-level flags (kept for the "Read Only" badge on the section header)
  bool _hasPersonalInfo = false;
  bool _hasAcademicInfo = false;
  bool _hasContactInfo = false;
  bool _hasPlacementInfo = false;

  bool _initialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _qualificationController.dispose();
    _collegeController.dispose();
    _passoutYearController.dispose();
    _specializationController.dispose();
    _cgpaController.dispose();
    _admissionDateController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _preferredLocationController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _hearAboutController.dispose();
    _preferredJobLocationController.dispose();
    super.dispose();
  }

  // Helper: returns true when the string is non-null and non-empty
  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initializeWithApiData(ProfileController controller) {
    final profileData = controller.profileData;

    if (profileData != null) {
      // ── Personal Info ──────────────────────────────────────────────────
      if (profileData.personalInfo != null) {
        _hasPersonalInfo = true;
        final p = profileData.personalInfo!;

        _hasFullName = _hasValue(p.fullName);
        _fullNameController = TextEditingController(text: p.fullName ?? '');

        _hasEmail = _hasValue(p.email);
        _emailController = TextEditingController(text: p.email ?? '');

        _hasPhone = _hasValue(p.phone);
        _phoneController = TextEditingController(text: p.phone ?? '');

        _hasWhatsapp = _hasValue(p.whatsappNumber);
        _whatsappController = TextEditingController(text: p.whatsappNumber ?? '');

        _hasDob = p.dateOfBirth != null;
        _dobController = TextEditingController(text: p.dateOfBirth != null ? _formatDate(p.dateOfBirth!) : '');

        _hasAge = p.age != null;
        _ageController = TextEditingController(text: p.age?.toString() ?? '');
      }

      // ── Academic Info ──────────────────────────────────────────────────
      if (profileData.academicInfo != null) {
        _hasAcademicInfo = true;
        final a = profileData.academicInfo!;

        _hasQualification = _hasValue(a.qualification?.name);
        _qualificationController = TextEditingController(text: a.qualification?.name ?? '');

        _hasCollege = _hasValue(a.college);
        _collegeController = TextEditingController(text: a.college ?? '');

        _hasPassoutYear = a.passOutYear != null;
        _passoutYearController = TextEditingController(text: a.passOutYear?.toString() ?? '');

        _hasSpecialization = _hasValue(a.specialization);
        _specializationController = TextEditingController(text: a.specialization ?? '');

        _hasCgpa = a.cgpa != null;
        _cgpaController = TextEditingController(text: a.cgpa?.toString() ?? '');

        _hasStudentType = _hasValue(a.studentOrWorkingProfessional);
        if (_hasStudentType) _selectedStudentType = a.studentOrWorkingProfessional!;

        _hasArrears = a.anyArrears != null;
        if (_hasArrears) _selectedArrears = a.anyArrears! ? 'Yes' : 'No';

        _hasAdmissionDate = a.admissionDate != null;
        _admissionDateController = TextEditingController(
          text: a.admissionDate != null ? _formatDate(a.admissionDate!) : '',
        );
      }

      // ── Contact Info ───────────────────────────────────────────────────
      if (profileData.contactInfo != null) {
        _hasContactInfo = true;
        final c = profileData.contactInfo!;

        _hasAddress = _hasValue(c.address);
        _addressController = TextEditingController(text: c.address ?? '');

        _hasDistrict = _hasValue(c.district);
        _districtController = TextEditingController(text: c.district ?? '');

        _hasPincode = _hasValue(c.pincode);
        _pincodeController = TextEditingController(text: c.pincode ?? '');

        _hasPreferredLocation = _hasValue(c.preferredLocation?.name);
        _preferredLocationController = TextEditingController(text: c.preferredLocation?.name ?? '');

        _hasParentName = _hasValue(c.parentName);
        _parentNameController = TextEditingController(text: c.parentName ?? '');

        _hasParentPhone = _hasValue(c.parentPhone);
        _parentPhoneController = TextEditingController(text: c.parentPhone ?? '');

        _hasHearAbout = _hasValue(c.howDidYouHear);
        _hearAboutController = TextEditingController(text: c.howDidYouHear ?? '');
      }

      // ── Placement Info ─────────────────────────────────────────────────
      if (profileData.placementInfo != null) {
        _hasPlacementInfo = true;
        final pl = profileData.placementInfo!;

        _hasPlacementAssistance = pl.placementAssistance != null;
        if (_hasPlacementAssistance) {
          _selectedPlacementAssistance = pl.placementAssistance! ? 'Yes' : 'No';
        }

        _hasPreferredJobLocation = _hasValue(pl.preferredJobLocation);
        _preferredJobLocationController = TextEditingController(text: pl.preferredJobLocation ?? '');
      }

      // ── Status Info ────────────────────────────────────────────────────
      if (profileData.statusInfo != null) {
        _portalAccess = profileData.statusInfo!.portalAccessEnabled ?? true;
        _isActive = !(profileData.statusInfo!.isAlumni ?? false);
      }
    }

    _initialized = true;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        if (controller.profileData != null && !_initialized) {
          _initializeWithApiData(controller);
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
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                              ),
                              child: const Center(child: Icon(Icons.person_rounded, color: AppColors.white, size: 50)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 5)],
                                ),
                                child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
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

                  // Personal Information
                  _buildEditSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    color: AppColors.primary,
                    hasData: _hasPersonalInfo,
                    children: [
                      _buildTextField('Full Name', _fullNameController, isEditable: !_hasFullName),
                      _buildTextField(
                        'Email Address',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                        isEditable: !_hasEmail,
                      ),
                      _buildTextField(
                        'Phone Number',
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        isEditable: !_hasPhone,
                      ),
                      _buildTextField(
                        'WhatsApp Number',
                        _whatsappController,
                        keyboardType: TextInputType.phone,
                        isEditable: !_hasWhatsapp,
                      ),
                      _buildTextField('Date of Birth', _dobController, isEditable: !_hasDob),
                      _buildTextField('Age', _ageController, keyboardType: TextInputType.number, isEditable: !_hasAge),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Academic Information
                  _buildEditSection(
                    title: 'Academic Information',
                    icon: Icons.school_rounded,
                    color: const Color(0xFFFF7675),
                    hasData: _hasAcademicInfo,
                    children: [
                      _buildTextField('Qualification', _qualificationController, isEditable: !_hasQualification),
                      _buildTextField('College', _collegeController, isEditable: !_hasCollege),
                      _buildTextField(
                        'Pass Out Year',
                        _passoutYearController,
                        keyboardType: TextInputType.number,
                        isEditable: !_hasPassoutYear,
                      ),
                      _buildTextField('Specialization', _specializationController, isEditable: !_hasSpecialization),
                      _buildTextField(
                        'CGPA',
                        _cgpaController,
                        keyboardType: TextInputType.number,
                        isEditable: !_hasCgpa,
                      ),
                      _buildDropdownField(
                        'Student/Working Professional',
                        ['Student', 'Working Professional'],
                        _selectedStudentType,
                        (value) => setState(() => _selectedStudentType = value!),
                        isEditable: !_hasStudentType,
                      ),
                      _buildDropdownField(
                        'Any Arrears',
                        ['Yes', 'No'],
                        _selectedArrears,
                        (value) => setState(() => _selectedArrears = value!),
                        isEditable: !_hasArrears,
                      ),
                      _buildTextField('Admission Date', _admissionDateController, isEditable: !_hasAdmissionDate),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Contact Information
                  _buildEditSection(
                    title: 'Contact Information',
                    icon: Icons.contact_phone_rounded,
                    color: AppColors.statsGreen,
                    hasData: _hasContactInfo,
                    children: [
                      _buildTextField('Address', _addressController, isEditable: !_hasAddress),
                      _buildTextField('District', _districtController, isEditable: !_hasDistrict),
                      _buildTextField(
                        'Pincode',
                        _pincodeController,
                        keyboardType: TextInputType.number,
                        isEditable: !_hasPincode,
                      ),
                      _buildTextField(
                        'Preferred Location',
                        _preferredLocationController,
                        isEditable: !_hasPreferredLocation,
                      ),
                      _buildTextField('Parent/Guardian Name', _parentNameController, isEditable: !_hasParentName),
                      _buildTextField(
                        'Parent/Guardian Phone',
                        _parentPhoneController,
                        keyboardType: TextInputType.phone,
                        isEditable: !_hasParentPhone,
                      ),
                      _buildTextField('How did you hear about us?', _hearAboutController, isEditable: !_hasHearAbout),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Placement Information
                  _buildEditSection(
                    title: 'Placement Information',
                    icon: Icons.work_rounded,
                    color: AppColors.statsOrange,
                    hasData: _hasPlacementInfo,
                    children: [
                      _buildDropdownField(
                        'Placement Assistance',
                        ['Yes', 'No'],
                        _selectedPlacementAssistance,
                        (value) => setState(() => _selectedPlacementAssistance = value!),
                        isEditable: !_hasPlacementAssistance,
                      ),
                      _buildTextField(
                        'Preferred Job Location',
                        _preferredJobLocationController,
                        isEditable: !_hasPreferredJobLocation,
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
                        onPressed: _showSuccessDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    );
  }

  // ── Section container (unchanged) ──────────────────────────────────────
  Widget _buildEditSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool hasData,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.sectionTitle),
              const SizedBox(width: 8),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Read Only',
                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ── Field builders (unchanged) ──────────────────────────────────────────
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
          if (!isEditable)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                'This information is from your profile and cannot be edited',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
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
                      item,
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
          if (!isEditable)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                'This information is from your profile and cannot be edited',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
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
                decoration: BoxDecoration(color: AppColors.statsGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: AppColors.statsGreen, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profile Updated!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                    Navigator.pop(context);
                    Navigator.pop(context);
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
