import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_registration_model.dart';
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
  String? errorMessage;
  dynamic successData;

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
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        switch (type) {
          case 'basic':
            registrationModel.basicDocPath = path;
            break;
          case 'higher':
            registrationModel.higherDocPath = path;
            break;
          case 'id':
            registrationModel.idProofPath = path;
            break;
          case 'photo':
            registrationModel.photoPath = path;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      LoggerUtils.error("Error picking file: $e", tag: 'NACTET');
    }
  }

  Future<bool> submit(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Final sync of controllers to model
      registrationModel.name = nameController.text;
      registrationModel.guardianName = guardianNameController.text;
      registrationModel.dateOfBirth = dobController.text;
      registrationModel.permanentAddress = addressController.text;
      registrationModel.mobileNumber = mobileController.text;
      registrationModel.email = emailController.text;
      registrationModel.basicEducationalQualificationYearOfPassing = 
          int.tryParse(basicQualYearController.text);
      registrationModel.higherEducationalQualification = higherQualController.text;
      registrationModel.higherEducationalQualificationYearOfPassing = 
          int.tryParse(higherQualYearController.text);

      final response = await _service.submitRegistration(registrationModel);

      if (response.success) {
        successData = response.data;
        isSuccess = true;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = response.message ?? "Registration failed";
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
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
    errorMessage = null;
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
