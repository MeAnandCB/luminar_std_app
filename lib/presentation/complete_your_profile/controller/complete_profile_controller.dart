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

  Uint8List? _idFrontImage;
  Uint8List? _idBackImage;
  Uint8List? _profilePic;

  Uint8List? get idFrontImage => _idFrontImage;
  Uint8List? get idBackImage => _idBackImage;
  Uint8List? get profilePic => _profilePic;

  List<Qualification> _qualifications = [];
  List<Specialization> _specializations = [];
  bool _isLoadingAcademic = false;
  bool _isSubmitting = false;

  List<Qualification> get qualifications => _qualifications;
  List<Specialization> get specializations => _specializations;
  bool get isLoadingAcademic => _isLoadingAcademic;
  bool get isSubmitting => _isSubmitting;

  // Form Fields
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
        final Uint8List bytes = await image.readAsBytes();
        if (isFront) {
          _idFrontImage = bytes;
        } else {
          _idBackImage = bytes;
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
        _profilePic = await image.readAsBytes();
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
      final Map<String, String> deltaFields = {};

      // Helper to add if changed
      void addIfChanged(String key, dynamic currentValue, dynamic initialValue) {
        if (currentValue != null && currentValue.toString() != initialValue?.toString()) {
          deltaFields[key] = currentValue.toString();
        }
      }

      // Personal / Contact
      addIfChanged('whatsapp_number', whatsappNumber, initialProfile?.personalInfo?.whatsappNumber);
      addIfChanged('date_of_birth', dateOfBirth, initialProfile?.personalInfo?.dateOfBirth);
      addIfChanged('address', address, initialProfile?.contactInfo?.address);
      addIfChanged('pincode', pincode, initialProfile?.contactInfo?.pincode);
      addIfChanged('district', district, initialProfile?.contactInfo?.district);

      // Academic
      addIfChanged('qualification', qualificationId, initialProfile?.academicInfo?.qualification?.id);
      addIfChanged('college', college, initialProfile?.academicInfo?.college);
      addIfChanged('pass_out_year', passOutYear, initialProfile?.academicInfo?.passOutYear);
      addIfChanged('specialization', specialization, initialProfile?.academicInfo?.specialization);
      addIfChanged('cgpa', cgpa, initialProfile?.academicInfo?.cgpa);
      if (anyArrears != null && anyArrears != initialProfile?.academicInfo?.anyArrears) {
        deltaFields['any_arrears'] = anyArrears!.toString();
      }

      // Career
      addIfChanged('student_or_working_professional', studentStatus, initialProfile?.academicInfo?.studentOrWorkingProfessional);
      if (placementAssistance != null && placementAssistance != initialProfile?.placementInfo?.placementAssistance) {
        deltaFields['placement_assistance'] = placementAssistance!.toString();
      }
      addIfChanged('preferred_job_location', preferredJobLocation, initialProfile?.placementInfo?.preferredJobLocation);

      // Parent
      addIfChanged('parent_name', parentName, initialProfile?.contactInfo?.parentName);
      addIfChanged('parent_phone', parentPhone, initialProfile?.contactInfo?.parentPhone);

      if (deltaFields.isEmpty && _idFrontImage == null && _idBackImage == null && _profilePic == null) {
        // Nothing to update
        return;
      }

      await _submissionService.submitProfile(
        fields: deltaFields,
        idFront: _idFrontImage,
        idBack: _idBackImage,
        profilePic: _profilePic,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearImages() {
    _idFrontImage = null;
    _idBackImage = null;
    _profilePic = null;
    notifyListeners();
  }
}
