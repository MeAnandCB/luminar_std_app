import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_registration_model.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_check_display_model.dart';
import 'package:luminar_std/repository/nactet_registration/service/nactet_registration_service.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';

class NactetRegistrationController extends ChangeNotifier {
  final NactetRegistrationService _service = NactetRegistrationService();
  final NactetRegistrationModel registrationModel = NactetRegistrationModel();

  int currentStep = 0;
  bool isLoading = false;
  bool isCheckingStatus = false;
  bool isSuccess = false;
  bool displayForm = true;
  bool confirmationChecked = false;
  String? errorMessage;
  String? fileSizeError;
  dynamic successData;

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

  void init(Enrollment? enrollment, String? studentName, String? studentEmail, String? studentMobile) {
    if (enrollment != null) {
      registrationModel.enrollment = enrollment.uid;
      registrationModel.course = 1; 
      registrationModel.batch = enrollment.batch.uid;
      // Map branch name to ID if needed (e.g., Calicut -> 7)
      registrationModel.branch = "7"; 
      
      // Auto-check if already filled
      checkRegistrationStatus(enrollment.uid);
    }
    
    if (studentName != null && nameController.text.isEmpty) {
      nameController.text = studentName;
      registrationModel.name = studentName;
    }
    if (studentEmail != null && emailController.text.isEmpty) {
      emailController.text = studentEmail;
      registrationModel.email = studentEmail;
    }
    if (studentMobile != null && mobileController.text.isEmpty) {
      mobileController.text = studentMobile;
      registrationModel.mobileNumber = studentMobile;
    }
    
    notifyListeners();
  }

  /// Used when navigating from the multi-enrollment selection sheet.
  void initFromNactetEnrollment(
    NactetCheckDisplayEnrollment enrollment,
    String? studentName,
    String? studentEmail,
    String? studentMobile,
  ) {
    registrationModel.enrollment = enrollment.enrollmentUid;
    registrationModel.course = enrollment.courseId;
    registrationModel.batch = enrollment.batchUid;
    registrationModel.branch = "7";

    checkRegistrationStatus(enrollment.enrollmentUid);

    if (studentName != null && nameController.text.isEmpty) {
      nameController.text = studentName;
      registrationModel.name = studentName;
    }
    if (studentEmail != null && emailController.text.isEmpty) {
      emailController.text = studentEmail;
      registrationModel.email = studentEmail;
    }
    if (studentMobile != null && mobileController.text.isEmpty) {
      mobileController.text = studentMobile;
      registrationModel.mobileNumber = studentMobile;
    }

    notifyListeners();
  }

  void toggleConfirmation() {
    confirmationChecked = !confirmationChecked;
    notifyListeners();
  }

  /// Returns an error message if the current step is invalid, null if valid.
  String? validateStep(int step) {
    switch (step) {
      case 0:
        if (registrationModel.branch == null) return 'Please select your branch';
        if (nameController.text.trim().isEmpty) return 'Please enter your full name';
        if (guardianNameController.text.trim().isEmpty) return 'Please enter guardian name';
        if (registrationModel.gender == null) return 'Please select your gender';
        if (dobController.text.trim().isEmpty) return 'Please select your date of birth';
        if (addressController.text.trim().isEmpty) return 'Please enter your permanent address';
        if (mobileController.text.trim().isEmpty) return 'Please enter your mobile number';
        if (mobileController.text.trim().length < 5) return 'Please enter a valid mobile number';
        if (emailController.text.trim().isEmpty) return 'Please enter your email';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
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
        if (basicYear == null || basicYear < 1950 || basicYear > DateTime.now().year) {
          return 'Please enter a valid year (1950–${DateTime.now().year})';
        }
        if (higherQualController.text.trim().isEmpty) {
          return 'Please enter your highest educational qualification';
        }
        if (higherQualYearController.text.trim().isEmpty) {
          return 'Please enter year of passing for highest qualification';
        }
        final higherYear = int.tryParse(higherQualYearController.text.trim());
        if (higherYear == null || higherYear < 1950 || higherYear > DateTime.now().year) {
          return 'Please enter a valid year (1950–${DateTime.now().year})';
        }
        return null;
      case 2:
        if (registrationModel.basicDocPath == null) {
          return 'Please upload your basic qualification document';
        }
        if (registrationModel.higherDocPath == null) {
          return 'Please upload your highest qualification document';
        }
        if (registrationModel.idProofPath == null) return 'Please upload your ID proof';
        if (registrationModel.photoPath == null) return 'Please upload your passport size photo';
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

  void updateBranch(String branchName) {
    // Map labels to IDs
    String branchId = "7";
    if (branchName.toLowerCase() == 'calicut') branchId = "7";
    else if (branchName.toLowerCase() == 'cochin') branchId = "1";
    else if (branchName.toLowerCase() == 'thrissur') branchId = "3";
    
    registrationModel.branch = branchId;
    notifyListeners();
  }

  bool isBranchSelected(String branchName) {
    String expectedId = "7";
    if (branchName.toLowerCase() == 'calicut') expectedId = "7";
    else if (branchName.toLowerCase() == 'cochin') expectedId = "1";
    else if (branchName.toLowerCase() == 'thrissur') expectedId = "3";
    
    return registrationModel.branch == expectedId;
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
      final displayResponse = await _service.fetchCheckDisplayStatus(enrollmentUid: enrollmentUid);
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
    if (currentStep < 3) {
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
        LoggerUtils.debug('[$type] File: $filePath | Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB', tag: 'NACTET');
        if (fileSize > _maxFileSizeBytes) {
          fileSizeError = 'File exceeds 10 MB limit (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB). Please choose a smaller file.';
          notifyListeners();
          return;
        }

        switch (type) {
          case 'basic':
            registrationModel.basicDocPath = filePath;
            break;
          case 'higher':
            registrationModel.higherDocPath = filePath;
            break;
          case 'id':
            registrationModel.idProofPath = filePath;
            break;
          case 'photo':
            registrationModel.photoPath = filePath;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      LoggerUtils.error('Error picking file: $e', tag: 'NACTET');
    }
  }

  Future<bool> submit(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Final sync of controllers to model
      registrationModel.name = nameController.text.trim();
      registrationModel.guardianName = guardianNameController.text.trim();
      registrationModel.dateOfBirth = dobController.text.trim();
      registrationModel.permanentAddress = addressController.text.trim();
      registrationModel.mobileNumber = mobileController.text.trim();
      registrationModel.email = emailController.text.trim();
      registrationModel.basicEducationalQualificationYearOfPassing =
          int.tryParse(basicQualYearController.text.trim());
      registrationModel.higherEducationalQualification = higherQualController.text.trim();
      registrationModel.higherEducationalQualificationYearOfPassing =
          int.tryParse(higherQualYearController.text.trim());

      // Debug: print all fields being sent
      final fields = registrationModel.toFields();
      LoggerUtils.debug('--- NACTET SUBMIT FIELDS ---', tag: 'NACTET');
      fields.forEach((k, v) => LoggerUtils.debug('  $k: $v', tag: 'NACTET'));
      LoggerUtils.debug('  basicDoc: ${registrationModel.basicDocPath}', tag: 'NACTET');
      LoggerUtils.debug('  higherDoc: ${registrationModel.higherDocPath}', tag: 'NACTET');
      LoggerUtils.debug('  idProof: ${registrationModel.idProofPath}', tag: 'NACTET');
      LoggerUtils.debug('  photo: ${registrationModel.photoPath}', tag: 'NACTET');

      final response = await _service.submitRegistration(registrationModel);

      LoggerUtils.debug('--- NACTET RESPONSE ---', tag: 'NACTET');
      LoggerUtils.debug('  status: ${response.statusCode}', tag: 'NACTET');
      LoggerUtils.debug('  success: ${response.success}', tag: 'NACTET');
      LoggerUtils.debug('  message: ${response.message}', tag: 'NACTET');
      LoggerUtils.debug('  data: ${response.data}', tag: 'NACTET');

      if (response.success) {
        successData = response.data;
        isSuccess = true;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = response.message ?? 'Registration failed (status ${response.statusCode})';
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
    isSuccess = false;
    isLoading = false;
    confirmationChecked = false;
    errorMessage = null;
    fileSizeError = null;
    successData = null;
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
    registrationModel.course = null;
    registrationModel.batch = null;
    notifyListeners();
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
