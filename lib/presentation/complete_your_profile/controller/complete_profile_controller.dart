import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luminar_std/repository/academic_info/model.dart';
import 'package:luminar_std/repository/academic_info/service.dart';

class CompleteProfileController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final AcademicInfoService _academicService = AcademicInfoService();

  Uint8List? _idFrontImage;
  Uint8List? _idBackImage;

  Uint8List? get idFrontImage => _idFrontImage;
  Uint8List? get idBackImage => _idBackImage;

  List<Qualification> _qualifications = [];
  List<Specialization> _specializations = [];
  bool _isLoadingAcademic = false;

  List<Qualification> get qualifications => _qualifications;
  List<Specialization> get specializations => _specializations;
  bool get isLoadingAcademic => _isLoadingAcademic;

  String? selectedQualification;
  String? selectedSpecialization;

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
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Optimize image size
      );

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
      debugPrint('Error picking image: $e');
    }
  }

  void clearImages() {
    _idFrontImage = null;
    _idBackImage = null;
    notifyListeners();
  }
}
