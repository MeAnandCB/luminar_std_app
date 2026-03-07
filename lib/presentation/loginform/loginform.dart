import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // Form keys
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _fullNameController = TextEditingController(text: 'sumesh');
  final _emailController = TextEditingController(text: 'test58@gamil.com');
  final _phoneController = TextEditingController(text: '+91 12345-67890');
  final _whatsappController = TextEditingController(text: '+91 12345-67890');
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _collegeNameController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _preferredLocationController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController(text: '+91 12345-67895');

  // Dropdown selections
  String? _selectedQualification;
  String? _selectedSpecialization;
  String? _selectedPassOutYear;
  String? _selectedCurrentStatus = 'Student';
  bool _hasArrears = false;
  bool _placementAssistance = false;

  // District auto-fill flag
  String _districtText = 'District will auto-fill from pincode';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Complete Profile',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fields remaining indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statsOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.statsOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.statsOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '12 fields remaining',
                      style: TextStyle(
                        color: AppColors.statsOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Picture Section
              _buildSectionTitle('Profile Picture'),
              const SizedBox(height: 12),
              _buildUploadArea(
                'Upload',
                'JPG, PNG, PDF • Max 5MB each',
                icon: Icons.cloud_upload_outlined,
              ),

              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),

              _buildTextField(
                'Full Name',
                controller: _fullNameController,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Email',
                controller: _emailController,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Phone',
                controller: _phoneController,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'WhatsApp',
                controller: _whatsappController,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Date of Birth',
                controller: _dobController,
                hintText: 'dd/mm/yyyy',
                suffixIcon: Icons.calendar_today,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Address',
                controller: _addressController,
                hintText: 'Enter your complete address',
                maxLines: 3,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Pincode',
                controller: _pincodeController,
                hintText: '6-digit pincode',
                keyboardType: TextInputType.number,
                maxLength: 6,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 8),

              _buildDistrictAutoFill(),

              const SizedBox(height: 24),

              // ID Proof Section
              _buildSectionTitle('ID Proof (Both sides required)'),
              const SizedBox(height: 16),

              _buildUploadCard(
                'Front Side',
                'Upload the front side of your ID proof (Aadhar, PAN, etc.) as JPG, PNG, or PDF',
                isRequired: true, // Required field
              ),
              const SizedBox(height: 12),
              _buildUploadCard(
                'Back Side',
                'Upload the back side of your ID proof (Aadhar, PAN, etc.) as JPG, PNG, or PDF',
                isRequired: true, // Required field
              ),

              const SizedBox(height: 24),

              // Academic Information Section
              _buildSectionTitle('Academic Information'),
              const SizedBox(height: 16),

              // Qualification and Specialization in one row
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Qualification',
                      value: _selectedQualification,
                      items: ['B.Tech', 'M.Tech', 'BCA', 'MCA', 'B.Sc', 'M.Sc'],
                      onChanged: (value) =>
                          setState(() => _selectedQualification = value),
                      hintText: 'Select qualification',
                      isRequired: true, // Required field
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'Specialization',
                      value: _selectedSpecialization,
                      items: [
                        'Computer Science',
                        'Electronics',
                        'Mechanical',
                        'Civil',
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedSpecialization = value),
                      hintText: 'Select specialization',
                      isRequired: true, // Required field
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // College/University and Pass Out Year in one row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'College/University',
                      controller: _collegeNameController,
                      hintText: 'College name',
                      isRequired: true, // Required field
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'Pass Out Year',
                      value: _selectedPassOutYear,
                      items: ['2020', '2021', '2022', '2023', '2024', '2025'],
                      onChanged: (value) =>
                          setState(() => _selectedPassOutYear = value),
                      hintText: 'Select year',
                      isRequired: true, // Required field
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CGPA and Any Arrears in one row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'CGPA',
                      controller: _cgpaController,
                      hintText: 'e.g., 8.5',
                      keyboardType: TextInputType.number,
                      isRequired: true, // Required field
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Any Arrears?',
                              style: AppTextStyles.bodyText1,
                            ),
                            Text(
                              ' *',
                              style: TextStyle(color: AppColors.error),
                            ), // Required field
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.cardBackground,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Radio(
                                      value: false,
                                      groupValue: _hasArrears,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) =>
                                          setState(() => _hasArrears = false),
                                    ),
                                    const Text('No'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Radio(
                                      value: true,
                                      groupValue: _hasArrears,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) =>
                                          setState(() => _hasArrears = true),
                                    ),
                                    const Text('Yes'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Career Information Section
              _buildSectionTitle('Career Information'),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Current Status', style: AppTextStyles.bodyText1),
                      Text(
                        ' *',
                        style: TextStyle(color: AppColors.error),
                      ), // Required field
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusSelector(),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Preferred Job Location',
                controller: _preferredLocationController,
                hintText: 'e.g., Cochin, Trivandrum, Thrissur, Calicut',
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildCheckboxTile(),

              const SizedBox(height: 24),

              // Parent/Guardian Section
              _buildSectionTitle('Parent/Guardian'),
              const SizedBox(height: 16),

              _buildTextField(
                'Name',
                controller: _parentNameController,
                isRequired: true, // Required field
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Phone',
                controller: _parentPhoneController,
                isRequired: true, // Required field
                suffixText: 'WEREW',
              ),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.sectionTitle);
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    IconData? suffixIcon,
    bool isRequired = false,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.bodyText1),
            if (isRequired)
              Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          style: AppTextStyles.bodyText2,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 20, color: AppColors.textSecondary)
                : null,
            suffixText: suffixText,
            suffixStyle: AppTextStyles.caption,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label, {
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.bodyText1),
            if (isRequired)
              Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(
              color: value == null && isRequired
                  ? AppColors.error.withOpacity(0.5)
                  : AppColors.borderColor,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.cardBackground,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hintText ?? 'Select $label',
                style: value == null && isRequired
                    ? AppTextStyles.hintText.copyWith(
                        color: AppColors.error.withOpacity(0.7),
                      )
                    : AppTextStyles.hintText,
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              style: AppTextStyles.bodyText2,
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea(
    String title,
    String subtitle, {
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildUploadCard(
    String title,
    String subtitle, {
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.cardBackground,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRequired)
                      Text(' *', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Upload',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictAutoFill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _districtText,
              style: _districtText.contains('auto-fill')
                  ? AppTextStyles.hintText
                  : AppTextStyles.bodyText2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Student',
            isSelected: _selectedCurrentStatus == 'Student',
            onTap: () => setState(() => _selectedCurrentStatus = 'Student'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Working Professional',
            isSelected: _selectedCurrentStatus == 'Working Professional',
            onTap: () =>
                setState(() => _selectedCurrentStatus = 'Working Professional'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.cardBackground,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile() {
    return CheckboxListTile(
      title: Text(
        'I am interested in placement assistance',
        style: AppTextStyles.bodyText2,
      ),
      value: _placementAssistance,
      activeColor: AppColors.primary,
      onChanged: (value) =>
          setState(() => _placementAssistance = value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Handle form submission
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile saved successfully!')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Text('Save Profile', style: AppTextStyles.buttonText),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _collegeNameController.dispose();
    _cgpaController.dispose();
    _preferredLocationController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }
}
