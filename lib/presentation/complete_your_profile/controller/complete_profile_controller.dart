import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luminar_std/repository/academic_info/model.dart';
import 'package:luminar_std/repository/academic_info/service.dart';
import 'package:luminar_std/repository/complete_profile/service.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart' as model;

class CompleteProfileController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final AcademicInfoService _academicService = AcademicInfoService();
  final CompleteProfileService _submissionService = CompleteProfileService();

  String? _idFrontPath;
  String? _idBackPath;
  String? _profilePicPath;
  String? _resumePath;

  String? get idFrontPath => _idFrontPath;
  String? get idBackPath => _idBackPath;
  String? get profilePicPath => _profilePicPath;
  String? get resumePath => _resumePath;

  List<Qualification> _qualifications = [];
  List<Specialization> _specializations = [];
  bool _isLoadingAcademic = false;
  bool _isSubmitting = false;

  List<Qualification> get qualifications => _qualifications;
  List<Specialization> get specializations => _specializations;
  bool get isLoadingAcademic => _isLoadingAcademic;
  bool get isSubmitting => _isSubmitting;

  // Form Fields
  String? fullName;
  String? email;
  String? phone;
  String? whatsappNumber;
  String? dateOfBirth;
  String? address;
  String? pincode;
  String? district;

  String? qualificationId; // id from model
  String? qualificationName;
  String? college;
  String? passOutYear;
  String? specialization;
  String? cgpa;
  bool? anyArrears;

  String? studentStatus; // student or professional
  bool? placementAssistance;
  String? preferredJobLocation;

  String? parentName;
  String? parentPhone;

  // Additional fields from user's request
  bool? isActive;
  String? profilePicBase64;
  int? statusId;
  int? preferredLocationId;
  String? referrerId;
  String? studentId;
  int? convertedFromLead;
  String? placementCompany;
  String? placementPackage;
  String? placementDate;
  String? admissionDate;
  int? age;
  String? notes;
  String? howDidYouHear;
  bool? portalAccessEnabled;
  bool? isAlumni;
  bool? isPlaced;

  void setResume(String? path) {
    _resumePath = path;
    notifyListeners();
  }

  Future<void> fetchAcademicDropdowns() async {
    _isLoadingAcademic = true;
    notifyListeners();

    try {
      final qRes = await _academicService.getQualifications();
      final sRes = await _academicService.getSpecializations();

      if (qRes.success && qRes.data != null) {
        _qualifications = qRes.data!.qualifications;
      }
      if (sRes.success && sRes.data != null) {
        _specializations = sRes.data!.specializations;
      }
    } catch (e) {
      debugPrint('Error fetching academic data: $e');
    } finally {
      _isLoadingAcademic = false;
      notifyListeners();
    }
  }

  Future<void> pickIdImage({required bool isFront, required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        if (isFront) {
          _idFrontPath = image.path;
        } else {
          _idBackPath = image.path;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking ID image: $e');
    }
  }

  Future<void> pickProfilePic() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        _profilePicPath = image.path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking profile pic: $e');
    }
  }

  Future<void> submitProfile(model.Profile? initialProfile) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final Map<String, dynamic> deltaFields = {};

      // Helper to add if changed or if initial is null
      void addIfChanged(String key, dynamic currentValue, dynamic initialValue) {
        if (currentValue != null && currentValue.toString() != initialValue?.toString()) {
          deltaFields[key] = currentValue;
        }
      }

      // Personal / Contact
      addIfChanged('full_name', fullName, initialProfile?.personalInfo?.fullName);
      addIfChanged('email', email, initialProfile?.personalInfo?.email);
      addIfChanged('phone', phone, initialProfile?.personalInfo?.phone);
      addIfChanged('whatsapp_number', whatsappNumber, initialProfile?.personalInfo?.whatsappNumber);
      addIfChanged('date_of_birth', dateOfBirth, initialProfile?.personalInfo?.dateOfBirth?.toString().split(' ').first);
      addIfChanged('age', age, initialProfile?.personalInfo?.age);
      addIfChanged('address', address, initialProfile?.contactInfo?.address);
      addIfChanged('pincode', pincode, initialProfile?.contactInfo?.pincode);
      addIfChanged('district', district, initialProfile?.contactInfo?.district);

      // Academic
      addIfChanged('qualification_id', qualificationId, initialProfile?.academicInfo?.qualification?.id);
      addIfChanged('college', college, initialProfile?.academicInfo?.college);
      addIfChanged('pass_out_year', passOutYear, initialProfile?.academicInfo?.passOutYear);
      addIfChanged('specialization', specialization, initialProfile?.academicInfo?.specialization);
      addIfChanged('cgpa', cgpa, initialProfile?.academicInfo?.cgpa);
      addIfChanged('admission_date', admissionDate, initialProfile?.academicInfo?.admissionDate);
      if (anyArrears != null && anyArrears != initialProfile?.academicInfo?.anyArrears) {
        deltaFields['any_arrears'] = anyArrears;
      }

      // Career
      addIfChanged(
        'student_or_working_professional',
        studentStatus,
        initialProfile?.academicInfo?.studentOrWorkingProfessional,
      );
      if (placementAssistance != null && placementAssistance != initialProfile?.placementInfo?.placementAssistance) {
        deltaFields['placement_assistance'] = placementAssistance;
      }
      addIfChanged('preferred_job_location', preferredJobLocation, initialProfile?.placementInfo?.preferredJobLocation);

      // Parent
      addIfChanged('parent_name', parentName, initialProfile?.contactInfo?.parentName);
      addIfChanged('parent_phone_number', parentPhone, initialProfile?.contactInfo?.parentPhone);

      // Status / Others
      if (isActive != null) deltaFields['is_active'] = isActive;
      if (profilePicBase64 != null) deltaFields['profile_pic_base64'] = profilePicBase64;
      if (statusId != null) deltaFields['status_id'] = statusId;
      if (preferredLocationId != null) deltaFields['preferred_location_id'] = preferredLocationId;
      if (referrerId != null) deltaFields['referrer_id'] = referrerId;
      if (studentId != null) deltaFields['student_id'] = studentId;
      if (convertedFromLead != null) deltaFields['converted_from_lead'] = convertedFromLead;
      if (placementCompany != null) deltaFields['placement_company'] = placementCompany;
      if (placementPackage != null) deltaFields['placement_package'] = placementPackage;
      if (placementDate != null) deltaFields['placement_date'] = placementDate;
      if (notes != null) deltaFields['notes'] = notes;
      if (howDidYouHear != null) deltaFields['how_did_you_hear'] = howDidYouHear;
      if (portalAccessEnabled != null) deltaFields['portal_access_enabled'] = portalAccessEnabled;
      if (isAlumni != null) deltaFields['is_alumni'] = isAlumni;
      if (isPlaced != null) deltaFields['is_placed'] = isPlaced;

      if (deltaFields.isEmpty &&
          _idFrontPath == null &&
          _idBackPath == null &&
          _profilePicPath == null &&
          _resumePath == null) {
        // Nothing to update
        _isSubmitting = false;
        notifyListeners();
        return;
      }

      await _submissionService.submitProfile(
        student_id: initialProfile?.personalInfo?.studentId.toString(),
        fields: deltaFields,
        idFrontPath: _idFrontPath,
        idBackPath: _idBackPath,
        profilePicPath: _profilePicPath,
        resumePath: _resumePath,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearFiles() {
    _idFrontPath = null;
    _idBackPath = null;
    _profilePicPath = null;
    _resumePath = null;
    notifyListeners();
  }
}
