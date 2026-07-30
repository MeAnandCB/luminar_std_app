import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_registration_model.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_check_display_model.dart';
import 'package:luminar_std/repository/nactet_registration/service/nactet_registration_service.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';
import 'package:luminar_std/repository/locations/model.dart';
import 'package:luminar_std/repository/locations/service.dart';
import 'package:luminar_std/repository/payment_screen/service.dart';
import 'package:luminar_std/repository/shared_pref.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';

class NactetRegistrationController extends ChangeNotifier {
  final NactetRegistrationService _service = NactetRegistrationService();
  final LocationsService _locationsService = LocationsService();
  final PaymentScreenService _paymentService = PaymentScreenService();
  final NactetRegistrationModel registrationModel = NactetRegistrationModel();

  int currentStep = 0;
  bool isLoading = false;
  bool isCheckingStatus = false;
  bool isLoadingLocations = false;
  bool isLoadingBranch = false;
  bool isSuccess = false;
  bool displayForm = true;
  bool confirmationChecked = false;
  String? errorMessage;
  String? fileSizeError;
  dynamic successData;

  // Set once the branch has been auto-detected from the enrollment API, so
  // the UI knows to show a locked/read-only branch display instead of the
  // manual picker. If auto-detection fails, this stays false and the user
  // falls back to picking manually so they're never stuck.
  bool branchAutoDetected = false;
  String? branchName;

  List<LocationModel> locations = [];

  String _mobileCountryCode = '+91';
  String get mobileCountryCode => _mobileCountryCode;
  set mobileCountryCode(String value) {
    _mobileCountryCode = value;
    notifyListeners();
  }

  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  final PageController pageController = PageController();

  // Controllers for text fields to pre-fill and manage state
  final nameController = TextEditingController();
  final guardianNameController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final basicQualYearController = TextEditingController();
  final higherQualController = TextEditingController();
  final higherQualYearController = TextEditingController();

  Future<void> fetchLocations() async {
    isLoadingLocations = true;
    notifyListeners();
    try {
      final response = await _locationsService.getLocations();
      if (response.success && response.data != null) {
        locations = response.data!.locations;
      }
    } catch (e) {
      LoggerUtils.error('Error fetching locations: $e', tag: 'NACTET');
    } finally {
      isLoadingLocations = false;
      notifyListeners();
    }
  }

  Future<void> init(
    Enrollment? enrollment,
    String? studentName,
    String? studentEmail,
    String? studentMobile,
  ) async {
    await fetchLocations();
    if (enrollment != null) {
      registrationModel.enrollment = enrollment.uid;
      registrationModel.course = 1;
      registrationModel.batch = enrollment.batch.uid;
      registrationModel.branch = null;

      await _autoDetectBranch(enrollment.uid);

      // Auto-check if already filled
      checkRegistrationStatus(enrollment.uid);
    }

    notifyListeners();
  }

  /// Used when navigating from the multi-enrollment selection sheet.
  Future<void> initFromNactetEnrollment(
    NactetCheckDisplayEnrollment enrollment,
    String? studentName,
    String? studentEmail,
    String? studentMobile,
  ) async {
    registrationModel.enrollment = enrollment.enrollmentUid;
    registrationModel.course = enrollment.courseId;
    registrationModel.batch = enrollment.batchUid;
    registrationModel.branch = null;

    await fetchLocations();
    await _autoDetectBranch(enrollment.enrollmentUid);
    checkRegistrationStatus(enrollment.enrollmentUid);
    notifyListeners();
  }

  /// Auto-selects the branch from the enrollment detail API
  /// (/api/enrollment/{uid}/) instead of requiring the student to pick it
  /// manually. Falls back to leaving the branch unselected (manual chip
  /// picker stays available in the UI) if the backend doesn't return
  /// recognizable branch data.
  Future<void> _autoDetectBranch(String enrollmentUid) async {
    isLoadingBranch = true;
    branchAutoDetected = false;
    notifyListeners();

    try {
      final token = await SharedPrefService.getAccessToken();
      if (token == null || token.isEmpty) return;

      final response = await _paymentService.fetchEnrollmentDetails(
        enrollmentUid,
        token,
      );
      final branch = response.data?.branch;

      developer.log(
        'enrollment_uid=$enrollmentUid id=${branch?.id} name=${branch?.name}',
        name: 'EnrollmentDetail.RawBranch',
      );

      if (branch?.id != null) {
        registrationModel.branch = branch!.id.toString();
        branchName = branch.name ??
            locations
                .where((l) => l.id == branch.id)
                .map((l) => l.name)
                .firstOrNull;
        branchAutoDetected = true;
      } else if (branch?.name != null && branch!.name!.trim().isNotEmpty) {
        // No numeric id in the response — try to match the returned name
        // against the fetched Locations list to recover an id.
        final match = locations
            .where((l) => l.name.toLowerCase() == branch.name!.toLowerCase())
            .firstOrNull;
        if (match != null) {
          registrationModel.branch = match.id.toString();
          branchName = match.name;
          branchAutoDetected = true;
        }
      }
    } catch (e) {
      LoggerUtils.error('Branch auto-detect failed: $e', tag: 'NACTET');
    } finally {
      isLoadingBranch = false;
      notifyListeners();
    }
  }

  void toggleConfirmation() {
    confirmationChecked = !confirmationChecked;
    notifyListeners();
  }

  /// Returns an error message if the current step is invalid, null if valid.
  String? validateStep(int step) {
    switch (step) {
      case 0:
        if (registrationModel.branch == null)
          return 'Please select your branch';
        final name = nameController.text.trim();
        if (name.isEmpty) return 'Please enter your full name';
        if (name.length < 2) return 'Name must be at least 2 characters';
        if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(name))
          return 'Name should contain letters only';
        final guardian = guardianNameController.text.trim();
        if (guardian.isEmpty) return 'Please enter guardian name';
        if (guardian.length < 2)
          return 'Guardian name must be at least 2 characters';
        if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(guardian))
          return 'Guardian name should contain letters only';
        if (registrationModel.gender == null)
          return 'Please select your gender';
        if (dobController.text.trim().isEmpty)
          return 'Please select your date of birth';
        if (addressController.text.trim().isEmpty)
          return 'Please enter your permanent address';
        final digits = mobileController.text.trim().replaceAll(
          RegExp(r'\D'),
          '',
        );
        if (digits.isEmpty) return 'Please enter your mobile number';
        if (digits.length < 7) return 'Mobile number must be at least 7 digits';
        if (digits.length > 15)
          return 'Mobile number must not exceed 15 digits';
        if (emailController.text.trim().isEmpty)
          return 'Please enter your email';
        if (!RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$',
        ).hasMatch(emailController.text.trim())) {
          return 'Please enter a valid email address';
        }
        return null;
      case 1:
        if (registrationModel.basicEducationalQualification == null) {
          return 'Please select basic educational qualification';
        }
        if (basicQualYearController.text.trim().isEmpty) {
          return 'Please enter basic qualification year of passing';
        }
        final basicYear = int.tryParse(basicQualYearController.text.trim());
        if (basicYear == null ||
            basicYear < 1950 ||
            basicYear > DateTime.now().year + 5) {
          return 'Please enter a valid year (1950–${DateTime.now().year + 5})';
        }
        if (higherQualController.text.trim().isEmpty) {
          return 'Please enter your highest educational qualification';
        }
        if (higherQualYearController.text.trim().isEmpty) {
          return 'Please enter year of passing for highest qualification';
        }
        final higherYear = int.tryParse(higherQualYearController.text.trim());
        if (higherYear == null ||
            higherYear < 1950 ||
            higherYear > DateTime.now().year + 5) {
          return 'Please enter a valid year (1950–${DateTime.now().year + 5})';
        }
        return null;
      case 2:
        if (registrationModel.basicDocPath == null) {
          return 'Please upload your basic qualification document';
        }
        if (registrationModel.higherDocPath == null) {
          return 'Please upload your highest qualification document';
        }
        if (registrationModel.idProofPath == null)
          return 'Please upload your ID proof';
        if (registrationModel.photoPath == null)
          return 'Please upload your passport size photo';
        return null;
      case 3:
        if (!confirmationChecked) {
          return 'Please confirm that all information is accurate before submitting';
        }
        return null;
      default:
        return null;
    }
  }

  void updateBranch(int locationId) {
    registrationModel.branch = locationId.toString();
    final branchLabel = locations
        .firstWhere(
          (loc) => loc.id == locationId,
          orElse: () => LocationModel(
            id: locationId,
            name: 'Unknown',
            value: '',
            isActive: true,
          ),
        )
        .name;

    LoggerUtils.debug(
      'Branch selected: id=$locationId name=$branchLabel',
      tag: 'NACTET',
    );
    LoggerUtils.debug(
      'Partial payload after branch selection: ${registrationModel.toFields()}',
      tag: 'NACTET',
    );
    notifyListeners();
  }

  bool isBranchSelected(int locationId) {
    return registrationModel.branch == locationId.toString();
  }

  void updateGender(String gender) {
    registrationModel.gender = gender;
    notifyListeners();
  }

  Future<void> checkRegistrationStatus(String enrollmentUid) async {
    isCheckingStatus = true;
    notifyListeners();

    try {
      // Check if form should be displayed
      final displayResponse = await _service.fetchCheckDisplayStatus(
        enrollmentUid: enrollmentUid,
      );
      if (displayResponse.statusCode == 200 && displayResponse.data != null) {
        final dispData = displayResponse.data;
        if (dispData is Map<String, dynamic>) {
          displayForm = dispData['display_form'] ?? true;
        }
      }
    } catch (e) {
      debugPrint('Error checking registration status: $e');
    } finally {
      isCheckingStatus = false;
      notifyListeners();
    }
  }

  void updateBasicQual(String qual) {
    registrationModel.basicEducationalQualification = qual;
    notifyListeners();
  }

  void updateDateOfBirth(String dob) {
    registrationModel.dateOfBirth = dob;
    dobController.text = dob;
    notifyListeners();
  }

  void updateStep(int step) {
    currentStep = step;
    pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < 4) {
      updateStep(currentStep + 1);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      updateStep(currentStep - 1);
    }
  }

  Future<void> pickFile(String type) async {
    fileSizeError = null;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Enforce 10 MB limit
        final fileSize = await File(filePath).length();
        LoggerUtils.debug(
          '[$type] File: $filePath | Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
          tag: 'NACTET',
        );
        if (fileSize > _maxFileSizeBytes) {
          fileSizeError =
              'File exceeds 10 MB limit (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB). Please choose a smaller file.';
          notifyListeners();
          return;
        }

        // Read the bytes now, while the picker's cache copy is still
        // guaranteed to exist. This form is a multi-step wizard — by the
        // time the user reaches submit, Android may have already evicted
        // the file_picker cache entry, so re-reading the path later can
        // throw PathNotFoundException.
        final fileBytes = await File(filePath).readAsBytes();

        switch (type) {
          case 'basic':
            registrationModel.basicDocPath = filePath;
            registrationModel.basicDocBytes = fileBytes;
            break;
          case 'higher':
            registrationModel.higherDocPath = filePath;
            registrationModel.higherDocBytes = fileBytes;
            break;
          case 'id':
            registrationModel.idProofPath = filePath;
            registrationModel.idProofBytes = fileBytes;
            break;
          case 'photo':
            registrationModel.photoPath = filePath;
            registrationModel.photoBytes = fileBytes;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      LoggerUtils.error('Error picking file: $e', tag: 'NACTET');
      fileSizeError = 'Could not read the selected file. Please try again.';
      notifyListeners();
    }
  }

  Future<bool> submit(BuildContext context) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Final sync — all text fields forced to UPPER CASE before sending
      registrationModel.name = nameController.text.trim().toUpperCase();
      registrationModel.guardianName = guardianNameController.text
          .trim()
          .toUpperCase();
      registrationModel.dateOfBirth = dobController.text.trim();
      registrationModel.permanentAddress = addressController.text
          .trim()
          .toUpperCase();
      // Include the selected country code in the mobile number
      registrationModel.mobileNumber =
          '$mobileCountryCode${mobileController.text.trim()}';
      registrationModel.email = emailController.text.trim().toLowerCase();
      registrationModel.basicEducationalQualificationYearOfPassing =
          int.tryParse(basicQualYearController.text.trim());
      registrationModel.higherEducationalQualification = higherQualController
          .text
          .trim()
          .toUpperCase();
      registrationModel.higherEducationalQualificationYearOfPassing =
          int.tryParse(higherQualYearController.text.trim());

      LoggerUtils.debug(
        'Final NACTET submit payload fields: ${registrationModel.toFields()}',
        tag: 'NACTET',
      );

      final response = await _service.submitRegistration(registrationModel);

      if (response.success) {
        successData = response.data;
        isSuccess = true;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage =
            response.message ??
            'Registration failed (status ${response.statusCode})';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggerUtils.error('Submit exception: $e', tag: 'NACTET');
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    currentStep = 0;
    // The PageController retains its last physical page across reopens since
    // this controller is a long-lived, app-level singleton — without this,
    // the PageView stays on the last-viewed step (e.g. step 4) even though
    // currentStep and all the form fields below have been reset to step 1.
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    isSuccess = false;
    isLoading = false;
    confirmationChecked = false;
    errorMessage = null;
    fileSizeError = null;
    successData = null;
    branchAutoDetected = false;
    branchName = null;
    nameController.clear();
    guardianNameController.clear();
    dobController.clear();
    addressController.clear();
    mobileController.clear();
    emailController.clear();
    basicQualYearController.clear();
    higherQualController.clear();
    higherQualYearController.clear();
    // Reset model
    registrationModel.enrollment = null;
    registrationModel.branch = null;
    registrationModel.name = null;
    registrationModel.guardianName = null;
    registrationModel.gender = null;
    registrationModel.dateOfBirth = null;
    registrationModel.permanentAddress = null;
    registrationModel.mobileNumber = null;
    registrationModel.email = null;
    registrationModel.basicEducationalQualification = null;
    registrationModel.basicEducationalQualificationYearOfPassing = null;
    registrationModel.higherEducationalQualification = null;
    registrationModel.higherEducationalQualificationYearOfPassing = null;
    registrationModel.basicDocPath = null;
    registrationModel.higherDocPath = null;
    registrationModel.idProofPath = null;
    registrationModel.photoPath = null;
    registrationModel.basicDocBytes = null;
    registrationModel.higherDocBytes = null;
    registrationModel.idProofBytes = null;
    registrationModel.photoBytes = null;
    registrationModel.course = null;
    registrationModel.batch = null;
    notifyListeners();
  }

  void logStep(int step) {
    final m = registrationModel;
    developer.log(
      '\n'
      '╔══════════════════════════════════════════════════════════╗\n'
      '║        📋  NACTET FORM — STEP $step COMPLETED              ║\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  STEP 1 — PERSONAL\n'
      '║    branch              : ${m.branch ?? '—'}\n'
      '║    name                : ${nameController.text}\n'
      '║    guardian_name       : ${guardianNameController.text}\n'
      '║    gender              : ${m.gender ?? '—'}\n'
      '║    date_of_birth       : ${dobController.text}\n'
      '║    address             : ${addressController.text}\n'
      '║    country_code        : $_mobileCountryCode\n'
      '║    mobile_digits       : ${mobileController.text}\n'
      '║    mobile_full         : $_mobileCountryCode${mobileController.text}\n'
      '║    email               : ${emailController.text}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  STEP 2 — EDUCATION\n'
      '║    basic_qual          : ${m.basicEducationalQualification ?? '—'}\n'
      '║    basic_qual_year     : ${basicQualYearController.text}\n'
      '║    higher_qual         : ${higherQualController.text}\n'
      '║    higher_qual_year    : ${higherQualYearController.text}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  STEP 3 — DOCUMENTS\n'
      '║    basic_doc           : ${m.basicDocPath?.split('/').last ?? '—'}\n'
      '║    higher_doc          : ${m.higherDocPath?.split('/').last ?? '—'}\n'
      '║    id_proof            : ${m.idProofPath?.split('/').last ?? '—'}\n'
      '║    passport_photo      : ${m.photoPath?.split('/').last ?? '—'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  STEP 4 — COURSE\n'
      '║    enrollment          : ${m.enrollment ?? '—'}\n'
      '║    course              : ${m.course ?? '—'}\n'
      '║    batch               : ${m.batch ?? '—'}\n'
      '║    confirmed           : $confirmationChecked\n'
      '╚══════════════════════════════════════════════════════════╝',
      name: '📋 NACTET.Step$step',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    guardianNameController.dispose();
    dobController.dispose();
    addressController.dispose();
    mobileController.dispose();
    emailController.dispose();
    basicQualYearController.dispose();
    higherQualController.dispose();
    higherQualYearController.dispose();
    pageController.dispose();
    super.dispose();
  }
}
