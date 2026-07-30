import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class NactetRegistrationModel {
  String? enrollment;
  String? branch;
  String? name;
  String? guardianName;
  String? gender;
  String? dateOfBirth;
  String? permanentAddress;
  String? mobileNumber;
  String? email;
  String? basicEducationalQualification;
  int? basicEducationalQualificationYearOfPassing;
  String? higherEducationalQualification;
  int? higherEducationalQualificationYearOfPassing;
  String? basicDocPath;
  String? higherDocPath;
  String? idProofPath;
  String? photoPath;
  // The picker's cache copy of a document isn't guaranteed to survive until
  // submit — this is a multi-step wizard, and Android can evict the
  // file_picker cache folder in the meantime (low storage, OS cleanup, the
  // plugin purging old sessions). Bytes are captured immediately on pick so
  // submit never has to re-read a path that may no longer exist.
  Uint8List? basicDocBytes;
  Uint8List? higherDocBytes;
  Uint8List? idProofBytes;
  Uint8List? photoBytes;
  int? course;
  String? batch;

  NactetRegistrationModel({
    this.enrollment,
    this.branch,
    this.name,
    this.guardianName,
    this.gender,
    this.dateOfBirth,
    this.permanentAddress,
    this.mobileNumber,
    this.email,
    this.basicEducationalQualification,
    this.basicEducationalQualificationYearOfPassing,
    this.higherEducationalQualification,
    this.higherEducationalQualificationYearOfPassing,
    this.basicDocPath,
    this.higherDocPath,
    this.idProofPath,
    this.photoPath,
    this.course,
    this.batch,
  });

  Map<String, String> toFields() {
    return {
      if (enrollment != null) 'enrollment_uid': enrollment!,
      if (branch != null) 'branch_id': branch!,
      if (name != null) 'name': name!,
      if (guardianName != null) 'guardian_name': guardianName!,
      if (gender != null) 'gender': gender!,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth!,
      if (permanentAddress != null) 'permanent_address': permanentAddress!,
      if (mobileNumber != null) 'mobile_number': mobileNumber!,
      if (email != null) 'email': email!,
      if (basicEducationalQualification != null)
        'basic_educational_qualification': basicEducationalQualification!,
      if (basicEducationalQualificationYearOfPassing != null)
        'basic_educational_qualification_year_of_passing':
            basicEducationalQualificationYearOfPassing!.toString(),
      if (higherEducationalQualification != null)
        'higher_educational_qualification': higherEducationalQualification!,
      if (higherEducationalQualificationYearOfPassing != null)
        'higher_educational_qualification_year_of_passing':
            higherEducationalQualificationYearOfPassing!.toString(),
      if (course != null) 'course_id': course!.toString(),
      if (batch != null) 'batch_uid': batch!,
    };
  }

  Future<List<http.MultipartFile>> toFiles() async {
    final List<http.MultipartFile> files = [];

    if (basicDocPath != null && basicDocBytes != null) {
      files.add(_createMultipartFile(
          'basic_educational_qualification_document', basicDocPath!, basicDocBytes!));
    }
    if (higherDocPath != null && higherDocBytes != null) {
      files.add(_createMultipartFile(
          'higher_educational_qualification_document', higherDocPath!, higherDocBytes!));
    }
    if (idProofPath != null && idProofBytes != null) {
      files.add(_createMultipartFile('id_proof_document', idProofPath!, idProofBytes!));
    }
    if (photoPath != null && photoBytes != null) {
      files.add(_createMultipartFile('passport_size_photo', photoPath!, photoBytes!));
    }

    return files;
  }

  http.MultipartFile _createMultipartFile(
      String fieldName, String filePath, Uint8List bytes) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    MediaType contentType;

    if (extension == 'pdf') {
      contentType = MediaType('application', 'pdf');
    } else if (extension == 'png') {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('image', 'jpeg');
    }

    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: path.basename(filePath),
      contentType: contentType,
    );
  }
}
