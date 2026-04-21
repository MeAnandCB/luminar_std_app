import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/complete_your_profile/controller/complete_profile_controller.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:provider/provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
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
      await Provider.of<ProfileController>(
        context,
        listen: false,
      ).getProfileData(context: context);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Profile'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.primary),
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
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swiping until valid
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
              padding: EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_validateCurrentPage()) {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: Text('Next'),
              ),
            )
          else if (_currentPage == _totalPages - 1)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Consumer2<ProfileController, CompleteProfileController>(
                builder:
                    (context, profileController, completeController, child) {
                      return ElevatedButton(
                        onPressed: completeController.isSubmitting
                            ? null
                            : () async {
                                if (_validateCurrentPage()) {
                                  try {
                                    await completeController.submitProfile(
                                      profileController.profileData,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profile completed successfully!',
                                          ),
                                          backgroundColor:
                                              AppColors.statusActive,
                                        ),
                                      );
                                      await profileController.refreshProfile(
                                        context: context,
                                      );
                                      // Clear cached dashboard so BottomNavScreen
                                      // fetches fresh data with profileCompleted:true
                                      if (context.mounted) {
                                        context
                                            .read<DashboardController>()
                                            .clearDashboardData();
                                      }
                                      if (context.mounted) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const BottomNavScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      LoggerUtils.error(
                                        e.toString(),
                                        tag: 'ProfileCompletion',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppUtils.friendlyError(
                                              e.toString(),
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusActive,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: completeController.isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text('Submit'),
                      );
                    },
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
    return Consumer2<ProfileController, CompleteProfileController>(
      builder: (context, profileCtrl, completeCtrl, child) {
        // Use live form progress once user starts filling; fall back to server data
        final liveCount = completeCtrl.filledFieldsCount;
        final serverCount = profileCtrl.filledFieldsCount;
        final filled = liveCount > serverCount ? liveCount : serverCount;
        final total = CompleteProfileController.totalFields;
        final percentage = filled / total;
        final percentageInt = (percentage * 100).toInt();
        final remaining = total - filled;

        return Container(
          padding: EdgeInsets.all(16),
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
                  Text(
                    'Complete Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentageInt%',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$remaining fields remaining',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      },
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
  String? _countryCode = '+91';
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  bool _initialized = false;
  bool _hasFullName = false;
  bool _hasEmail = false;
  bool _hasPhone = false;
  bool _hasAddress = false;
  bool _hasPincode = false;
  bool _hasDistrict = false;
  bool _hasProfilePic = false;
  String? _profilePicUrl;

  // Shown when pincode is not found — lets user pick Out of State / Out of Country
  bool _showLocationFallback = false;
  String? _selectedLocationFallback;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final pInfo = controller.profileData!.personalInfo;
    final cInfo = controller.profileData!.contactInfo;
    final completeController = context.read<CompleteProfileController>();

    if (pInfo != null) {
      _hasFullName = _hasValue(pInfo.fullName);
      if (_hasFullName) {
        _fullNameController.text = pInfo.fullName!;
        completeController.fullName = pInfo.fullName;
      }

      _hasEmail = _hasValue(pInfo.email);
      if (_hasEmail) {
        _emailController.text = pInfo.email!;
        completeController.email = pInfo.email;
      }

      // Assuming pInfo.phone is the primary phone number
      _hasPhone = _hasValue(pInfo.phone);
      if (_hasPhone) {
        _phoneController.text = pInfo.phone!;
        completeController.phone = pInfo.phone;
      } else if (_hasValue(pInfo.whatsappNumber)) {
        // If phone is not available, use whatsapp number for phone field
        _hasPhone = true; // Mark as having phone if whatsapp is present
        _phoneController.text = pInfo.whatsappNumber!;
        completeController.phone = pInfo.whatsappNumber;
      }

      _hasProfilePic = _hasValue(pInfo.profilePicture);
      if (_hasProfilePic) {
        _profilePicUrl = pInfo.profilePicture;
        completeController.serverProfilePic = true;
      }
      completeController.serverIdFront = _hasValue(pInfo.idProof);
      completeController.serverIdBack = _hasValue(pInfo.idProof2);
      completeController.serverResume = pInfo.resume != null;

      if (pInfo.dateOfBirth != null) {
        final dobStr = pInfo.dateOfBirth!.toString().split(' ').first;
        _dobController.text = dobStr;
        completeController.dateOfBirth = dobStr;
        if (pInfo.age != null) {
          _ageController.text = pInfo.age.toString();
          completeController.age = pInfo.age;
        } else {
          _calculateAge(pInfo.dateOfBirth!);
        }
      }
    }

    if (cInfo != null) {
      _hasAddress = _hasValue(cInfo.address);
      if (_hasAddress) {
        _addressController.text = cInfo.address!;
        completeController.address = cInfo.address;
      }

      _hasPincode = _hasValue(cInfo.pincode);
      if (_hasPincode) {
        _pincodeController.text = cInfo.pincode!;
        completeController.pincode = cInfo.pincode;
      }

      _hasDistrict = _hasValue(cInfo.district);
      if (_hasDistrict) {
        _districtController.text = cInfo.district!;
        completeController.district = cInfo.district;
      }
    }
    _initialized = true;
    if (mounted) setState(() {});
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _pickImage() async {
    final completeController = context.read<CompleteProfileController>();
    await completeController.pickProfilePic();
    if (completeController.profilePicPath != null) {
      setState(() {});
    }
  }

  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    _ageController.text = age.toString();
    context.read<CompleteProfileController>().age = age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.cardBackground,
                    onSurface: AppColors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.cardBackground,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final dobStr = picked.toString().split(' ').first;
        _dobController.text = dobStr;
        context.read<CompleteProfileController>().dateOfBirth = dobStr;
        _calculateAge(picked);
      });
    }
  }

  Widget _buildLocationFallbackDropdown(
    CompleteProfileController completeController,
  ) {
    const options = ['Out of State', 'Out of Country'];
    return DropdownButtonFormField<String>(
      initialValue: _selectedLocationFallback,
      decoration: InputDecoration(
        labelText: 'District*',
        prefixIcon: Icon(
          Icons.map_outlined,
          color: AppColors.primary,
          size: 20,
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
      hint: Text(
        'Select location type',
        style: TextStyle(color: AppColors.textHint, fontSize: 13),
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedLocationFallback = value;
          completeController.district = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please select';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, child) {
        if (!_initialized && controller.profileData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initData(controller);
          });
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Picture',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Consumer<CompleteProfileController>(
                            builder: (context, completeController, child) {
                              return CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.avatarBackground,
                                backgroundImage:
                                    completeController.profilePicPath != null
                                    ? FileImage(
                                        File(
                                          completeController.profilePicPath!,
                                        ),
                                      )
                                    : (_profilePicUrl != null
                                              ? NetworkImage(_profilePicUrl!)
                                              : null)
                                          as ImageProvider?,
                                child:
                                    (completeController.profilePicPath ==
                                            null &&
                                        _profilePicUrl == null)
                                    ? Icon(
                                        Icons.person,
                                        size: 30,
                                        color: AppColors.textSecondary,
                                      )
                                    : null,
                              );
                            },
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(
                                Icons.upload,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'Upload',
                                style: TextStyle(color: AppColors.primary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primary),
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
                SizedBox(height: 16),

                // Personal Information Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),

                      CustomTextField(
                        label: 'Full Name*',
                        controller: _fullNameController,
                        enabled: false,
                        prefixIcon: Icons.person_outline,
                        onChanged: (value) {
                          context.read<CompleteProfileController>().fullName =
                              value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          if (!RegExp(
                            r"^[a-zA-Z\s]+$",
                          ).hasMatch(value.trim())) {
                            return 'Name must contain only letters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      CustomTextField(
                        label: 'Email*',
                        controller: _emailController,
                        enabled: false,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          context.read<CompleteProfileController>().email =
                              value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                          ).hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: CustomTextField(
                                  label: 'Date of Birth*',
                                  controller: _dobController,
                                  prefixIcon: Icons.calendar_today_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: CustomTextField(
                              label: 'Age',
                              controller: _ageController,
                              enabled: false,
                              prefixIcon: Icons.cake_outlined,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

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
                                  right: BorderSide(
                                    color: AppColors.borderColor,
                                  ),
                                ),
                              ),
                              child: CountryCodePicker(
                                enabled: true,
                                onChanged: (code) {
                                  final dial = code.dialCode ?? '+91';
                                  setState(() => _countryCode = dial);
                                  final digits = _phoneController.text
                                      .replaceFirst(RegExp(r'^\+\d+\s*'), '');
                                  _phoneController.text = '$dial $digits';
                                  context.read<CompleteProfileController>().phone =
                                      _phoneController.text;
                                },
                                initialSelection: 'IN',
                                favorite: ['+91', '+1', '+44'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                textStyle: TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                enabled: true,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (digits) {
                                  final full =
                                      '${_countryCode ?? '+91'} $digits';
                                  context
                                      .read<CompleteProfileController>()
                                      .phone = full;
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      CustomTextField(
                        label: 'Address*',
                        controller: _addressController,
                        enabled: true,
                        prefixIcon: Icons.location_on_outlined,
                        onChanged: (value) {
                          context.read<CompleteProfileController>().address =
                              value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      CustomTextField(
                        label: 'Pincode*',
                        controller: _pincodeController,
                        enabled: true,
                        prefixIcon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (value) async {
                          final completeController = context
                              .read<CompleteProfileController>();
                          completeController.pincode = value;

                          // Reset district when pincode is being edited
                          if (value.length < 6) {
                            setState(() {
                              _districtController.clear();
                              completeController.district = null;
                              _showLocationFallback = false;
                              _selectedLocationFallback = null;
                            });
                            return;
                          }

                          // Auto-fill district based on pincode
                          if (value.length == 6) {
                            setState(() {
                              _districtController.text = 'Loading...';
                              _showLocationFallback = false;
                              _selectedLocationFallback = null;
                            });
                            final district = await context
                                .read<ProfileController>()
                                .getDistrictFromPincode(value);
                            if (district != null) {
                              setState(() {
                                _districtController.text = district;
                                completeController.district = district;
                                _showLocationFallback = false;
                              });
                            } else {
                              // Pincode not found — show Out of State / Out of Country picker
                              setState(() {
                                _districtController.clear();
                                completeController.district = null;
                                _showLocationFallback = true;
                                _selectedLocationFallback = null;
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
                      SizedBox(height: 12),
                      controller.isPincodeLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _showLocationFallback
                          ? _buildLocationFallbackDropdown(
                              context.read<CompleteProfileController>(),
                            )
                          : CustomTextField(
                              label: 'District*',
                              controller: _districtController,
                              prefixIcon: Icons.map_outlined,
                              enabled: false,
                              onChanged: (value) {
                                context
                                        .read<CompleteProfileController>()
                                        .district =
                                    value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'District will auto-fill';
                                }
                                return null;
                              },
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
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
        labelStyle: TextStyle(color: AppColors.textSecondary),
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
  bool _showError = false;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await controller.pickIdImage(
                  isFront: isFront,
                  source: ImageSource.camera,
                );
                if (mounted) setState(() => _showError = false);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await controller.pickIdImage(
                  isFront: isFront,
                  source: ImageSource.gallery,
                );
                if (mounted) setState(() => _showError = false);
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Proof (Both sides required) *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Front Side
                    _buildUploadSection(
                      title: 'Front Side *',
                      subtitle: 'Upload the front side of your ID proof',
                      imagePath: completeProfileController.idFrontPath,
                      onUpload: () => _showImageSourceDialog(true),
                      isUploaded: _hasFrontId,
                    ),

                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 20),

                    // Back Side
                    _buildUploadSection(
                      title: 'Back Side *',
                      subtitle: 'Upload the back side of your ID proof',
                      imagePath: completeProfileController.idBackPath,
                      onUpload: () => _showImageSourceDialog(false),
                      isUploaded: _hasBackId,
                    ),
                  ],
                ),
              ),
              if (_showError &&
                  (completeProfileController.idFrontPath == null &&
                          !_hasFrontId ||
                      completeProfileController.idBackPath == null &&
                          !_hasBackId))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    completeProfileController.idFrontPath == null &&
                            !_hasFrontId &&
                            completeProfileController.idBackPath == null &&
                            !_hasBackId
                        ? 'Both front and back ID proof are required'
                        : completeProfileController.idFrontPath == null &&
                              !_hasFrontId
                        ? 'Front side of ID proof is required'
                        : 'Back side of ID proof is required',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
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
    final isValid =
        (_hasFrontId || controller.idFrontPath != null) &&
        (_hasBackId || controller.idBackPath != null);
    if (!isValid) {
      setState(() => _showError = true);
    }
    return isValid;
  }

  Widget _buildUploadSection({
    required String title,
    required String subtitle,
    required String? imagePath,
    required VoidCallback onUpload,
    required bool isUploaded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(imagePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (isUploaded)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.statusActive,
                      size: 40,
                    )
                  else
                    Icon(
                      Icons.image_outlined,
                      color: AppColors.textHint,
                      size: 40,
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          imagePath != null
                              ? 'Image Selected'
                              : (isUploaded
                                    ? 'Already Uploaded'
                                    : 'Not Uploaded'),
                          style: TextStyle(
                            color: (imagePath != null || isUploaded)
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontWeight: (imagePath != null || isUploaded)
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        if (imagePath != null)
                          Text(
                            'Ready to save',
                            style: TextStyle(
                              color: AppColors.statusActive,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isUploaded ? null : onUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUploaded
                          ? AppColors.statusActive
                          : AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(100, 40),
                      disabledBackgroundColor: AppColors.statusActive,
                      disabledForegroundColor: AppColors.white,
                    ),
                    child: Text(
                      isUploaded
                          ? 'Uploaded'
                          : (imagePath != null ? 'Change' : 'Pick'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
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
  State<AcademicInfoSection> createState() => AcademicInfoSectionState();
}

class AcademicInfoSectionState extends State<AcademicInfoSection> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedQualification;
  String? _selectedSpecialization;
  String? _selectedPassOutYear;
  final TextEditingController _collegeNameController = TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();
  bool? _anyArrears;

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
    final completeController = context.read<CompleteProfileController>();

    if (aInfo != null) {
      _hasQualification = _hasValue(aInfo.qualification?.name);
      if (_hasQualification) {
        _selectedQualification = aInfo.qualification!.name;
        completeController.qualificationName = aInfo.qualification!.name;
        completeController.qualificationId = aInfo.qualification!.id.toString();
      }

      _hasSpecialization = _hasValue(aInfo.specialization);
      if (_hasSpecialization) {
        _selectedSpecialization = aInfo.specialization;
        completeController.specialization = aInfo.specialization;
      }

      _hasPassOutYear = aInfo.passOutYear != null;
      if (_hasPassOutYear) {
        _selectedPassOutYear = aInfo.passOutYear.toString();
        completeController.passOutYear = aInfo.passOutYear.toString();
      }

      _hasCollege = _hasValue(aInfo.college);
      if (_hasCollege) {
        _collegeNameController.text = aInfo.college!;
        completeController.college = aInfo.college;
      }

      _hasCgpa = aInfo.cgpa != null;
      if (_hasCgpa) {
        _cgpaController.text = aInfo.cgpa.toString();
        completeController.cgpa = aInfo.cgpa.toString();
      }

      _hasArrears = aInfo.anyArrears != null;
      if (_hasArrears) {
        _anyArrears = aInfo.anyArrears!;
        completeController.anyArrears = aInfo.anyArrears;
      }

      if (aInfo.admissionDate != null) {
        completeController.admissionDate =
            aInfo.admissionDate.toString().split(' ').first;
      }
    }
    _initialized = true;
  }

  bool validate() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isDropdownsValid =
        _selectedQualification != null &&
        _selectedSpecialization != null &&
        _selectedPassOutYear != null;
    final isRadioValid = _anyArrears != null;

    if (!isDropdownsValid || !isRadioValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all academic fields')),
      );
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

        final qualifications = completeProfileController.qualifications
            .map((q) => q.name)
            .toList();
        if (_selectedQualification != null &&
            !qualifications.contains(_selectedQualification)) {
          qualifications.insert(0, _selectedQualification!);
        }

        final specializations = completeProfileController.specializations
            .map((s) => s.name)
            .toList();
        if (_selectedSpecialization != null &&
            !specializations.contains(_selectedSpecialization)) {
          specializations.insert(0, _selectedSpecialization!);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Qualification Dropdown
                      _buildDropdown(
                        label: 'Qualification *',
                        value: _selectedQualification,
                        items: qualifications,
                        isLoading:
                            completeProfileController.isLoadingAcademic &&
                            qualifications.isEmpty,
                        isEditable: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedQualification = value;
                            final completeController = context
                                .read<CompleteProfileController>();
                            completeController.qualificationName = value;
                            // Find ID
                            final q = completeController.qualifications
                                .firstWhere((element) => element.name == value);
                            completeController.qualificationId = q.id
                                .toString();
                          });
                        },
                      ),

                      SizedBox(height: 16),

                      // College/University
                      CustomTextField(
                        label: 'College/University *',
                        controller: _collegeNameController,
                        enabled: true,
                        prefixIcon: Icons.school_outlined,
                        onChanged: (value) {
                          context.read<CompleteProfileController>().college =
                              value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter college name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // CGPA
                      TextFormField(
                        controller: _cgpaController,
                        enabled: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'CGPA *',
                          prefixIcon: Icon(
                            Icons.grade_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          counterText: '',
                        ),
                        onChanged: (value) {
                          final cgpa = double.tryParse(value);
                          if (cgpa != null) {
                            if (cgpa > 10) {
                              _cgpaController.text = '10';
                              _cgpaController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _cgpaController.text.length,
                                    ),
                                  );
                            } else if (cgpa < 0) {
                              _cgpaController.text = '0';
                              _cgpaController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _cgpaController.text.length,
                                    ),
                                  );
                            }
                          }
                          context.read<CompleteProfileController>().cgpa =
                              _cgpaController.text;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter CGPA';
                          }
                          final cgpa = double.tryParse(value.trim());
                          if (cgpa == null) {
                            return 'CGPA must be a valid number';
                          }
                          if (cgpa < 0 || cgpa > 10) {
                            return 'CGPA must be between 0 and 10';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Specialization Dropdown
                      _buildDropdown(
                        label: 'Specialization *',
                        value: _selectedSpecialization,
                        items: specializations,
                        isLoading:
                            completeProfileController.isLoadingAcademic &&
                            specializations.isEmpty,
                        isEditable: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialization = value;
                            context
                                    .read<CompleteProfileController>()
                                    .specialization =
                                value;
                          });
                        },
                      ),

                      SizedBox(height: 16),

                      // Pass Out Year Dropdown
                      _buildDropdown(
                        label: 'Pass Out Year *',
                        value: _selectedPassOutYear,
                        items: _passOutYears,
                        isEditable: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedPassOutYear = value;
                            context
                                    .read<CompleteProfileController>()
                                    .passOutYear =
                                value;
                          });
                        },
                      ),

                      SizedBox(height: 16),

                      // Any Arrears?
                      Text(
                        'Any Arrears?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildRadioButton('No', 'no', true)),
                          Expanded(
                            child: _buildRadioButton('Yes', 'yes', true),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
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
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isLoading
                      ? 'Loading...'
                      : 'Select ${label.replaceAll('*', '').trim()}',
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isEditable ? onChanged : null,
              icon: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton(String title, String value, bool isEnabled) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: RadioListTile<String>(
        title: Text(title, style: TextStyle(fontSize: 14)),
        value: value,
        groupValue: _anyArrears == true
            ? 'yes'
            : (_anyArrears == false ? 'no' : null),
        onChanged: isEnabled
            ? (val) {
                setState(() {
                  _anyArrears = val == 'yes';
                  context.read<CompleteProfileController>().anyArrears =
                      _anyArrears;
                });
              }
            : null,
      ),
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
  final TextEditingController _locationController = TextEditingController();
  bool _interestedInPlacement = true;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  bool _initialized = false;
  bool _hasCurrentStatus = false;
  bool _hasPreferredLocation = false;
  bool _hasPlacementAssistance = false;
  bool _hasResume = false; // Added for resume

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final aInfo = controller.profileData!.academicInfo;
    final plInfo = controller.profileData!.placementInfo;
    final completeController = context.read<CompleteProfileController>();

    if (aInfo != null) {
      _hasCurrentStatus = _hasValue(aInfo.studentOrWorkingProfessional);
      if (_hasCurrentStatus) {
        final status = aInfo.studentOrWorkingProfessional?.toLowerCase();
        if (status == 'student') {
          _currentStatus = 'Student';
        } else if (status != null && status.isNotEmpty) {
          _currentStatus = 'Working Professional';
        }
        completeController.studentStatus = status ?? 'student';
      }
    }

    if (plInfo != null) {
      _hasPreferredLocation = _hasValue(plInfo.preferredJobLocation);
      if (_hasPreferredLocation) {
        _locationController.text = plInfo.preferredJobLocation!;
        completeController.preferredJobLocation = plInfo.preferredJobLocation;
      }

      _hasPlacementAssistance = plInfo.placementAssistance != null;
      if (_hasPlacementAssistance) {
        _interestedInPlacement = plInfo.placementAssistance!;
        completeController.placementAssistance = plInfo.placementAssistance;
      }
    }

    final pInfo = controller.profileData?.personalInfo;
    if (pInfo != null) {
      _hasResume = _hasValue(pInfo.resume);
    }
    _initialized = true;
  }

  bool validate() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (_currentStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your current status')),
      );
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
        if (!_initialized && controller.profileData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initData(controller);
          });
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Career Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Current Status
                      Text(
                        'Current Status *',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _currentStatus,
                          isExpanded: true,
                          underline: SizedBox(),
                          items: ['Student', 'Working Professional']
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
                              context
                                  .read<CompleteProfileController>()
                                  .studentStatus = value == 'Student'
                                  ? 'student'
                                  : 'working_professional';
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 16),

                      // Preferred Job Location
                      CustomTextField(
                        label: 'Preferred Job Location *',
                        controller: _locationController,
                        enabled: true,
                        prefixIcon: Icons.location_city_outlined,
                        onChanged: (value) {
                          context
                                  .read<CompleteProfileController>()
                                  .preferredJobLocation =
                              value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter preferred job location';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Placement Assistance Checkbox
                      // Placement Assistance Checkbox
                      Container(
                        padding: EdgeInsets.all(12),
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
                                  context
                                          .read<CompleteProfileController>()
                                          .placementAssistance =
                                      _interestedInPlacement;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                'I am interested in placement assistance',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Resume Upload Section
                      Text(
                        'Resume (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Consumer<CompleteProfileController>(
                        builder: (context, completeController, child) {
                          return Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  completeController.resumePath != null ||
                                          _hasResume
                                      ? Icons.description
                                      : Icons.upload_file,
                                  color:
                                      completeController.resumePath != null ||
                                          _hasResume
                                      ? AppColors.statusActive
                                      : AppColors.textHint,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    completeController.resumePath != null ||
                                            _hasResume
                                        ? 'Resume selected'
                                        : 'Upload your resume (PDF)',
                                    style: TextStyle(
                                      color:
                                          completeController.resumePath !=
                                                  null ||
                                              _hasResume
                                          ? AppColors.textPrimary
                                          : AppColors.textHint,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final FilePickerResult? result =
                                        await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['pdf'],
                                        );

                                    if (result != null &&
                                        result.files.single.path != null) {
                                      completeController.setResume(
                                        result.files.single.path,
                                      );
                                    }
                                  },
                                  child: Text(
                                    completeController.resumePath != null ||
                                            _hasResume
                                        ? 'Change'
                                        : 'Pick',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _parentCountryCode = '+91';

  bool _initialized = false;
  bool _hasParentName = false;
  bool _hasParentPhone = false;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _initData(ProfileController controller) {
    if (_initialized || controller.profileData == null) return;

    final cInfo = controller.profileData!.contactInfo;
    final completeController = context.read<CompleteProfileController>();

    if (cInfo != null) {
      _hasParentName = _hasValue(cInfo.parentName);
      if (_hasParentName) {
        _nameController.text = cInfo.parentName!;
        completeController.parentName = cInfo.parentName;
      }

      _hasParentPhone = _hasValue(cInfo.parentPhone);
      if (_hasParentPhone) {
        _phoneController.text = cInfo.parentPhone!;
        completeController.parentPhone = cInfo.parentPhone;
      }
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
        if (!_initialized && controller.profileData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initData(controller);
          });
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent/Guardian',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Parent Name
                      CustomTextField(
                        label: 'Name *',
                        controller: _nameController,
                        enabled: true,
                        prefixIcon: Icons.person_outline,
                        onChanged: (value) {
                          context.read<CompleteProfileController>().parentName =
                              value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter parent/guardian name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          if (!RegExp(
                            r"^[a-zA-Z\s]+$",
                          ).hasMatch(value.trim())) {
                            return 'Name must contain only letters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

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
                                  right: BorderSide(
                                    color: AppColors.borderColor,
                                  ),
                                ),
                              ),
                              child: CountryCodePicker(
                                enabled: true,
                                onChanged: (code) {
                                  final dial = code.dialCode ?? '+91';
                                  setState(() => _parentCountryCode = dial);
                                  final digits = _phoneController.text
                                      .replaceFirst(RegExp(r'^\+\d+\s*'), '');
                                  _phoneController.text = '$dial $digits';
                                  context
                                      .read<CompleteProfileController>()
                                      .parentPhone = _phoneController.text;
                                },
                                initialSelection: 'IN',
                                favorite: ['+91', '+1', '+44'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                textStyle: TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                enabled: true,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (digits) {
                                  final full = '$_parentCountryCode $digits';
                                  context
                                      .read<CompleteProfileController>()
                                      .parentPhone = full;
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
