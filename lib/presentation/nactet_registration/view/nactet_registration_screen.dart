import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/nactet_registration/controller/nactet_registration_controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_check_display_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';

class NactetRegistrationScreen extends StatefulWidget {
  final NactetCheckDisplayEnrollment? nactetEnrollment;
  const NactetRegistrationScreen({super.key, this.nactetEnrollment});

  @override
  State<NactetRegistrationScreen> createState() =>
      _NactetRegistrationScreenState();
}

class _NactetRegistrationScreenState extends State<NactetRegistrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final enrollmentProvider = Provider.of<EnrollmentProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final nactetController = Provider.of<NactetRegistrationController>(
        context,
        listen: false,
      );
      final student = authProvider.studentData?.profile;

      if (widget.nactetEnrollment != null) {
        // Came from the multi-enrollment selection sheet
        nactetController.initFromNactetEnrollment(
          widget.nactetEnrollment!,
          student?.fullName,
          student?.email,
          student?.phone,
        );
      } else {
        // Default: use first enrollment from EnrollmentProvider
        final currentEnrollment =
            enrollmentProvider.enrollmentDataRes?.enrollments.isNotEmpty == true
            ? enrollmentProvider.enrollmentDataRes!.enrollments.first
            : null;
        nactetController.init(
          currentEnrollment,
          student?.fullName,
          student?.email,
          student?.phone,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final controller = Provider.of<NactetRegistrationController>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: controller.isCheckingStatus
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Checking registration status...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : controller.isSuccess
            ? _buildSuccessView(controller)
            : controller.displayForm
            ? Column(
                children: [
                  const SizedBox(height: 20),
                  _buildCourseInfoBanner(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPersonalSection(controller),
                          const SizedBox(height: 32),
                          _buildEducationSection(controller),
                          const SizedBox(height: 32),
                          _buildDocumentsSection(controller),
                          const SizedBox(height: 32),
                          _buildCourseSection(controller),
                        ],
                      ),
                    ),
                  ),
                  _buildSubmitBar(controller),
                ],
              )
            : _buildUnavailableView(controller),
      ),
    );
  }

  Widget _buildUnavailableView(NactetRegistrationController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Registration Unavailable',
            style: AppTextStyles.headerName.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'NACTET registration is currently closed or not yet available for your batch. Please check back later or contact your branch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cardBackground,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () {
          Provider.of<NactetRegistrationController>(
            context,
            listen: false,
          ).reset();
          Navigator.pop(context);
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NACTET Registration — February',
            style: AppTextStyles.headerName.copyWith(fontSize: 16),
          ),
          Text(
            'Fill in CAPITAL LETTERS • PDF, JPG or PNG accepted',
            style: AppTextStyles.activitySubtitle.copyWith(fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.stars_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseInfoBanner(BuildContext context) {
    // Prefer nactetEnrollment (from selection sheet) over EnrollmentProvider
    final nactet = widget.nactetEnrollment;
    final String courseName;
    final String enrollmentNumber;

    if (nactet != null) {
      courseName = nactet.courseName;
      enrollmentNumber = nactet.enrollmentNumber;
    } else {
      final enrollmentProvider = Provider.of<EnrollmentProvider>(context);
      final enrollment =
          enrollmentProvider.enrollmentDataRes?.enrollments.isNotEmpty == true
          ? enrollmentProvider.enrollmentDataRes!.enrollments.first
          : null;
      if (enrollment == null) return const SizedBox();
      courseName = enrollment.course.courseName;
      enrollmentNumber = enrollment.enrollmentNumber;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.book_outlined, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              courseName,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            enrollmentNumber,
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step Content ---

  Widget _buildPersonalSection(NactetRegistrationController controller) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.business, 'INSTITUTION & PERSONAL DETAILS'),
          const SizedBox(height: 20),
          _buildLabel('Institution (Branch) *'),
          const SizedBox(height: 10),
          _buildBranchField(controller),
          _buildFieldError(controller.fieldErrors['branch']),
          const SizedBox(height: 20),
          _buildLabel('Name of the Candidate *'),
          const SizedBox(height: 8),
          _buildAlert(
            'This name will be printed on your NACTET certificate. No corrections allowed later.',
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller.nameController,
            'FULL NAME AS ON DOCUMENTS',
            errorText: controller.fieldErrors['name'],
            onEdited: () => controller.clearFieldError('name'),
          ),
          const SizedBox(height: 20),
          _buildLabel('Guardian Name *'),
          const SizedBox(height: 10),
          _buildTextField(
            controller.guardianNameController,
            'Father / Mother / Guardian full name',
            errorText: controller.fieldErrors['guardian'],
            onEdited: () => controller.clearFieldError('guardian'),
          ),
          const SizedBox(height: 20),
          _buildLabel('Gender *'),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildGenderChip('MALE', 'M', controller),
              const SizedBox(width: 8),
              _buildGenderChip('FEMALE', 'F', controller),
              const SizedBox(width: 8),
              _buildGenderChip('Prefer not to say', 'O', controller),
            ],
          ),
          _buildFieldError(controller.fieldErrors['gender']),
          const SizedBox(height: 20),
          _buildLabel('Date of Birth *'),
          const SizedBox(height: 10),
          _buildDateField(context, controller),
          _buildFieldError(controller.fieldErrors['dob']),
          const SizedBox(height: 20),
          _buildLabel('Permanent Address *'),
          const SizedBox(height: 10),
          _buildTextField(
            controller.addressController,
            'House No, Street, City, State, PIN Code',
            maxLines: 3,
            errorText: controller.fieldErrors['address'],
            onEdited: () => controller.clearFieldError('address'),
          ),
          const SizedBox(height: 20),
          _buildLabel('Mobile No *'),
          const SizedBox(height: 10),
          _buildPhoneField(controller),
          _buildFieldError(controller.fieldErrors['mobile']),
          const SizedBox(height: 20),
          _buildLabel('Email *'),
          const SizedBox(height: 10),
          _buildTextField(
            controller.emailController,
            'your@email.com',
            keyboardType: TextInputType.emailAddress,
            capitalize: false,
            errorText: controller.fieldErrors['email'],
            onEdited: () => controller.clearFieldError('email'),
          ),
          const SizedBox(height: 40),
        ],
      );
  }

  Widget _buildEducationSection(NactetRegistrationController controller) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.school, 'EDUCATIONAL QUALIFICATION'),
          const SizedBox(height: 20),
          _buildLabel('Basic Educational Qualification *'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBasicQualChip('SSLC', controller),
              _buildBasicQualChip('CBSE 10TH', controller),
              _buildBasicQualChip('ICSE 10TH', controller),
              _buildBasicQualChip('OTHER', controller),
            ],
          ),
          _buildFieldError(controller.fieldErrors['basicQual']),
          const SizedBox(height: 20),
          _buildLabel('Basic Qualification — Year of Passing *'),
          const SizedBox(height: 10),
          _buildTextField(
            controller.basicQualYearController,
            'e.g. 2018',
            keyboardType: TextInputType.number,
            errorText: controller.fieldErrors['basicQualYear'],
            onEdited: () => controller.clearFieldError('basicQualYear'),
          ),
          const SizedBox(height: 20),
          _buildLabel('Highest Educational Qualification *'),
          const SizedBox(height: 8),
          _buildHint(
            'Include university name (e.g. B.Tech CSE — APJ Abdul Kalam Technological University)',
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller.higherQualController,
            'Degree — University Name',
            errorText: controller.fieldErrors['higherQual'],
            onEdited: () => controller.clearFieldError('higherQual'),
          ),
          const SizedBox(height: 20),
          _buildLabel('Year of Passing *'),
          const SizedBox(height: 10),
          _buildTextField(
            controller.higherQualYearController,
            'e.g. 2024',
            keyboardType: TextInputType.number,
            errorText: controller.fieldErrors['higherQualYear'],
            onEdited: () => controller.clearFieldError('higherQualYear'),
          ),
        ],
      );
  }

  Widget _buildDocumentsSection(NactetRegistrationController controller) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.upload_file, 'DOCUMENT UPLOAD'),
          const SizedBox(height: 15),
          _buildAlert('Upload documents as PDF, JPG, or PNG, max 10 MB each.'),
          const SizedBox(height: 20),
          _buildLabel(
            'Basic Educational Qualification Document (SSLC / CBSE / ICSE 10th) *',
          ),
          _buildHint(
            'Upload 10th mark sheet or passing certificate • PDF or image (JPG, PNG)',
          ),
          const SizedBox(height: 10),
          _buildFileUploadBox('basic', controller),
          _buildFieldError(controller.fieldErrors['basicDoc']),
          const SizedBox(height: 20),
          _buildLabel('Highest Educational Qualification Document *'),
          _buildHint(
            'If final marksheet not received, upload latest semester marksheet • PDF or image (JPG, PNG)',
          ),
          const SizedBox(height: 10),
          _buildFileUploadBox('higher', controller),
          _buildFieldError(controller.fieldErrors['higherDoc']),
          const SizedBox(height: 20),
          _buildLabel('ID Proof (Aadhaar / Driving Licence) *'),
          _buildHint('PDF or image (JPG, PNG)'),
          const SizedBox(height: 10),
          _buildFileUploadBox('id', controller),
          _buildFieldError(controller.fieldErrors['idProof']),
          const SizedBox(height: 20),
          _buildLabel('Passport Size Photograph *'),
          _buildHint('JPG or PNG supported'),
          const SizedBox(height: 10),
          _buildFileUploadBox('photo', controller),
          _buildFieldError(controller.fieldErrors['photo']),
          if (controller.fileSizeError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.fileSizeError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
  }

  Widget _buildCourseSection(NactetRegistrationController controller) {
    // Prefer nactetEnrollment when navigating from selection sheet
    final nactet = widget.nactetEnrollment;
    final String courseName;
    final String batchName;
    final String enrollmentNumber;

    if (nactet != null) {
      courseName = nactet.courseName;
      batchName = nactet.batchName;
      enrollmentNumber = nactet.enrollmentNumber;
    } else {
      final enrollmentProvider = Provider.of<EnrollmentProvider>(context);
      final enrollment =
          enrollmentProvider.enrollmentDataRes?.enrollments.isNotEmpty == true
          ? enrollmentProvider.enrollmentDataRes!.enrollments.first
          : null;
      courseName = enrollment?.course.courseName ?? 'N/A';
      batchName = enrollment?.batch.batchName ?? 'N/A';
      enrollmentNumber = enrollment?.enrollmentNumber ?? 'N/A';
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.assignment_turned_in, 'COURSE DETAILS'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoLabel('ENROLLMENT INFO'),
                const SizedBox(height: 16),
                _buildReviewRow('Course', courseName),
                const SizedBox(height: 12),
                _buildReviewRow('Batch', batchName),
                const SizedBox(height: 12),
                _buildReviewRow('Enrollment No.', enrollmentNumber),
              ],
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: controller.toggleConfirmation,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.confirmationChecked,
                  onChanged: (_) => controller.toggleConfirmation(),
                  activeColor: AppColors.statusActive,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'I confirm all information is accurate. I understand the name entered will be printed on my NACTET certificate and cannot be changed later.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFieldError(controller.fieldErrors['confirmation']),
        ],
      );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  /// Inline error shown directly under a field — used for the custom
  /// widgets (chips, date/phone pickers, file uploads, the confirmation
  /// checkbox) that can't use TextField's built-in errorText.
  Widget _buildFieldError(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 14, color: Colors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(NactetRegistrationController controller) {
    final hasError = controller.fieldErrors['mobile'] != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasError ? Colors.red : AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.borderColor)),
            ),
            child: CountryCodePicker(
              onChanged: (code) {
                controller.mobileCountryCode = code.dialCode ?? '+91';
                controller.registrationModel.mobileNumber =
                    '${controller.mobileCountryCode}${controller.mobileController.text.trim()}';
              },
              initialSelection: 'IN',
              favorite: const ['+91', '+1', '+44'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
              textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.mobileController,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                controller.registrationModel.mobileNumber =
                    '${controller.mobileCountryCode}${value.trim()}';
                controller.clearFieldError('mobile');
              },
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofillHints: const [],
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Mobile number',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool capitalize = true,
    String? errorText,
    VoidCallback? onEdited,
  }) {
    return TextField(
      controller: controller,
      onChanged: onEdited == null ? null : (_) => onEdited(),
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: capitalize
          ? TextCapitalization.characters
          : TextCapitalization.none,
      autocorrect: false,
      autofillHints: const [],
      inputFormatters: capitalize
          ? [
              TextInputFormatter.withFunction(
                (oldValue, newValue) =>
                    newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ]
          : null,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
        letterSpacing: capitalize ? 0.5 : 0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
        errorText: errorText,
        errorMaxLines: 2,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11.5),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAlert(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Branch is auto-selected from the enrollment detail API — the student
  /// no longer picks it manually. Shows a locked read-only field once
  /// detected; falls back to the tappable chip list (below) only if
  /// auto-detection couldn't resolve a branch, so the form is never a dead
  /// end.
  Widget _buildBranchField(NactetRegistrationController controller) {
    if (controller.isLoadingBranch) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (controller.branchAutoDetected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.business, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.branchName ?? 'Branch selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Icon(Icons.lock_outline, size: 15, color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
      );
    }

    // Fallback: auto-detection failed to resolve a branch — let the student
    // pick manually rather than blocking the form entirely.
    return controller.isLoadingLocations
        ? const SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.locations
                .map((loc) => _buildBranchChip(loc.name, loc.id, controller))
                .toList(),
          );
  }

  Widget _buildBranchChip(
    String label,
    int id,
    NactetRegistrationController controller,
  ) {
    final bool isSelected = controller.isBranchSelected(id);
    return GestureDetector(
      onTap: () => controller.updateBranch(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(
    String label,
    String value,
    NactetRegistrationController controller,
  ) {
    final bool isSelected = controller.registrationModel.gender == value;
    return GestureDetector(
      onTap: () => controller.updateGender(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicQualChip(
    String label,
    NactetRegistrationController controller,
  ) {
    final bool isSelected =
        controller.registrationModel.basicEducationalQualification == label;
    return GestureDetector(
      onTap: () => controller.updateBasicQual(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    NactetRegistrationController controller,
  ) {
    final hasError = controller.fieldErrors['dob'] != null;
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          controller.updateDateOfBirth(DateFormat('yyyy-MM-dd').format(date));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasError ? Colors.red : AppColors.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.dobController.text.isEmpty
                  ? 'dd/mm/yyyy'
                  : controller.dobController.text,
              style: TextStyle(
                color: controller.dobController.text.isEmpty
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadBox(
    String type,
    NactetRegistrationController controller,
  ) {
    String? path;
    switch (type) {
      case 'basic':
        path = controller.registrationModel.basicDocPath;
        break;
      case 'higher':
        path = controller.registrationModel.higherDocPath;
        break;
      case 'id':
        path = controller.registrationModel.idProofPath;
        break;
      case 'photo':
        path = controller.registrationModel.photoPath;
        break;
    }

    final bool hasFile = path != null;
    const errorKeys = {
      'basic': 'basicDoc',
      'higher': 'higherDoc',
      'id': 'idProof',
      'photo': 'photo',
    };
    final bool hasError =
        !hasFile && controller.fieldErrors[errorKeys[type]] != null;

    return GestureDetector(
      onTap: () => controller.pickFile(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? AppColors.primary
                : hasError
                ? Colors.red
                : AppColors.borderColor,
            style: hasFile || hasError
                ? BorderStyle.solid
                : BorderStyle.none, // Need dotted border ideally
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: hasFile ? AppColors.statusActive : AppColors.textHint,
              size: 28,
            ),
            const SizedBox(height: 12),
            if (hasFile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  path.split('/').last,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Tap to upload • '),
                    TextSpan(
                      text: 'Browse',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Max 10 MB',
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(NactetRegistrationController controller) {
    final data = controller.successData;

    final String courseName;
    final String batchName;
    if (widget.nactetEnrollment != null) {
      courseName = widget.nactetEnrollment!.courseName;
      batchName = widget.nactetEnrollment!.batchName;
    } else {
      final ep = Provider.of<EnrollmentProvider>(context, listen: false);
      final enr = ep.enrollmentDataRes?.enrollments.isNotEmpty == true
          ? ep.enrollmentDataRes!.enrollments.first
          : null;
      courseName = enr?.course.courseName ?? 'N/A';
      batchName = enr?.batch.batchName ?? 'N/A';
    }

    final branchName =
        data?['branch_name'] as String? ??
        controller.locations
            .where(
              (l) => l.id.toString() == controller.registrationModel.branch,
            )
            .map((l) => l.name)
            .firstOrNull ??
        '—';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 60),

          // --- Success Icon ---
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.statusActive.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.statusActive.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.statusActive,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Form Submitted!',
            style: AppTextStyles.headerName.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Registration for ${data?['course_name'] ?? courseName} received. Confirmation sent to ${controller.emailController.text}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // --- Summary Card ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow(
                  'Name',
                  data?['name'] ?? controller.nameController.text,
                ),
                _buildSummaryRow('Branch', branchName),
                _buildSummaryRow('Course', data?['course_name'] ?? courseName),
                _buildSummaryRow('Batch', data?['batch_name'] ?? batchName),
                _buildSummaryRow(
                  'Mobile',
                  data?['mobile_number'] ?? controller.mobileController.text,
                ),
                _buildSummaryRow(
                  'Email',
                  data?['email'] ?? controller.emailController.text,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- Back Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                controller.reset();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Back to Enrollments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the exact backend error message for a failed registration submit.
  /// Deliberately bypasses AppUtils.friendlyError, which truncates/replaces
  /// any message over 80 chars (or containing words like "exception") with a
  /// generic string — that hid the real validation reason for this form.
  void _showSubmissionErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submission Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSubmit(NactetRegistrationController controller) async {
    final error = controller.validateForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    controller.logFormSnapshot();
    final success = await controller.submit(context);
    if (success) {
      if (mounted) setState(() {});
    } else if (controller.errorMessage != null && mounted) {
      _showSubmissionErrorDialog(controller.errorMessage!);
    }
  }

  Widget _buildSubmitBar(NactetRegistrationController controller) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 12.0;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                controller.reset();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () => _confirmAndSubmit(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusActive,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Confirm & Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
