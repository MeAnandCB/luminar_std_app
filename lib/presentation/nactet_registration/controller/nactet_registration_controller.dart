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

  /// Per-field validation errors, keyed by field name (e.g. 'name', 'email',
  /// 'basicDoc'), populated by [validateForm]. The single-page form has no
  /// per-step gate anymore, so this is what lets each field show its own
  /// inline error instead of only a generic top-level message.
  Map<String, String> fieldErrors = {};

  void clearFieldError(String key) {
    if (fieldErrors.containsKey(key)) {
      fieldErrors.remove(key);
      notifyListeners();
    }
  }

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
    clearFieldError('confirmation');
    notifyListeners();
  }

  /// Field order the form is laid out in — used to pick which error to
  /// surface in the top-level SnackBar (the first one the user would
  /// actually scroll past), since [fieldErrors] itself is unordered.
  static const List<String> _fieldOrder = [
    'branch', 'name', 'guardian', 'gender', 'dob', 'address', 'mobile',
    'email', 'basicQual', 'basicQualYear', 'higherQual', 'higherQualYear',
    'basicDoc', 'higherDoc', 'idProof', 'photo', 'confirmation',
  ];

  /// Validates the entire single-page form, populating [fieldErrors] so
  /// every invalid field can show its own inline error — not just the
  /// first one found. Returns the first error message (in field order) for
  /// the top-level SnackBar, or null if the form is valid.
  String? validateForm() {
    final errors = <String, String>{};

    // ── Institution & personal details ──────────────────────────────────
    if (registrationModel.branch == null) {
      errors['branch'] = 'Please select your branch';
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      errors['name'] = 'Please enter your full name';
    } else if (name.length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    } else if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(name)) {
      errors['name'] = 'Name should contain letters only';
    }

    final guardian = guardianNameController.text.trim();
    if (guardian.isEmpty) {
      errors['guardian'] = 'Please enter guardian name';
    } else if (guardian.length < 2) {
      errors['guardian'] = 'Guardian name must be at least 2 characters';
    } else if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(guardian)) {
      errors['guardian'] = 'Guardian name should contain letters only';
    }

    if (registrationModel.gender == null) {
      errors['gender'] = 'Please select your gender';
    }

    if (dobController.text.trim().isEmpty) {
      errors['dob'] = 'Please select your date of birth';
    }

    if (addressController.text.trim().isEmpty) {
      errors['address'] = 'Please enter your permanent address';
    }

    final digits = mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      errors['mobile'] = 'Please enter your mobile number';
    } else if (digits.length < 7) {
      errors['mobile'] = 'Mobile number must be at least 7 digits';
    } else if (digits.length > 15) {
      errors['mobile'] = 'Mobile number must not exceed 15 digits';
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Please enter your email';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    // ── Educational qualification ───────────────────────────────────────
    if (registrationModel.basicEducationalQualification == null) {
      errors['basicQual'] = 'Please select basic educational qualification';
    }

    final basicYearText = basicQualYearController.text.trim();
    if (basicYearText.isEmpty) {
      errors['basicQualYear'] = 'Please enter year of passing';
    } else {
      final basicYear = int.tryParse(basicYearText);
      if (basicYear == null ||
          basicYear < 1950 ||
          basicYear > DateTime.now().year + 5) {
        errors['basicQualYear'] =
            'Enter a valid year (1950–${DateTime.now().year + 5})';
      }
    }

    if (higherQualController.text.trim().isEmpty) {
      errors['higherQual'] = 'Please enter your highest educational qualification';
    }

    final higherYearText = higherQualYearController.text.trim();
    if (higherYearText.isEmpty) {
      errors['higherQualYear'] = 'Please enter year of passing';
    } else {
      final higherYear = int.tryParse(higherYearText);
      if (higherYear == null ||
          higherYear < 1950 ||
          higherYear > DateTime.now().year + 5) {
        errors['higherQualYear'] =
            'Enter a valid year (1950–${DateTime.now().year + 5})';
      }
    }

    // ── Documents ────────────────────────────────────────────────────────
    if (registrationModel.basicDocPath == null) {
      errors['basicDoc'] = 'Please upload this document';
    }
    if (registrationModel.higherDocPath == null) {
      errors['higherDoc'] = 'Please upload this document';
    }
    if (registrationModel.idProofPath == null) {
      errors['idProof'] = 'Please upload your ID proof';
    }
    if (registrationModel.photoPath == null) {
      errors['photo'] = 'Please upload your passport size photo';
    }

    // ── Confirmation ─────────────────────────────────────────────────────
    if (!confirmationChecked) {
      errors['confirmation'] =
          'Please confirm that all information is accurate before submitting';
    }

    fieldErrors = errors;
    notifyListeners();

    if (errors.isEmpty) return null;
    for (final key in _fieldOrder) {
      if (errors.containsKey(key)) return errors[key];
    }
    return errors.values.first;
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
    clearFieldError('branch');
    notifyListeners();
  }

  bool isBranchSelected(int locationId) {
    return registrationModel.branch == locationId.toString();
  }

  void updateGender(String gender) {
    registrationModel.gender = gender;
    clearFieldError('gender');
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
    clearFieldError('basicQual');
    notifyListeners();
  }

  void updateDateOfBirth(String dob) {
    registrationModel.dateOfBirth = dob;
    dobController.text = dob;
    clearFieldError('dob');
    notifyListeners();
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
        // guaranteed to exist. Time can pass between picking a document and
        // hitting submit, and Android may evict the file_picker cache entry
        // in the meantime, so re-reading the path later can throw
        // PathNotFoundException.
        final fileBytes = await File(filePath).readAsBytes();

        switch (type) {
          case 'basic':
            registrationModel.basicDocPath = filePath;
            registrationModel.basicDocBytes = fileBytes;
            clearFieldError('basicDoc');
            break;
          case 'higher':
            registrationModel.higherDocPath = filePath;
            registrationModel.higherDocBytes = fileBytes;
            clearFieldError('higherDoc');
            break;
          case 'id':
            registrationModel.idProofPath = filePath;
            registrationModel.idProofBytes = fileBytes;
            clearFieldError('idProof');
            break;
          case 'photo':
            registrationModel.photoPath = filePath;
            registrationModel.photoBytes = fileBytes;
            clearFieldError('photo');
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
    isSuccess = false;
    isLoading = false;
    confirmationChecked = false;
    errorMessage = null;
    fileSizeError = null;
    fieldErrors = {};
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

  void logFormSnapshot() {
    final m = registrationModel;
    developer.log(
      '\n'
      '╔══════════════════════════════════════════════════════════╗\n'
      '║        📋  NACTET FORM — READY TO SUBMIT                  ║\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  PERSONAL\n'
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
      '║  EDUCATION\n'
      '║    basic_qual          : ${m.basicEducationalQualification ?? '—'}\n'
      '║    basic_qual_year     : ${basicQualYearController.text}\n'
      '║    higher_qual         : ${higherQualController.text}\n'
      '║    higher_qual_year    : ${higherQualYearController.text}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  DOCUMENTS\n'
      '║    basic_doc           : ${m.basicDocPath?.split('/').last ?? '—'}\n'
      '║    higher_doc          : ${m.higherDocPath?.split('/').last ?? '—'}\n'
      '║    id_proof            : ${m.idProofPath?.split('/').last ?? '—'}\n'
      '║    passport_photo      : ${m.photoPath?.split('/').last ?? '—'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  COURSE\n'
      '║    enrollment          : ${m.enrollment ?? '—'}\n'
      '║    course              : ${m.course ?? '—'}\n'
      '║    batch               : ${m.batch ?? '—'}\n'
      '║    confirmed           : $confirmationChecked\n'
      '╚══════════════════════════════════════════════════════════╝',
      name: '📋 NACTET.Submit',
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
    super.dispose();
  }
}
