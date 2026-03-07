import 'package:flutter/material.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';
import 'package:luminar_std/repository/home_screen/service.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart';
import 'package:luminar_std/repository/profile_screen/service/profile_screen_service.dart';

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

  // Convenience method to refresh profile data
  Future<void> refreshProfile({required BuildContext context}) async {
    await getProfileData(context: context);
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
