import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:luminar_std/repository/live_class/model/live_class_model.dart';
import 'package:luminar_std/repository/live_class/service/live_class_service.dart';

class LiveClassController extends ChangeNotifier {
  List<LiveClassRes>? liveClassResModel;
  ClassLink? classLinkData;

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool _islinkLoading = false;

  bool get islinkLoading => _isLoading;

  //get live class details
  Future<void> getLiveClassDetails() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await LiveClassService().getLiveClassDetails();

      if (response.success) {
        LiveClassResModel resModel = response.data;
        liveClassResModel = resModel.liveClassResModel;
      } else {
        // Handle error case if needed
      }
    } catch (e) {
      print(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //classlinkLoading

  Future<void> getLiveClassLinkDetails({required String id}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await LiveClassService().getLivelink(id: id);

      if (response.success) {
        ClasslinkResModel resModel = response.data;
        classLinkData = resModel.classLinkData;
      } else {
        // Handle error case if needed
      }
    } catch (e) {
      print(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
