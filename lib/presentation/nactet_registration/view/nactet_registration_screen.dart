import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';
import 'package:luminar_std/presentation/nactet_registration/controller/nactet_registration_controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_check_display_model.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';

class NactetRegistrationScreen extends StatefulWidget {
  final NactetCheckDisplayEnrollment? nactetEnrollment;
  const NactetRegistrationScreen({super.key, this.nactetEnrollment});

  @override
  State<NactetRegistrationScreen> createState() => _NactetRegistrationScreenState();
}

class _NactetRegistrationScreenState extends State<NactetRegistrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final nactetController = Provider.of<NactetRegistrationController>(context, listen: false);
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
    final controller = Provider.of<NactetRegistrationController>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: controller.isCheckingStatus 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Checking registration status...',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                  _buildStepIndicator(controller),
                  const SizedBox(height: 20),
                  _buildCourseInfoBanner(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView(
                      controller: controller.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(controller),
                        _buildStep2(controller),
                        _buildStep3(controller),
                        _buildStep4(controller),
                      ],
                    ),
                  ),
                  _buildBottomNavigation(controller),
                ],
              )
            : _buildUnavailableView(controller),
    );
  }

  Widget _buildUnavailableView(NactetRegistrationController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock_outlined, size: 64, color: AppColors.primary.withOpacity(0.2)),
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        onPressed: () => Navigator.pop(context),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(NactetRegistrationController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                controller.isSuccess ? '1 / submitted' : '${controller.currentStep + 1} / 4 tasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: controller.isSuccess ? 1.0 : (controller.currentStep + 1) / 4,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                controller.isSuccess ? AppColors.statusActive : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, NactetRegistrationController controller) {
    final bool isActive = controller.currentStep == step;
    final bool isCompleted = controller.currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppColors.statusActive 
                : isActive ? AppColors.primary : AppColors.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: (isCompleted || isActive) ? Colors.transparent : AppColors.borderColor,
            ),
          ),
          child: Center(
            child: isCompleted 
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    (step + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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

  Widget _buildStep1(NactetRegistrationController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.business, 'INSTITUTION & PERSONAL DETAILS'),
          const SizedBox(height: 20),
          _buildLabel('Please mention your Institution (Branch) *'),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBranchChip('Calicut', controller),
              const SizedBox(width: 8),
              _buildBranchChip('Cochin', controller),
              const SizedBox(width: 8),
              _buildBranchChip('Thrissur', controller),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('Name of the Candidate *'),
          const SizedBox(height: 8),
          _buildAlert('This name will be printed on your NACTET certificate. No corrections allowed later.'),
          const SizedBox(height: 10),
          _buildTextField(controller.nameController, 'FULL NAME AS ON DOCUMENTS'),
          const SizedBox(height: 20),
          _buildLabel('Guardian Name *'),
          const SizedBox(height: 10),
          _buildTextField(controller.guardianNameController, 'Father / Mother / Guardian full name'),
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
          const SizedBox(height: 20),
          _buildLabel('Date of Birth *'),
          const SizedBox(height: 10),
          _buildDateField(context, controller),
          const SizedBox(height: 20),
          _buildLabel('Permanent Address *'),
          const SizedBox(height: 10),
          _buildTextField(controller.addressController, 'House No, Street, City, State, PIN Code', maxLines: 3),
          const SizedBox(height: 20),
          _buildLabel('Mobile No *'),
          const SizedBox(height: 10),
          _buildTextField(controller.mobileController, '10-digit mobile number', keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildLabel('Email *'),
          const SizedBox(height: 10),
          _buildTextField(controller.emailController, 'your@email.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStep2(NactetRegistrationController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
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
          const SizedBox(height: 20),
          _buildLabel('Basic Qualification — Year of Passing *'),
          const SizedBox(height: 10),
          _buildTextField(controller.basicQualYearController, 'e.g. 2018', keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildLabel('Highest Educational Qualification *'),
          const SizedBox(height: 8),
          _buildHint('Include university name (e.g. B.Tech CSE — APJ Abdul Kalam Technological University)'),
          const SizedBox(height: 10),
          _buildTextField(controller.higherQualController, 'Degree — University Name'),
          const SizedBox(height: 20),
          _buildLabel('Year of Passing *'),
          const SizedBox(height: 10),
          _buildTextField(controller.higherQualYearController, 'e.g. 2024', keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildStep3(NactetRegistrationController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.upload_file, 'DOCUMENT UPLOAD'),
          const SizedBox(height: 15),
          _buildAlert('Upload documents as PDF, JPG, or PNG, max 10 MB each.'),
          const SizedBox(height: 20),
          _buildLabel('Basic Educational Qualification Document (SSLC / CBSE / ICSE 10th) *'),
          _buildHint('Upload 10th mark sheet or passing certificate • PDF or image (JPG, PNG)'),
          const SizedBox(height: 10),
          _buildFileUploadBox('basic', controller),
          const SizedBox(height: 20),
          _buildLabel('Highest Educational Qualification Document *'),
          _buildHint('If final marksheet not received, upload latest semester marksheet • PDF or image (JPG, PNG)'),
          const SizedBox(height: 10),
          _buildFileUploadBox('higher', controller),
          const SizedBox(height: 20),
          _buildLabel('ID Proof (Aadhaar / Driving Licence) *'),
          _buildHint('PDF or image (JPG, PNG)'),
          const SizedBox(height: 10),
          _buildFileUploadBox('id', controller),
          const SizedBox(height: 20),
          _buildLabel('Passport Size Photograph *'),
          _buildHint('JPG or PNG supported'),
          const SizedBox(height: 10),
          _buildFileUploadBox('photo', controller),
          if (controller.fileSizeError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
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
      ),
    );
  }

  Widget _buildStep4(NactetRegistrationController controller) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.assignment_turned_in, 'COURSE DETAILS'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4)),
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
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildAlert(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchChip(String label, NactetRegistrationController controller) {
    final bool isSelected = controller.isBranchSelected(label); 
    return GestureDetector(
      onTap: () => controller.updateBranch(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBackground,
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

  Widget _buildGenderChip(String label, String value, NactetRegistrationController controller) {
    final bool isSelected = controller.registrationModel.gender == value;
    return GestureDetector(
      onTap: () => controller.updateGender(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBackground,
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

  Widget _buildBasicQualChip(String label, NactetRegistrationController controller) {
    final bool isSelected = controller.registrationModel.basicEducationalQualification == label;
    return GestureDetector(
      onTap: () => controller.updateBasicQual(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBackground,
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

  Widget _buildDateField(BuildContext context, NactetRegistrationController controller) {
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
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.dobController.text.isEmpty ? 'dd/mm/yyyy' : controller.dobController.text,
              style: TextStyle(
                color: controller.dobController.text.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadBox(String type, NactetRegistrationController controller) {
    String? path;
    switch (type) {
      case 'basic': path = controller.registrationModel.basicDocPath; break;
      case 'higher': path = controller.registrationModel.higherDocPath; break;
      case 'id': path = controller.registrationModel.idProofPath; break;
      case 'photo': path = controller.registrationModel.photoPath; break;
    }

    final bool hasFile = path != null;

    return GestureDetector(
      onTap: () => controller.pickFile(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.primary.withOpacity(0.05) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? AppColors.primary : AppColors.borderColor,
            style: hasFile ? BorderStyle.solid : BorderStyle.none, // Need dotted border ideally
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
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Tap to upload • '),
                    TextSpan(
                      text: 'Browse',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
        color: AppColors.textSecondary.withOpacity(0.5),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(NactetRegistrationController controller) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    final enrollment = enrollmentProvider.enrollmentDataRes?.enrollments.isNotEmpty == true 
          ? enrollmentProvider.enrollmentDataRes!.enrollments.first : null;
    
    final data = controller.successData;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStepIndicator(controller),
          const SizedBox(height: 60),
          
          // --- Success Icon ---
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.statusActive.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.statusActive.withOpacity(0.2),
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
            style: AppTextStyles.headerName.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Registration for ${data?['course_name'] ?? enrollment?.course.courseName ?? "your course"} received. Confirmation sent to ${controller.emailController.text}.',
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
              border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
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
                    color: AppColors.textSecondary.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow('Name', data?['name'] ?? controller.nameController.text),
                _buildSummaryRow('Branch', data?['branch_name'] ?? 'Calicut'),
                _buildSummaryRow('Course', data?['course_name'] ?? enrollment?.course.courseName ?? 'N/A'),
                _buildSummaryRow('Batch', data?['batch_name'] ?? enrollment?.batch.batchName ?? 'N/A'),
                _buildSummaryRow('Mobile', data?['mobile_number'] ?? controller.mobileController.text),
                _buildSummaryRow('Email', data?['email'] ?? controller.emailController.text),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(NactetRegistrationController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.currentStep > 0)
            TextButton.icon(
              onPressed: controller.previousStep,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
          
          AnimatedSmoothIndicator(
            activeIndex: controller.currentStep,
            count: 4,
            effect: ScrollingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.primary.withOpacity(0.2),
              dotHeight: 8,
              dotWidth: 8,
            ),
          ),

          if (controller.currentStep < 3)
            ElevatedButton(
              onPressed: () {
                final error = controller.validateStep(controller.currentStep);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                  return;
                }
                controller.nextStep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                children: const [
                  Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: controller.isLoading ? null : () async {
                final validationError = controller.validateStep(3);
                if (validationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(validationError), backgroundColor: Colors.red),
                  );
                  return;
                }
                final success = await controller.submit(context);
                if (success) {
                  if (mounted) {
                    setState(() {
                      controller.isSuccess = true;
                    });
                  }
                } else if (controller.errorMessage != null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppUtils.friendlyError(controller.errorMessage!)), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusActive,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: controller.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                  children: const [
                    Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
            ),
        ],
      ),
    );
  }
}
