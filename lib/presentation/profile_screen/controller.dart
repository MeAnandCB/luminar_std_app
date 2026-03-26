import 'package:flutter/material.dart';

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
      final fetchedData = await ProfileScreenService().GetProfileData(
        context: context,
      );

      // Check if fetchedData is ProfileModel (not DashBoardModel)
      if (fetchedData is ProfileModel) {
        profileModel = fetchedData;
        profile =
            fetchedData.profile; // Make sure ProfileModel has a profile field

        if (profile != null) {
          print('✅ Profile data loaded successfully');
          _error = null;
        } else {
          print('⚠️ Profile data is null in response');
          _error = 'No profile data available';
        }
      } else {
        print('❌ Invalid response format: $fetchedData');
        _error = 'Invalid response format';
        profile = null;
        profileModel = null;
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      _error = e.toString();
      profile = null;
      profileModel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('📊 Loading state: $_isLoading, Error: $_error');
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
      print('❌ Error fetching district: $e');
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
  int get totalFields => 21;

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
    if (p.personalInfo?.profilePicture?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.idProof?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.idProof2?.isNotEmpty ?? false) count++;
    if (p.personalInfo?.resume != null) count++;
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

  // Clear profile data (useful for logout)
  void clearProfileData() {
    profile = null;
    profileModel = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
