// lib/screens/profile_completion_screen.dart
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

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
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: const [
                PersonalInfoSection(),
                IdProofSection(),
                AcademicInfoSection(),
                CareerInfoSection(),
                ParentInfoSection(),
                Center(child: Text('Profile Complete!')),
              ],
            ),
          ),
          if (_currentPage < _totalPages - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _totalPages - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text('Continue - ${_currentPage + 1}/$_totalPages'),
              ),
            )
          else if (_currentPage == _totalPages - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Submit profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile completed successfully!'),
                      backgroundColor: AppColors.statusActive,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusActive,
                ),
                child: const Text('Complete Profile'),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Complete Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '37%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '12 fields remaining',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class PersonalInfoSection extends StatefulWidget {
  const PersonalInfoSection({super.key});

  @override
  State<PersonalInfoSection> createState() => _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends State<PersonalInfoSection> {
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  String? _countryCode = '+91';
  String? _fullName = 'Shihab';
  String? _email = 'shihab@gmail.com';
  String? _phone = '1234568900';
  String? _address;
  String? _pincode;
  String? _district;

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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.avatarBackground,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.upload,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Upload',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Full Name*',
                    initialValue: _fullName,
                    prefixIcon: Icons.person_outline,
                    onChanged: (value) => _fullName = value,
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
                    initialValue: _email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => _email = value,
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
                            border: Border(
                              right: BorderSide(color: AppColors.borderColor),
                            ),
                          ),
                          child: CountryCodePicker(
                            onChanged: (code) {
                              _countryCode = code.dialCode;
                            },
                            initialSelection: 'IN',
                            favorite: ['+91', '+1', '+44'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            textStyle: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Phone number',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onChanged: (value) => _phone = value,
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
                    prefixIcon: Icons.location_on_outlined,
                    onChanged: (value) => _address = value,
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
                          prefixIcon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (value) {
                            _pincode = value;
                            // Auto-fill district based on pincode
                            if (value?.length == 6) {
                              setState(() {
                                _district =
                                    'District will auto-fill from pincode';
                              });
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
                        child: CustomTextField(
                          label: 'District*',
                          initialValue: _district,
                          prefixIcon: Icons.map_outlined,
                          enabled: false,
                          onChanged: (value) => _district = value,
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
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
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
    this.initialValue,
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
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
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
  State<IdProofSection> createState() => _IdProofSectionState();
}

class _IdProofSectionState extends State<IdProofSection> {
  String? _frontFileName;
  String? _backFileName;

  Future<void> _pickFile(bool isFront) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        if (isFront) {
          _frontFileName = result.files.single.name;
        } else {
          _backFileName = result.files.single.name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Front Side
                _buildUploadSection(
                  title: 'Front Side *',
                  subtitle:
                      'Upload the front side of your ID proof (Aadhar, PAN, etc.) as JPG, PNG, or PDF',
                  fileName: _frontFileName,
                  onUpload: () => _pickFile(true),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Back Side
                _buildUploadSection(
                  title: 'Back Side *',
                  subtitle:
                      'Upload the back side of your ID proof (Aadhar, PAN, etc.) as JPG, PNG, or PDF',
                  fileName: _backFileName,
                  onUpload: () => _pickFile(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String subtitle,
    required String? fileName,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
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
                  Checkbox(
                    value: fileName != null,
                    onChanged: (value) {},
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName ?? 'Upload $title',
                          style: TextStyle(
                            color: fileName != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontWeight: fileName != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        if (fileName != null)
                          Text(
                            'File selected',
                            style: TextStyle(
                              color: AppColors.statusActive,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(100, 40),
                    ),
                    child: const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
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
  State<AcademicInfoSection> createState() => _AcademicInfoSectionState();
}

class _AcademicInfoSectionState extends State<AcademicInfoSection> {
  String? _selectedQualification;
  String? _selectedSpecialization;
  String? _selectedPassOutYear;
  String? _collegeName;
  String? _cgpa;
  String? _arrears;

  final List<String> _qualifications = [
    'High School',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Diploma',
  ];

  final List<String> _specializations = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Business Administration',
  ];

  final List<String> _passOutYears = [
    '2020',
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
  ];

  @override
  Widget build(BuildContext context) {
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
                  'Academic Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Qualification Dropdown
                _buildDropdown(
                  label: 'Qualification *',
                  value: _selectedQualification,
                  items: _qualifications,
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
                  prefixIcon: Icons.school_outlined,
                  onChanged: (value) => _collegeName = value,
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
                  prefixIcon: Icons.grade_outlined,
                  keyboardType: TextInputType.number,

                  onChanged: (value) => _cgpa = value,
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
                  items: _specializations,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildRadioButton('No', 'no')),
                    Expanded(child: _buildRadioButton('Yes', 'yes')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                'Select ${label.replaceAll('*', '').trim()}',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
              items: items
                  .map(
                    (item) => DropdownItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),

              onChanged: onChanged,
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50,
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _arrears,
      onChanged: (value) {
        setState(() {
          _arrears = value;
        });
      },
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class CareerInfoSection extends StatefulWidget {
  const CareerInfoSection({super.key});

  @override
  State<CareerInfoSection> createState() => _CareerInfoSectionState();
}

class _CareerInfoSectionState extends State<CareerInfoSection> {
  String? _currentStatus = 'Student';
  String? _preferredLocation;
  bool _interestedInPlacement = true;

  @override
  Widget build(BuildContext context) {
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
                  'Career Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Current Status
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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
                    items:
                        [
                              'Student',
                              'Employed',
                              'Unemployed',
                              'Looking for change',
                            ]
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentStatus = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Preferred Job Location
                CustomTextField(
                  label: 'Preferred Job Location',
                  prefixIcon: Icons.location_city_outlined,

                  onChanged: (value) => _preferredLocation = value,
                ),

                const SizedBox(height: 16),

                // Placement Assistance Checkbox
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _interestedInPlacement,
                        onChanged: (value) {
                          setState(() {
                            _interestedInPlacement = value ?? false;
                          });
                        },
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
    );
  }
}

class ParentInfoSection extends StatefulWidget {
  const ParentInfoSection({super.key});

  @override
  State<ParentInfoSection> createState() => _ParentInfoSectionState();
}

class _ParentInfoSectionState extends State<ParentInfoSection> {
  String? _parentName = 'adssf';
  String? _parentPhone = '0987654324';
  String? _countryCode = '+91';

  @override
  Widget build(BuildContext context) {
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
                  'Parent/Guardian',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Parent Name
                CustomTextField(
                  label: 'Name *',
                  initialValue: _parentName,
                  prefixIcon: Icons.person_outline,
                  onChanged: (value) => _parentName = value,
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
                          border: Border(
                            right: BorderSide(color: AppColors.borderColor),
                          ),
                        ),
                        child: CountryCodePicker(
                          onChanged: (code) {
                            _countryCode = code.dialCode;
                          },
                          initialSelection: 'IN',
                          favorite: ['+91', '+1', '+44'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                          textStyle: const TextStyle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: _parentPhone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Phone number',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (value) => _parentPhone = value,
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
    );
  }
}
