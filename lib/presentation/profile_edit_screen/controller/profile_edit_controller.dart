import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/repository/complete_profile/service.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ProfileEditController extends ChangeNotifier {
  final CompleteProfileService _submissionService = CompleteProfileService();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  final ImagePicker _picker = ImagePicker();
  String? _profilePicPath;
  String? get profilePicPath => _profilePicPath;

  String? _resumePath;
  String? get resumePath => _resumePath;

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

  int? _qualificationId;
  int? _preferredLocationId;

  // Country codes — stored separately from the digit-only controllers
  String _phoneCountryCode = '+91';
  String get phoneCountryCode => _phoneCountryCode;
  set phoneCountryCode(String v) { _phoneCountryCode = v; notifyListeners(); }

  String _whatsappCountryCode = '+91';
  String get whatsappCountryCode => _whatsappCountryCode;
  set whatsappCountryCode(String v) { _whatsappCountryCode = v; notifyListeners(); }

  String _parentPhoneCountryCode = '+91';
  String get parentPhoneCountryCode => _parentPhoneCountryCode;
  set parentPhoneCountryCode(String v) { _parentPhoneCountryCode = v; notifyListeners(); }

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
    _splitPhone(p?.phone ?? '', (code, digits) {
      _phoneCountryCode = code;
      phoneController.text = digits;
    });
    _splitPhone(p?.whatsappNumber ?? '', (code, digits) {
      _whatsappCountryCode = code;
      whatsappController.text = digits;
    });
    _selectedDob = p?.dateOfBirth;
    dobController.text = _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : '';
    ageController.text = p?.age?.toString() ?? '';

    // Academic Info
    _qualificationId = a?.qualification?.id;
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
    _preferredLocationId = c?.preferredLocation?.id;
    preferredLocationController.text = c?.preferredLocation?.name ?? '';
    parentNameController.text = c?.parentName ?? '';
    _splitPhone(c?.parentPhone ?? '', (code, digits) {
      _parentPhoneCountryCode = code;
      parentPhoneController.text = digits;
    });
    hearAboutController.text = c?.howDidYouHear ?? '';

    // Placement Info
    _placementAssistance = pl?.placementAssistance ?? true;
    preferredJobLocationController.text = pl?.preferredJobLocation ?? '';

    if (notify) notifyListeners();
  }

  /// Splits a stored phone string like "+918943382754" into ("+91", "8943382754").
  /// Matches against known valid dial codes sorted longest-first so that
  /// "+1684" (American Samoa, 4 chars) is tried before "+1" (USA),
  /// and "+91" (India, 2 chars) wins over the non-existent "+918".
  void _splitPhone(String raw, void Function(String code, String digits) out) {
    final s = raw.trim();
    if (!s.startsWith('+') || s.length < 2) {
      out('+91', s);
      return;
    }

    // Sorted longest-first to prevent prefix collisions
    const _knownCodes = [
      // ── NANP (+1 + 3-digit area) ──────────────────────────────────────────
      '+1684','+1264','+1268','+1242','+1246','+1441','+1284','+1345',
      '+1767','+1809','+1829','+1849','+1473','+1671','+1876','+1664',
      '+1670','+1787','+1939','+1758','+1784','+1869','+1868','+1649','+1340',
      // ── 3-digit codes ─────────────────────────────────────────────────────
      '+213','+376','+244','+374','+994','+973','+880','+375','+229',
      '+975','+387','+267','+246','+673','+359','+226','+257','+855',
      '+237','+238','+236','+235','+269','+242','+243','+682','+506',
      '+385','+357','+253','+240','+291','+372','+251','+679','+358',
      '+241','+220','+995','+233','+299','+502','+224','+245','+509',
      '+852','+354','+964','+353','+225','+962','+254','+686','+850',
      '+965','+996','+856','+371','+961','+266','+231','+218','+423',
      '+370','+352','+853','+389','+960','+223','+356','+692','+222',
      '+230','+976','+382','+505','+227','+234','+683','+968','+680',
      '+970','+507','+675','+595','+598','+998','+678','+677','+232',
      '+421','+386','+249','+597','+268','+963','+886','+992','+255',
      '+670','+228','+690','+676','+216','+993','+688','+256','+971',
      '+260','+263','+591','+261','+265','+212','+258','+264','+674',
      '+977','+380','+381','+385',
      // ── 2-digit codes ─────────────────────────────────────────────────────
      '+20','+27','+30','+31','+32','+33','+34','+36','+39',
      '+40','+41','+43','+44','+45','+46','+47','+48','+49',
      '+51','+52','+53','+54','+55','+56','+57','+58','+60',
      '+61','+62','+63','+64','+65','+66','+81','+82','+84',
      '+86','+90','+91','+92','+93','+94','+95','+98',
      // ── 1-digit codes ─────────────────────────────────────────────────────
      '+1','+7',
    ];

    for (final code in _knownCodes) {
      if (s.startsWith(code)) {
        out(code, s.substring(code.length));
        return;
      }
    }

    // Last-resort fallback — take up to 3 digits after '+'
    final m = RegExp(r'^\+(\d{1,3})(.*)').firstMatch(s);
    if (m != null) {
      out('+${m.group(1)!}', m.group(2)!);
    } else {
      out('+91', s);
    }
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

  Future<void> pickResume() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        _resumePath = result.files.single.path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking resume: $e');
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

      // Phone fields — join country code + digits, compare against stored full number
      final fullPhone    = '$_phoneCountryCode${phoneController.text.trim()}';
      final fullWhatsapp = '$_whatsappCountryCode${whatsappController.text.trim()}';
      addIfChanged('phone',          fullPhone.length > _phoneCountryCode.length    ? fullPhone    : null, p?.phone);
      addIfChanged('whatsapp_number', fullWhatsapp.length > _whatsappCountryCode.length ? fullWhatsapp : null, p?.whatsappNumber);
      addIfChanged(
        'date_of_birth',
        dobController.text,
        p?.dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(p!.dateOfBirth!) : null,
      );
      addIfChanged('age', int.tryParse(ageController.text), p?.age);

      addIfChanged('qualification_id', _qualificationId, a?.qualification?.id);
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
      addIfChanged('preferred_location_id', _preferredLocationId, c?.preferredLocation?.id);
      addIfChanged('parent_name', parentNameController.text, c?.parentName);
      final fullParentPhone = '$_parentPhoneCountryCode${parentPhoneController.text.trim()}';
      addIfChanged('parent_phone_number', fullParentPhone.length > _parentPhoneCountryCode.length ? fullParentPhone : null, c?.parentPhone);
      addIfChanged('how_did_you_hear', hearAboutController.text, c?.howDidYouHear);

      addIfChanged('placement_assistance', _placementAssistance, pl?.placementAssistance);
      addIfChanged('preferred_job_location', preferredJobLocationController.text, pl?.preferredJobLocation);

      if (deltaFields.isEmpty && _profilePicPath == null && _resumePath == null) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      }

      developer.log(
        '\n'
        '╔══════════════════════════════════════════════════════════╗\n'
        '║             📤  EDIT PROFILE PAYLOAD                    ║\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  endpoint : ${AppEndpoints.profileUpdate}${p?.studentId}/update/\n'
        '║  method   : PATCH (multipart)\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  DELTA FIELDS (${deltaFields.length} changed)${deltaFields.isEmpty ? ' — none' : ''}\n'
        '${deltaFields.entries.map((e) => '║    ${e.key.padRight(22)}: ${e.value}  (${e.value.runtimeType})').join('\n')}\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  FILES\n'
        '║    profile_pic : ${_profilePicPath ?? '(unchanged)'}\n'
        '║    resume      : ${_resumePath ?? '(unchanged)'}\n'
        '╚══════════════════════════════════════════════════════════╝',
        name: '📤 Profile.EditPayload',
      );

      final result = await _submissionService.submitProfile(
        student_id: p?.studentId.toString(),
        fields: deltaFields,
        profilePicPath: _profilePicPath,
        resumePath: _resumePath,
      );

      if (!result.success) {
        _error = result.message ?? 'Failed to update profile.';
        return false;
      }

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
