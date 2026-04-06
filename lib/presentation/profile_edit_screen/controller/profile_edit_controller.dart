import 'package:flutter/material.dart';
import 'package:luminar_std/repository/complete_profile/service.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditController extends ChangeNotifier {
  final CompleteProfileService _submissionService = CompleteProfileService();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  final ImagePicker _picker = ImagePicker();
  String? _profilePicPath;
  String? get profilePicPath => _profilePicPath;

  String? _error;
  String? get error => _error;

  // Form Controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final dobController = TextEditingController();
  final ageController = TextEditingController();
  final qualificationController = TextEditingController();
  final collegeController = TextEditingController();
  final passoutYearController = TextEditingController();
  final specializationController = TextEditingController();
  final cgpaController = TextEditingController();
  final admissionDateController = TextEditingController();
  final addressController = TextEditingController();
  final districtController = TextEditingController();
  final pincodeController = TextEditingController();
  final preferredLocationController = TextEditingController();
  final parentNameController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final hearAboutController = TextEditingController();
  final preferredJobLocationController = TextEditingController();

  String _selectedStudentType = 'student';
  String get selectedStudentType => _selectedStudentType;
  set selectedStudentType(String value) {
    _selectedStudentType = value;
    notifyListeners();
  }

  bool _anyArrears = false;
  bool get anyArrears => _anyArrears;
  set anyArrears(bool value) {
    _anyArrears = value;
    notifyListeners();
  }

  bool _placementAssistance = true;
  bool get placementAssistance => _placementAssistance;
  set placementAssistance(bool value) {
    _placementAssistance = value;
    notifyListeners();
  }

  DateTime? _selectedDob;
  DateTime? _selectedAdmissionDate;

  void init(Profile? profile, {bool notify = true}) {
    if (profile == null) return;

    final p = profile.personalInfo;
    final a = profile.academicInfo;
    final c = profile.contactInfo;
    final pl = profile.placementInfo;

    // Personal Info
    fullNameController.text = p?.fullName ?? '';
    emailController.text = p?.email ?? '';
    phoneController.text = p?.phone ?? '';
    whatsappController.text = p?.whatsappNumber ?? '';
    _selectedDob = p?.dateOfBirth;
    dobController.text = _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : '';
    ageController.text = p?.age?.toString() ?? '';

    // Academic Info
    qualificationController.text = a?.qualification?.name ?? '';
    collegeController.text = a?.college ?? '';
    passoutYearController.text = a?.passOutYear?.toString() ?? '';
    specializationController.text = a?.specialization ?? '';
    cgpaController.text = a?.cgpa?.toString() ?? '';
    _selectedAdmissionDate = a?.admissionDate;
    admissionDateController.text = _selectedAdmissionDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedAdmissionDate!)
        : '';
    _anyArrears = a?.anyArrears ?? false;
    _selectedStudentType = a?.studentOrWorkingProfessional?.toLowerCase() ?? 'student';

    // Contact Info
    addressController.text = c?.address ?? '';
    districtController.text = c?.district ?? '';
    pincodeController.text = c?.pincode ?? '';
    preferredLocationController.text = c?.preferredLocation?.name ?? '';
    parentNameController.text = c?.parentName ?? '';
    parentPhoneController.text = c?.parentPhone ?? '';
    hearAboutController.text = c?.howDidYouHear ?? '';

    // Placement Info
    _placementAssistance = pl?.placementAssistance ?? true;
    preferredJobLocationController.text = pl?.preferredJobLocation ?? '';

    if (notify) notifyListeners();
  }

  void updateDob(DateTime date) {
    _selectedDob = date;
    dobController.text = DateFormat('yyyy-MM-dd').format(date);

    // Calculate Age
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
      age--;
    }
    ageController.text = age.toString();
    notifyListeners();
  }

  void updateAdmissionDate(DateTime date) {
    _selectedAdmissionDate = date;
    admissionDateController.text = DateFormat('yyyy-MM-dd').format(date);
    notifyListeners();
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        _profilePicPath = image.path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Future<bool> updateProfile(BuildContext context, Profile? initialProfile) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> deltaFields = {};

      void addIfChanged(String key, dynamic newValue, dynamic oldValue) {
        if (newValue != null && newValue.toString() != oldValue?.toString()) {
          deltaFields[key] = newValue;
        }
      }

      final p = initialProfile?.personalInfo;
      final a = initialProfile?.academicInfo;
      final c = initialProfile?.contactInfo;
      final pl = initialProfile?.placementInfo;

      // Only add editable fields (excluding name, email, phone)
      addIfChanged('whatsapp_number', whatsappController.text, p?.whatsappNumber);
      addIfChanged(
        'date_of_birth',
        dobController.text,
        p?.dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(p!.dateOfBirth!) : null,
      );
      addIfChanged('age', int.tryParse(ageController.text), p?.age);

      addIfChanged('qualification', qualificationController.text, a?.qualification?.name);
      addIfChanged('college', collegeController.text, a?.college);
      addIfChanged('pass_out_year', int.tryParse(passoutYearController.text), a?.passOutYear);
      addIfChanged('specialization', specializationController.text, a?.specialization);
      addIfChanged('cgpa', double.tryParse(cgpaController.text), a?.cgpa);
      addIfChanged(
        'admission_date',
        admissionDateController.text,
        a?.admissionDate != null ? DateFormat('yyyy-MM-dd').format(a!.admissionDate!) : null,
      );
      addIfChanged('any_arrears', _anyArrears, a?.anyArrears);
      addIfChanged(
        'student_or_working_professional',
        _selectedStudentType,
        a?.studentOrWorkingProfessional?.toLowerCase(),
      );

      addIfChanged('address', addressController.text, c?.address);
      addIfChanged('district', districtController.text, c?.district);
      addIfChanged('pincode', pincodeController.text, c?.pincode);
      addIfChanged('preferred_location', preferredLocationController.text, c?.preferredLocation?.name);
      addIfChanged('parent_name', parentNameController.text, c?.parentName);
      addIfChanged('parent_phone', parentPhoneController.text, c?.parentPhone);
      addIfChanged('how_did_you_hear', hearAboutController.text, c?.howDidYouHear);

      addIfChanged('placement_assistance', _placementAssistance, pl?.placementAssistance);
      addIfChanged('preferred_job_location', preferredJobLocationController.text, pl?.preferredJobLocation);

      if (deltaFields.isEmpty && _profilePicPath == null) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      }

      await _submissionService.submitProfile(
        student_id: p?.studentId.toString(),
        fields: deltaFields,
        profilePicPath: _profilePicPath,
      );

      // Refresh ProfileController
      if (context.mounted) {
        await context.read<ProfileController>().refreshProfile(context: context);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    dobController.dispose();
    ageController.dispose();
    qualificationController.dispose();
    collegeController.dispose();
    passoutYearController.dispose();
    specializationController.dispose();
    cgpaController.dispose();
    admissionDateController.dispose();
    addressController.dispose();
    districtController.dispose();
    pincodeController.dispose();
    preferredLocationController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    hearAboutController.dispose();
    preferredJobLocationController.dispose();
    super.dispose();
  }
}
