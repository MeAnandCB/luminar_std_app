import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/repository/academic_info/model.dart';
import 'package:luminar_std/repository/academic_info/service.dart';
import 'package:provider/provider.dart';
import 'package:luminar_std/presentation/global_widget/shimmer.dart';

class ReferralScreen extends StatefulWidget {
  final String? referrerName;
  final String? referrerPhone;

  const ReferralScreen({super.key, this.referrerName, this.referrerPhone});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int? _selectedQualification;
  int? _selectedCourse;
  bool _isSubmitting = false;

  final AcademicInfoService _academicService = AcademicInfoService();
  List<Qualification> _qualificationsList = [];
  List<PublicCourse> _coursesList = [];
  bool _isLoadingAcademic = true;

  @override
  void initState() {
    super.initState();
    _fetchAcademicData();
  }

  Future<void> _fetchAcademicData() async {
    try {
      // Kick off both requests before awaiting either, so they run in
      // parallel instead of one blocking the other.
      final qFuture = _academicService.getQualifications();
      final cFuture = _academicService.getPublicCourses();
      final qRes = await qFuture;
      final cRes = await cFuture;
      if (mounted) {
        setState(() {
          if (qRes.success && qRes.data != null) {
            _qualificationsList = qRes.data!.qualifications;
          }
          if (cRes.success && cRes.data != null) {
            _coursesList = cRes.data!.courses;
          }
          _isLoadingAcademic = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching academic data: $e');
      if (mounted) {
        setState(() {
          _isLoadingAcademic = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final payload = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'referrer_name': widget.referrerName ?? '',
        'referrer_phone': widget.referrerPhone ?? '',
        'qualification_id': _selectedQualification,
        'course_id': _selectedCourse,
        'email': _emailController.text.trim(),
        'secret': 'luminar',
      };

      try {
        final response = await ApiService().post(
          endpoint: AppEndpoints.referralSubmit,
          body: payload,
        );
        print('Response: ${response.data}');

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.celebration_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Awesome! Your referral has been successfully submitted! 🎉',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.statusActive,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Failed to submit referral'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error submitting referral: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An error occurred. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Refer & Earn',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderIcon(),
                const SizedBox(height: 24),

                Text(
                  'Lead Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _nameController,
                  label: 'Lead Full Name *',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Lead Phone Number *',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Lead Email Address (Optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _isLoadingAcademic
                    ? const ShimmerWidget(
                        width: double.infinity,
                        height: 56,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      )
                    : _buildQualificationDropdown(),
                const SizedBox(height: 16),

                _isLoadingAcademic
                    ? const ShimmerWidget(
                        width: double.infinity,
                        height: 56,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      )
                    : _buildCourseDropdown(),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Submit Referral'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.redeem_rounded, size: 48, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(
          icon,
          color: AppColors.primary.withValues(alpha: 0.7),
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildQualificationDropdown() {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: _selectedQualification,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Qualification (Optional)',
        labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(
          Icons.school_outlined,
          color: AppColors.primary.withValues(alpha: 0.7),
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _qualificationsList.map((q) {
        return DropdownMenuItem<int>(
          value: q.id,
          child: Text(q.name, overflow: TextOverflow.ellipsis, maxLines: 1),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedQualification = newValue;
        });
      },
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: _selectedCourse,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Which course are they looking for? (Optional)',
        labelStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(
          Icons.menu_book_rounded,
          color: AppColors.primary.withValues(alpha: 0.7),
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _coursesList.map((c) {
        return DropdownMenuItem<int>(
          value: c.id,
          child: Text(
            c.courseName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedCourse = newValue;
        });
      },
    );
  }
}
