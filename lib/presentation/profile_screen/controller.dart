import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart';
import 'package:luminar_std/repository/profile_screen/service/profile_screen_service.dart';
import 'package:luminar_std/repository/pincode/service.dart';

class ProfileController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Profile? profile;
  ProfileModel? profileModel;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Profile? get profileData => profile;
  ProfileModel? get profileModelData => profileModel;
  bool _isPincodeLoading = false;
  bool get isPincodeLoading => _isPincodeLoading;

  Future<Profile?> getProfileData({required BuildContext context}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ProfileScreenService().getProfileData();

      if (response.success && response.data != null) {
        profileModel = response.data;
        profile = profileModel?.profile;

        if (profile != null) {
          _error = null;
          _logProfileResponse(profile!);
        } else {
          _error = 'No profile data available';
        }
      } else {
        _error = response.message;
        if (response.statusCode == 401) {
          await AppUtils.clearUserSession();
          if (context.mounted) AppUtils.navigateToLogin(context);
        }
      }
    } catch (e) {
      _error = e.toString();
      profile = null;
      profileModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return profile;
  }

  Future<String?> getDistrictFromPincode(String pincode) async {
    _isPincodeLoading = true;
    notifyListeners();

    try {
      final response =
          await PincodeService().getPincodeData(pincode);
      if (response.success && response.data != null) {
        final postOffices = response.data!.data.postOffices;
        if (postOffices.isNotEmpty) {
          return postOffices.first.district;
        }
      }
    } catch (e) {
      LoggerUtils.error('❌ Error fetching district: $e', tag: 'Profile');
    } finally {
      _isPincodeLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Convenience method to refresh profile data
  Future<void> refreshProfile({required BuildContext context}) async {
    await getProfileData(context: context);
  }

  // Metrics calculation
  int get totalFields => 19;

  int get filledFieldsCount {
    if (profile == null) return 0;
    int count = 0;
    final p = profile!;

    // Personal / Contact
    if (p.personalInfo?.fullName?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.email?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.phone?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.dateOfBirth != null) count++;
    if (p.personalInfo?.age != null) count++;
    if (p.personalInfo?.idProof?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.idProof2?.isNotEmpty ?? false) count++;
    if (p.contactInfo?.address?.isNotEmpty ?? false) count++;
    if (p.contactInfo?.pincode?.isNotEmpty ?? false) count++;
    if (p.contactInfo?.district?.isNotEmpty ?? false) count++;

    // Academic
    if (p.academicInfo?.qualification?.name?.isNotEmpty ?? false) count++;
    if (p.academicInfo?.college?.isNotEmpty ?? false) count++;
    if (p.academicInfo?.passOutYear != null) count++;
    if (p.academicInfo?.specialization?.isNotEmpty ?? false) count++;
    if (p.academicInfo?.cgpa != null) count++;
    if (p.academicInfo?.admissionDate != null) count++;
    if (p.academicInfo?.studentOrWorkingProfessional?.isNotEmpty ?? false) count++;

    // Parent
    if (p.contactInfo?.parentName?.isNotEmpty ?? false) count++;
    if (p.contactInfo?.parentPhone?.isNotEmpty ?? false) count++;

    return count > totalFields ? totalFields : count;
  }

  int get remainingFieldsCount => totalFields - filledFieldsCount;
  double get completionPercentage => filledFieldsCount / totalFields;

  void _logProfileResponse(Profile p) {
    final pi = p.personalInfo;
    final ai = p.academicInfo;
    final ci = p.contactInfo;
    final si = p.statusInfo;
    final pl = p.placementInfo;
    final co = p.counselor;

    developer.log(
      '\n'
      '╔══════════════════════════════════════════════════════════╗\n'
      '║              📥  PROFILE RESPONSE RECEIVED              ║\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  PERSONAL INFO                                          ║\n'
      '║    student_id       : ${pi?.studentId ?? 'null'}\n'
      '║    full_name        : ${pi?.fullName ?? 'null'}\n'
      '║    email            : ${pi?.email ?? 'null'}\n'
      '║    phone            : ${pi?.phone ?? 'null'}\n'
      '║    whatsapp_number  : ${pi?.whatsappNumber ?? 'null'}\n'
      '║    date_of_birth    : ${pi?.dateOfBirth ?? 'null'}\n'
      '║    age              : ${pi?.age ?? 'null'}\n'
      '║    profile_picture  : ${pi?.profilePicture != null ? '(set)' : 'null'}\n'
      '║    id_proof         : ${pi?.idProof != null ? '(set)' : 'null'}\n'
      '║    id_proof_2       : ${pi?.idProof2 != null ? '(set)' : 'null'}\n'
      '║    resume           : ${pi?.resume != null ? '(set)' : 'null'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  ACADEMIC INFO                                          ║\n'
      '║    qualification_id : ${ai?.qualification?.id ?? 'null'}\n'
      '║    qualification    : ${ai?.qualification?.name ?? 'null'}\n'
      '║    college          : ${ai?.college ?? 'null'}\n'
      '║    pass_out_year    : ${ai?.passOutYear ?? 'null'}\n'
      '║    specialization   : ${ai?.specialization ?? 'null'}\n'
      '║    cgpa             : ${ai?.cgpa ?? 'null'}\n'
      '║    admission_date   : ${ai?.admissionDate ?? 'null'}\n'
      '║    any_arrears      : ${ai?.anyArrears ?? 'null'}\n'
      '║    student_type     : ${ai?.studentOrWorkingProfessional ?? 'null'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  CONTACT INFO                                           ║\n'
      '║    address          : ${ci?.address ?? 'null'}\n'
      '║    district         : ${ci?.district ?? 'null'}\n'
      '║    pincode          : ${ci?.pincode ?? 'null'}\n'
      '║    preferred_loc_id : ${ci?.preferredLocation?.id ?? 'null'}\n'
      '║    preferred_loc    : ${ci?.preferredLocation?.name ?? 'null'}\n'
      '║    parent_name      : ${ci?.parentName ?? 'null'}\n'
      '║    parent_phone     : ${ci?.parentPhone ?? 'null'}\n'
      '║    how_did_you_hear : ${ci?.howDidYouHear ?? 'null'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  STATUS INFO                                            ║\n'
      '║    status           : ${si?.status?.name ?? 'null'}\n'
      '║    is_alumni        : ${si?.isAlumni ?? 'null'}\n'
      '║    is_placed        : ${si?.isPlaced ?? 'null'}\n'
      '║    portal_access    : ${si?.portalAccessEnabled ?? 'null'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  PLACEMENT INFO                                         ║\n'
      '║    placement_assist : ${pl?.placementAssistance ?? 'null'}\n'
      '║    pref_job_location: ${pl?.preferredJobLocation ?? 'null'}\n'
      '╠══════════════════════════════════════════════════════════╣\n'
      '║  COUNSELOR                                              ║\n'
      '║    name             : ${co?.name ?? 'null'}\n'
      '║    email            : ${co?.email ?? 'null'}\n'
      '╚══════════════════════════════════════════════════════════╝',
      name: '📥 Profile.Response',
    );
  }

  // Clear profile data (useful for logout)
  void clearProfileData() {
    profile = null;
    profileModel = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
