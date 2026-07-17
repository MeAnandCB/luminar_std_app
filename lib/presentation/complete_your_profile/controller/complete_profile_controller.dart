import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/core/utils/picked_file_utils.dart';
import 'package:luminar_std/repository/academic_info/model.dart';
import 'package:luminar_std/repository/academic_info/service.dart';
import 'package:luminar_std/repository/complete_profile/service.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart' as model;

class ProfileFieldStatus {
  final String name;
  final bool isFilled;
  final int pageIndex;
  final String section;

  const ProfileFieldStatus({
    required this.name,
    required this.isFilled,
    required this.pageIndex,
    required this.section,
  });
}

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

  // Server-side flags — set when initializing form from existing profile data
  bool serverProfilePic = false;
  bool serverIdFront = false;
  bool serverIdBack = false;
  bool serverResume = false;

  List<Qualification> _qualifications = [];
  List<Specialization> _specializations = [];
  bool _isLoadingAcademic = false;
  bool _isSubmitting = false;

  List<Qualification> get qualifications => _qualifications;
  List<Specialization> get specializations => _specializations;
  bool get isLoadingAcademic => _isLoadingAcademic;
  bool get isSubmitting => _isSubmitting;

  // Form Fields — setters notify listeners so progress bar updates live
  String? _fullName; String? get fullName => _fullName;
  set fullName(String? v) { _fullName = v; notifyListeners(); }

  String? _email; String? get email => _email;
  set email(String? v) { _email = v; notifyListeners(); }

  String? _phone; String? get phone => _phone;
  set phone(String? v) { _phone = v; notifyListeners(); }

  String? whatsappNumber;
  String? _dateOfBirth; String? get dateOfBirth => _dateOfBirth;
  set dateOfBirth(String? v) { _dateOfBirth = v; notifyListeners(); }

  String? _address; String? get address => _address;
  set address(String? v) { _address = v; notifyListeners(); }

  String? _pincode; String? get pincode => _pincode;
  set pincode(String? v) { _pincode = v; notifyListeners(); }

  String? _district; String? get district => _district;
  set district(String? v) { _district = v; notifyListeners(); }

  String? _qualificationId; String? get qualificationId => _qualificationId;
  set qualificationId(String? v) { _qualificationId = v; notifyListeners(); }
  String? qualificationName;

  String? _college; String? get college => _college;
  set college(String? v) { _college = v; notifyListeners(); }

  String? _passOutYear; String? get passOutYear => _passOutYear;
  set passOutYear(String? v) { _passOutYear = v; notifyListeners(); }

  String? _specialization; String? get specialization => _specialization;
  set specialization(String? v) { _specialization = v; notifyListeners(); }

  String? _cgpa; String? get cgpa => _cgpa;
  set cgpa(String? v) { _cgpa = v; notifyListeners(); }

  bool? anyArrears;

  String? _studentStatus; String? get studentStatus => _studentStatus;
  set studentStatus(String? v) { _studentStatus = v; notifyListeners(); }

  bool? placementAssistance;
  String? preferredJobLocation;
  String? linkedinLink;
  String? portfolioLink;

  String? _parentName; String? get parentName => _parentName;
  set parentName(String? v) { _parentName = v; notifyListeners(); }

  String? _parentPhone; String? get parentPhone => _parentPhone;
  set parentPhone(String? v) { _parentPhone = v; notifyListeners(); }

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
  String? _admissionDate; String? get admissionDate => _admissionDate;
  set admissionDate(String? v) { _admissionDate = v; notifyListeners(); }

  int? _age; int? get age => _age;
  set age(int? v) { _age = v; notifyListeners(); }
  String? notes;
  String? howDidYouHear;
  bool? portalAccessEnabled;
  bool? isAlumni;
  bool? isPlaced;

  // ── Live progress tracking ─────────────────────────────────────────────────
  static const int totalFields = 19;

  int get filledFieldsCount {
    int count = 0;
    bool _filled(String? v) => v != null && v.trim().isNotEmpty;

    if (_filled(fullName)) count++;
    if (_filled(email)) count++;
    if (_filled(phone)) count++;
    if (_filled(dateOfBirth)) count++;
    if (age != null) count++;
    if (_idFrontPath != null || serverIdFront) count++;
    if (_idBackPath != null || serverIdBack) count++;
    if (_filled(address)) count++;
    if (_filled(pincode)) count++;
    if (_filled(district)) count++;
    if (_filled(qualificationId)) count++;
    if (_filled(college)) count++;
    if (_filled(passOutYear)) count++;
    if (_filled(specialization)) count++;
    if (_filled(cgpa)) count++;
    if (_filled(admissionDate)) count++;
    if (_filled(studentStatus)) count++;
    if (_filled(parentName)) count++;
    if (_filled(parentPhone)) count++;
    return count > totalFields ? totalFields : count;
  }

  double get completionPercentage => filledFieldsCount / totalFields;
  int get remainingFieldsCount => totalFields - filledFieldsCount;

  void notifyProgress() => notifyListeners();

  Future<void> setResume(String? path) async {
    if (path == null) {
      _resumePath = null;
      notifyListeners();
      return;
    }
    try {
      _resumePath = await PickedFileUtils.persist(path);
    } catch (e) {
      debugPrint('Error persisting resume file: $e');
      _resumePath = path;
    }
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
        debugPrint('[AcademicDropdowns] ✅ qualifications loaded: ${_qualifications.length} items');
      } else {
        debugPrint('[AcademicDropdowns] ❌ qualifications FAILED [${qRes.statusCode}]: ${qRes.message}');
      }

      if (sRes.success && sRes.data != null) {
        _specializations = sRes.data!.specializations;
        debugPrint('[AcademicDropdowns] ✅ specializations loaded: ${_specializations.length} items');
      } else {
        debugPrint('[AcademicDropdowns] ❌ specializations FAILED [${sRes.statusCode}]: ${sRes.message}');
      }
    } catch (e) {
      debugPrint('[AcademicDropdowns] ❌ exception: $e');
    } finally {
      _isLoadingAcademic = false;
      notifyListeners();
    }
  }

  Future<void> pickIdImage({required bool isFront, required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        // Persist out of image_picker's cache dir — this form submits much
        // later (final review step), and Android can reclaim cache-dir
        // files under storage pressure in the meantime, causing a
        // PathNotFoundException at upload time.
        final persistedPath = await PickedFileUtils.persist(image.path);
        if (isFront) {
          _idFrontPath = persistedPath;
        } else {
          _idBackPath = persistedPath;
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
        final persistedPath = await PickedFileUtils.persist(image.path);
        _profilePicPath = persistedPath;
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
      // ── Field audit: log every field value before building payload ──────────
      bool _f(String? v) => v != null && v.trim().isNotEmpty;
      String _fv(String label, String? v) =>
          '  ${label.padRight(26)}: ${_f(v) ? "✓  $v" : "✗  MISSING / EMPTY"}';
      String _bv(String label, bool? v) =>
          '  ${label.padRight(26)}: ${v != null ? "✓  $v" : "✗  MISSING"}';
      String _iv(String label, int? v) =>
          '  ${label.padRight(26)}: ${v != null ? "✓  $v" : "✗  MISSING"}';
      String _filev(String label, String? newPath, bool serverHas) {
        if (newPath != null) return '  ${label.padRight(26)}: ✓  new file → $newPath';
        if (serverHas)       return '  ${label.padRight(26)}: ✓  already on server';
        return                      '  ${label.padRight(26)}: ✗  MISSING';
      }

      debugPrint('\n╔══════════════════════════════════════════════════════════╗');
      debugPrint('║            COMPLETE PROFILE — FIELD AUDIT               ║');
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║  PERSONAL INFO                                           ║');
      debugPrint(_fv('full_name',     fullName));
      debugPrint(_fv('email',         email));
      debugPrint(_fv('phone',         phone));
      debugPrint(_fv('date_of_birth', dateOfBirth));
      debugPrint(_iv('age',           age));
      debugPrint(_fv('address',       address));
      debugPrint(_fv('pincode',       pincode));
      debugPrint(_fv('district',      district));
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║  ID PROOF                                                ║');
      debugPrint(_filev('id_proof (front)', _idFrontPath, serverIdFront));
      debugPrint(_filev('id_proof (back)',  _idBackPath,  serverIdBack));
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║  ACADEMIC INFO                                           ║');
      debugPrint(_fv('qualification_id',   qualificationId));
      debugPrint('  qualification_name    : ${qualificationName ?? "—"}');
      debugPrint(_fv('college',            college));
      debugPrint(_fv('pass_out_year',      passOutYear));
      debugPrint(_fv('specialization',     specialization));
      debugPrint(_fv('cgpa',               cgpa));
      debugPrint(_bv('any_arrears',        anyArrears));
      debugPrint(_fv('admission_date',     admissionDate));
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║  CAREER INFO                                             ║');
      debugPrint(_fv('student_status',          studentStatus));
      debugPrint(_fv('preferred_job_location',  preferredJobLocation));
      debugPrint(_bv('placement_assistance',    placementAssistance));
      debugPrint(_filev('resume',          _resumePath,   serverResume));
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║  PARENT INFO                                             ║');
      debugPrint(_fv('parent_name',   parentName));
      debugPrint(_fv('parent_phone',  parentPhone));
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      debugPrint('║  FILES                                                   ║');
      debugPrint(_filev('profile_pic', _profilePicPath, serverProfilePic));
      debugPrint('╚══════════════════════════════════════════════════════════╝\n');
      // ─────────────────────────────────────────────────────────────────────

      final Map<String, dynamic> deltaFields = {};

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
      if (anyArrears != null) {
        deltaFields['any_arrears'] = anyArrears;
      }

      // Career
      addIfChanged(
        'student_or_working_professional',
        studentStatus,
        initialProfile?.academicInfo?.studentOrWorkingProfessional,
      );
      if (placementAssistance != null) {
        deltaFields['placement_assistance'] = placementAssistance;
      }
      addIfChanged('preferred_job_location', preferredJobLocation, initialProfile?.placementInfo?.preferredJobLocation);
      addIfChanged('linkedin_link', linkedinLink, initialProfile?.placementInfo?.linkedinLink);
      addIfChanged('portfolio_link', portfolioLink, initialProfile?.placementInfo?.portfolioLink);

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

      // ── Delta audit: what is being sent vs skipped ───────────────────────
      const _allKeys = [
        'full_name', 'email', 'phone', 'whatsapp_number', 'date_of_birth', 'age',
        'address', 'pincode', 'district',
        'qualification_id', 'college', 'pass_out_year', 'specialization', 'cgpa',
        'any_arrears', 'admission_date',
        'student_or_working_professional', 'preferred_job_location', 'placement_assistance',
        'linkedin_link', 'portfolio_link',
        'parent_name', 'parent_phone_number',
      ];
      debugPrint('\n╔══════════════════════════════════════════════════════════╗');
      debugPrint('║            PAYLOAD DELTA (sent vs skipped)              ║');
      debugPrint('╠══════════════════════════════════════════════════════════╣');
      for (final key in _allKeys) {
        if (deltaFields.containsKey(key)) {
          debugPrint('  ➤ SENDING  $key = ${deltaFields[key]} (${deltaFields[key].runtimeType})');
        } else {
          debugPrint('  — skipped  $key  (unchanged or null)');
        }
      }
      debugPrint('  id_proof        : ${_idFrontPath != null ? "➤ SENDING new file" : "— skipped"}');
      debugPrint('  id_proof_2      : ${_idBackPath  != null ? "➤ SENDING new file" : "— skipped"}');
      debugPrint('  profile_pic     : ${_profilePicPath != null ? "➤ SENDING new file" : "— skipped"}');
      debugPrint('  resume          : ${_resumePath != null ? "➤ SENDING new file" : "— skipped"}');
      debugPrint('╚══════════════════════════════════════════════════════════╝\n');
      // ─────────────────────────────────────────────────────────────────────

      final profileStudentId = initialProfile?.personalInfo?.studentId;

      if (profileStudentId == null || profileStudentId.trim().isEmpty) {
        throw Exception('Cannot submit profile: student ID is missing. Please restart the app and try again.');
      }

      if (deltaFields.isEmpty &&
          _idFrontPath == null &&
          _idBackPath == null &&
          _profilePicPath == null &&
          _resumePath == null) {
        debugPrint('[CompleteProfile] ⚠️  Nothing changed — skipping PATCH');
        _isSubmitting = false;
        notifyListeners();
        return;
      }

      final result = await _submissionService.submitProfile(
        student_id: profileStudentId.toString(),
        fields: deltaFields,
        idFrontPath: _idFrontPath,
        idBackPath: _idBackPath,
        profilePicPath: _profilePicPath,
        resumePath: _resumePath,
      );

      // ── Response audit ───────────────────────────────────────────────────
      if (result.success) {
        debugPrint('[CompleteProfile] ✅ PATCH success [${result.statusCode}]');
        debugPrint('[CompleteProfile] response: ${result.data}');
      } else {
        debugPrint('[CompleteProfile] ❌ PATCH FAILED [${result.statusCode}]: ${result.message}');
        debugPrint('[CompleteProfile] response data: ${result.data}');
        throw Exception(result.message ?? 'Profile update failed (${result.statusCode})');
      }
      // ─────────────────────────────────────────────────────────────────────
    } catch (e) {
      LoggerUtils.error('submitProfile error: $e', tag: 'CompleteProfile', error: e);
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

  List<ProfileFieldStatus> getFieldStatuses() {
    bool _f(String? v) => v != null && v.trim().isNotEmpty;
    return [
      // Personal Info (page 0)
      ProfileFieldStatus(name: 'Full Name', isFilled: _f(fullName), pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'Email', isFilled: _f(email), pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'Phone', isFilled: _f(phone), pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'Date of Birth', isFilled: _f(dateOfBirth), pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'Age', isFilled: age != null, pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'Address', isFilled: _f(address), pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'Pincode', isFilled: _f(pincode), pageIndex: 0, section: 'Personal Info'),
      ProfileFieldStatus(name: 'District', isFilled: _f(district), pageIndex: 0, section: 'Personal Info'),
      // ID Proof (page 1)
      ProfileFieldStatus(name: 'ID Proof (Front)', isFilled: _idFrontPath != null || serverIdFront, pageIndex: 1, section: 'ID Proof'),
      ProfileFieldStatus(name: 'ID Proof (Back)', isFilled: _idBackPath != null || serverIdBack, pageIndex: 1, section: 'ID Proof'),
      // Academic Info (page 2)
      ProfileFieldStatus(name: 'Qualification', isFilled: _f(qualificationId), pageIndex: 2, section: 'Academic Info'),
      ProfileFieldStatus(name: 'College / University', isFilled: _f(college), pageIndex: 2, section: 'Academic Info'),
      ProfileFieldStatus(name: 'Pass Out Year', isFilled: _f(passOutYear), pageIndex: 2, section: 'Academic Info'),
      ProfileFieldStatus(name: 'Specialization', isFilled: _f(specialization), pageIndex: 2, section: 'Academic Info'),
      ProfileFieldStatus(name: 'CGPA', isFilled: _f(cgpa), pageIndex: 2, section: 'Academic Info'),
      ProfileFieldStatus(name: 'Admission Date', isFilled: _f(admissionDate), pageIndex: 2, section: 'Academic Info'),
      // Career Info (page 3)
      ProfileFieldStatus(name: 'Current Status', isFilled: _f(studentStatus), pageIndex: 3, section: 'Career Info'),
      // Parent Info (page 4)
      ProfileFieldStatus(name: 'Parent / Guardian Name', isFilled: _f(parentName), pageIndex: 4, section: 'Parent Info'),
      ProfileFieldStatus(name: 'Parent / Guardian Phone', isFilled: _f(parentPhone), pageIndex: 4, section: 'Parent Info'),
    ];
  }
}
