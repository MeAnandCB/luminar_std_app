// lib/screens/profile_completion_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/complete_your_profile/controller/complete_profile_controller.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:provider/provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  final _personalInfoKey = GlobalKey<PersonalInfoSectionState>();
  final _idProofKey = GlobalKey<IdProofSectionState>();
  final _academicInfoKey = GlobalKey<AcademicInfoSectionState>();
  final _careerInfoKey = GlobalKey<CareerInfoSectionState>();
  final _parentInfoKey = GlobalKey<ParentInfoSectionState>();

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _personalInfoKey.currentState?.validate() ?? false;
      case 1:
        return _idProofKey.currentState?.validate() ?? false;
      case 2:
        return _academicInfoKey.currentState?.validate() ?? false;
      case 3:
        return _careerInfoKey.currentState?.validate() ?? false;
      case 4:
        return _parentInfoKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<ProfileController>(context, listen: false).getProfileData(context: context);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () {
                  if (_currentPage > 0) {
                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
              )
            : null,
      ),
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swiping until valid
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                PersonalInfoSection(key: _personalInfoKey),
                IdProofSection(key: _idProofKey),
                AcademicInfoSection(key: _academicInfoKey),
                CareerInfoSection(key: _careerInfoKey),
                ParentInfoSection(key: _parentInfoKey),
              ],
            ),
          ),
          if (_currentPage < _totalPages - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_validateCurrentPage()) {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: Text('Next'),
              ),
            )
          else if (_currentPage == _totalPages - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_validateCurrentPage()) {
                    // Submit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile completed successfully!'),
                        backgroundColor: AppColors.statusActive,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusActive,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('Submit'),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Complete Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '37%',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.37,
              backgroundColor: AppColors.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text('12 fields remaining', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class PersonalInfoSection extends StatefulWidget {
  const PersonalInfoSection({super.key});

  @override
  State<PersonalInfoSection> createState() => PersonalInfoSectionState();
}

class PersonalInfoSectionState extends State<PersonalInfoSection> {
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  String? _countryCode = '+91';
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  bool _initialized = false;
  bool _hasFullName = false;
  bool _hasEmail = false;
  bool _hasPhone = false;
  bool _hasAddress = false;
  bool _hasPincode = false;
  bool _hasDistrict = false;
  bool _hasProfilePic = false;
  String? _profilePicUrl;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     final controller = context.read<ProfileController>();
  //     if (controller.profileData != null) {
  //       _initData(controller);
  //     }
  //   });
  // }

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final pInfo = controller.profileData!.personalInfo;
    final cInfo = controller.profileData!.contactInfo;

    if (pInfo != null) {
      _hasFullName = _hasValue(pInfo.fullName);
      if (_hasFullName) _fullNameController.text = pInfo.fullName!;

      _hasEmail = _hasValue(pInfo.email);
      if (_hasEmail) _emailController.text = pInfo.email!;

      _hasPhone = _hasValue(pInfo.phone) || _hasValue(pInfo.whatsappNumber);
      if (_hasPhone) _phoneController.text = pInfo.phone ?? pInfo.whatsappNumber!;

      _hasProfilePic = _hasValue(pInfo.profilePicture);
      if (_hasProfilePic) _profilePicUrl = pInfo.profilePicture;
    }

    if (cInfo != null) {
      _hasAddress = _hasValue(cInfo.address);
      if (_hasAddress) _addressController.text = cInfo.address!;

      _hasPincode = _hasValue(cInfo.pincode);
      if (_hasPincode) _pincodeController.text = cInfo.pincode!;

      _hasDistrict = _hasValue(cInfo.district);
      if (_hasDistrict) _districtController.text = cInfo.district!;
    }
    _initialized = true;
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        _initData(controller);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Picture',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.avatarBackground,
                            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                            child: _profileImage == null
                                ? const Icon(Icons.person, size: 30, color: AppColors.textSecondary)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload, color: AppColors.primary),
                              label: const Text('Upload', style: TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Full Name*',
                        controller: _fullNameController,
                        enabled: !_hasFullName,
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Email*',
                        controller: _emailController,
                        enabled: !_hasEmail,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // WhatsApp with Country Code Picker
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: AppColors.borderColor)),
                              ),
                              child: CountryCodePicker(
                                enabled: !_hasPhone,
                                onChanged: (code) {
                                  _countryCode = code.dialCode;
                                },
                                initialSelection: 'IN',
                                favorite: ['+91', '+1', '+44'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                textStyle: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                enabled: !_hasPhone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        label: 'Address*',
                        controller: _addressController,
                        enabled: !_hasAddress,
                        prefixIcon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Pincode*',
                              controller: _pincodeController,
                              enabled: !_hasPincode,
                              prefixIcon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              onChanged: (value) async {
                                // Clear district and pincode if backspace is pressed (length < 6)
                                if (_districtController.text.isNotEmpty && value.length < 6) {
                                  setState(() {
                                    _districtController.clear();
                                    _pincodeController.clear();
                                  });
                                  return;
                                }

                                if (value.isEmpty) {
                                  setState(() {
                                    _districtController.clear();
                                  });
                                  return;
                                }

                                // Auto-fill district based on pincode
                                if (value.length == 6) {
                                  setState(() {
                                    _districtController.text = 'Loading...';
                                  });
                                  final district = await context.read<ProfileController>().getDistrictFromPincode(
                                    value,
                                  );
                                  if (district != null) {
                                    setState(() {
                                      _districtController.text = district;
                                    });
                                  } else {
                                    setState(() {
                                      _districtController.text = 'District not found';
                                    });
                                  }
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter pincode';
                                }
                                if (value.length != 6) {
                                  return 'Pincode must be 6 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: controller.isPincodeLoading
                                ? Center(child: const CircularProgressIndicator())
                                : CustomTextField(
                                    label: 'District*',
                                    controller: _districtController,
                                    prefixIcon: Icons.map_outlined,
                                    enabled: false,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'District will auto-fill';
                                      }
                                      return null;
                                    },
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
      },
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final bool enabled;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 20) : null,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        counterText: '',
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class IdProofSection extends StatefulWidget {
  const IdProofSection({super.key});

  @override
  State<IdProofSection> createState() => IdProofSectionState();
}

class IdProofSectionState extends State<IdProofSection> {
  bool _initialized = false;
  bool _hasFrontId = false;
  bool _hasBackId = false;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final pInfo = controller.profileData!.personalInfo;
    if (pInfo != null) {
      _hasFrontId = _hasValue(pInfo.idProof);
      _hasBackId = _hasValue(pInfo.idProof2);
    }
    _initialized = true;
  }

  Future<void> _showImageSourceDialog(bool isFront) async {
    final controller = context.read<CompleteProfileController>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                controller.pickIdImage(isFront: isFront, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                controller.pickIdImage(isFront: isFront, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileController, CompleteProfileController>(
      builder: (context, profileController, completeProfileController, child) {
        _initData(profileController);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ID Proof (Both sides required) *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),

                    // Front Side
                    _buildUploadSection(
                      title: 'Front Side *',
                      subtitle: 'Upload the front side of your ID proof',
                      imageBytes: completeProfileController.idFrontImage,
                      onUpload: () => _showImageSourceDialog(true),
                      isUploaded: _hasFrontId,
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Back Side
                    _buildUploadSection(
                      title: 'Back Side *',
                      subtitle: 'Upload the back side of your ID proof',
                      imageBytes: completeProfileController.idBackImage,
                      onUpload: () => _showImageSourceDialog(false),
                      isUploaded: _hasBackId,
                    ),
                  ],
                ),
              ),
              if (profileController.error != null &&
                  (completeProfileController.idFrontImage == null || completeProfileController.idBackImage == null))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Both ID proof sides are required',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool validate() {
    final controller = context.read<CompleteProfileController>();
    return (_hasFrontId || controller.idFrontImage != null) && (_hasBackId || controller.idBackImage != null);
  }

  Widget _buildUploadSection({
    required String title,
    required String subtitle,
    required Uint8List? imageBytes,
    required VoidCallback onUpload,
    required bool isUploaded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover),
                    )
                  else if (isUploaded)
                    const Icon(Icons.check_circle, color: AppColors.statusActive, size: 40)
                  else
                    const Icon(Icons.image_outlined, color: AppColors.textHint, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          imageBytes != null ? 'Image Selected' : (isUploaded ? 'Already Uploaded' : 'Not Uploaded'),
                          style: TextStyle(
                            color: (imageBytes != null || isUploaded) ? AppColors.textPrimary : AppColors.textHint,
                            fontWeight: (imageBytes != null || isUploaded) ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (imageBytes != null)
                          const Text('Ready to save', style: TextStyle(color: AppColors.statusActive, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isUploaded ? null : onUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUploaded ? AppColors.statusActive : AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(100, 40),
                      disabledBackgroundColor: AppColors.statusActive,
                      disabledForegroundColor: AppColors.white,
                    ),
                    child: Text(isUploaded ? 'Uploaded' : (imageBytes != null ? 'Change' : 'Pick')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class AcademicInfoSection extends StatefulWidget {
  const AcademicInfoSection({super.key});

  @override
  State<AcademicInfoSection> createState() => AcademicInfoSectionState();
}

class AcademicInfoSectionState extends State<AcademicInfoSection> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedQualification;
  String? _selectedSpecialization;
  String? _selectedPassOutYear;
  final TextEditingController _collegeNameController = TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();
  String? _arrears;

  @override
  void dispose() {
    _collegeNameController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  bool _initialized = false;
  bool _hasQualification = false;
  bool _hasSpecialization = false;
  bool _hasPassOutYear = false;
  bool _hasCollege = false;
  bool _hasCgpa = false;
  bool _hasArrears = false;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final aInfo = controller.profileData!.academicInfo;
    if (aInfo != null) {
      _hasQualification = _hasValue(aInfo.qualification?.name);
      if (_hasQualification) {
        _selectedQualification = aInfo.qualification!.name;
      }

      _hasSpecialization = _hasValue(aInfo.specialization);
      if (_hasSpecialization) {
        _selectedSpecialization = aInfo.specialization;
      }

      _hasPassOutYear = aInfo.passOutYear != null;
      if (_hasPassOutYear) {
        _selectedPassOutYear = aInfo.passOutYear.toString();
      }

      _hasCollege = _hasValue(aInfo.college);
      if (_hasCollege) _collegeNameController.text = aInfo.college!;

      _hasCgpa = aInfo.cgpa != null;
      if (_hasCgpa) _cgpaController.text = aInfo.cgpa.toString();

      _hasArrears = aInfo.anyArrears != null;
      if (_hasArrears) _arrears = aInfo.anyArrears! ? 'yes' : 'no';
    }
    _initialized = true;
  }

  bool validate() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isDropdownsValid =
        _selectedQualification != null && _selectedSpecialization != null && _selectedPassOutYear != null;
    final isRadioValid = _arrears != null;

    if (!isDropdownsValid || !isRadioValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all academic fields')));
    }
    return isFormValid && isDropdownsValid && isRadioValid;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileController = context.read<ProfileController>();
      final completeController = context.read<CompleteProfileController>();

      if (profileController.profileData != null) {
        _initData(profileController);
      }

      completeController.fetchAcademicDropdowns();
    });
  }

  List<String> get _passOutYears {
    final currentYear = DateTime.now().year;
    return List.generate(25, (index) => (currentYear - 20 + index).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileController, CompleteProfileController>(
      builder: (context, profileController, completeProfileController, child) {
        _initData(profileController);

        final qualifications = completeProfileController.qualifications.map((q) => q.name).toList();
        if (_selectedQualification != null && !qualifications.contains(_selectedQualification)) {
          qualifications.insert(0, _selectedQualification!);
        }

        final specializations = completeProfileController.specializations.map((s) => s.name).toList();
        if (_selectedSpecialization != null && !specializations.contains(_selectedSpecialization)) {
          specializations.insert(0, _selectedSpecialization!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Academic Information',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 20),

                      // Qualification Dropdown
                      _buildDropdown(
                        label: 'Qualification *',
                        value: _selectedQualification,
                        items: qualifications,
                        isLoading: completeProfileController.isLoadingAcademic && qualifications.isEmpty,
                        isEditable: !_hasQualification,
                        onChanged: (value) {
                          setState(() {
                            _selectedQualification = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // College/University
                      CustomTextField(
                        label: 'College/University *',
                        controller: _collegeNameController,
                        enabled: !_hasCollege,
                        prefixIcon: Icons.school_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter college name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // CGPA
                      CustomTextField(
                        label: 'CGPA *',
                        controller: _cgpaController,
                        enabled: !_hasCgpa,
                        prefixIcon: Icons.grade_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter CGPA';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Specialization Dropdown
                      _buildDropdown(
                        label: 'Specialization *',
                        value: _selectedSpecialization,
                        items: specializations,
                        isLoading: completeProfileController.isLoadingAcademic && specializations.isEmpty,
                        isEditable: !_hasSpecialization,
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialization = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Pass Out Year Dropdown
                      _buildDropdown(
                        label: 'Pass Out Year *',
                        value: _selectedPassOutYear,
                        items: _passOutYears,
                        isEditable: !_hasPassOutYear,
                        onChanged: (value) {
                          setState(() {
                            _selectedPassOutYear = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Any Arrears?
                      const Text(
                        'Any Arrears?',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildRadioButton('No', 'no', !_hasArrears)),
                          Expanded(child: _buildRadioButton('Yes', 'yes', !_hasArrears)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isEditable = true,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isLoading ? 'Loading...' : 'Select ${label.replaceAll('*', '').trim()}',
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isEditable ? onChanged : null,
              icon: const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_drop_down)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton(String label, String value, bool isEditable) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _arrears,
      onChanged: isEditable
          ? (val) {
              setState(() {
                _arrears = val;
              });
            }
          : null,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class CareerInfoSection extends StatefulWidget {
  const CareerInfoSection({super.key});

  @override
  State<CareerInfoSection> createState() => CareerInfoSectionState();
}

class CareerInfoSectionState extends State<CareerInfoSection> {
  final _formKey = GlobalKey<FormState>();
  String? _currentStatus = 'Student';
  final TextEditingController _preferredLocationController = TextEditingController();
  bool _interestedInPlacement = true;

  @override
  void dispose() {
    _preferredLocationController.dispose();
    super.dispose();
  }

  bool _initialized = false;
  bool _hasCurrentStatus = false;
  bool _hasPreferredLocation = false;
  bool _hasPlacementAssistance = false;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final aInfo = controller.profileData!.academicInfo;
    final plInfo = controller.profileData!.placementInfo;

    if (aInfo != null) {
      _hasCurrentStatus = _hasValue(aInfo.studentOrWorkingProfessional);
      if (_hasCurrentStatus) _currentStatus = aInfo.studentOrWorkingProfessional;
    }

    if (plInfo != null) {
      _hasPreferredLocation = _hasValue(plInfo.preferredJobLocation);
      if (_hasPreferredLocation) _preferredLocationController.text = plInfo.preferredJobLocation!;

      _hasPlacementAssistance = plInfo.placementAssistance != null;
      if (_hasPlacementAssistance) _interestedInPlacement = plInfo.placementAssistance!;
    }
    _initialized = true;
  }

  bool validate() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (_currentStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your current status')));
      return false;
    }
    return isFormValid;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ProfileController>();
      if (controller.profileData != null) {
        _initData(controller);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        _initData(controller);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Career Information',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 20),

                      // Current Status
                      const Text(
                        'Current Status *',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _currentStatus,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            'Student',
                            'Employed',
                            'Unemployed',
                            'Looking for change',
                          ].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                          onChanged: !_hasCurrentStatus
                              ? (value) {
                                  setState(() {
                                    _currentStatus = value;
                                  });
                                }
                              : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Preferred Job Location
                      CustomTextField(
                        label: 'Preferred Job Location *',
                        controller: _preferredLocationController,
                        enabled: !_hasPreferredLocation,
                        prefixIcon: Icons.location_city_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter preferred job location';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Placement Assistance Checkbox
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _interestedInPlacement,
                              onChanged: !_hasPlacementAssistance
                                  ? (value) {
                                      setState(() {
                                        _interestedInPlacement = value ?? false;
                                      });
                                    }
                                  : null,
                              activeColor: AppColors.primary,
                            ),
                            const Expanded(
                              child: Text(
                                'I am interested in placement assistance',
                                style: TextStyle(color: AppColors.textPrimary),
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
          ),
        );
      },
    );
  }
}

class ParentInfoSection extends StatefulWidget {
  const ParentInfoSection({super.key});

  @override
  State<ParentInfoSection> createState() => ParentInfoSectionState();
}

class ParentInfoSectionState extends State<ParentInfoSection> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  String? _countryCode = '+91';

  bool _initialized = false;
  bool _hasParentName = false;
  bool _hasParentPhone = false;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final cInfo = controller.profileData!.contactInfo;

    if (cInfo != null) {
      _hasParentName = _hasValue(cInfo.parentName);
      if (_hasParentName) _parentNameController.text = cInfo.parentName!;

      _hasParentPhone = _hasValue(cInfo.parentPhone);
      if (_hasParentPhone) _parentPhoneController.text = cInfo.parentPhone!;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ProfileController>();
      if (controller.profileData != null) {
        _initData(controller);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        _initData(controller);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parent/Guardian',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 20),

                      // Parent Name
                      CustomTextField(
                        label: 'Name *',
                        controller: _parentNameController,
                        enabled: !_hasParentName,
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter parent/guardian name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Parent Phone with Country Code
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: AppColors.borderColor)),
                              ),
                              child: CountryCodePicker(
                                enabled: !_hasParentPhone,
                                onChanged: (code) {
                                  _countryCode = code.dialCode;
                                },
                                initialSelection: 'IN',
                                favorite: ['+91', '+1', '+44'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                textStyle: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _parentPhoneController,
                                enabled: !_hasParentPhone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
                                  }
                                  return null;
                                },
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
          ),
        );
      },
    );
  }
}
