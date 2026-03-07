class ProfileModel {
  String? status;
  Profile? profile;

  ProfileModel({this.status, this.profile});

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    status: json["status"],
    profile: json["profile"] == null ? null : Profile.fromJson(json["profile"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "profile": profile?.toJson(),
  };
}

class Profile {
  PersonalInfo? personalInfo;
  AcademicInfo? academicInfo;
  ContactInfo? contactInfo;
  StatusInfo? statusInfo;
  PlacementInfo? placementInfo;
  Counselor? counselor;

  Profile({
    this.personalInfo,
    this.academicInfo,
    this.contactInfo,
    this.statusInfo,
    this.placementInfo,
    this.counselor,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    personalInfo: json["personal_info"] == null
        ? null
        : PersonalInfo.fromJson(json["personal_info"]),
    academicInfo: json["academic_info"] == null
        ? null
        : AcademicInfo.fromJson(json["academic_info"]),
    contactInfo: json["contact_info"] == null
        ? null
        : ContactInfo.fromJson(json["contact_info"]),
    statusInfo: json["status_info"] == null
        ? null
        : StatusInfo.fromJson(json["status_info"]),
    placementInfo: json["placement_info"] == null
        ? null
        : PlacementInfo.fromJson(json["placement_info"]),
    counselor: json["counselor"] == null
        ? null
        : Counselor.fromJson(json["counselor"]),
  );

  Map<String, dynamic> toJson() => {
    "personal_info": personalInfo?.toJson(),
    "academic_info": academicInfo?.toJson(),
    "contact_info": contactInfo?.toJson(),
    "status_info": statusInfo?.toJson(),
    "placement_info": placementInfo?.toJson(),
    "counselor": counselor?.toJson(),
  };
}

class AcademicInfo {
  Qualification? qualification;
  String? college;
  int? passOutYear;
  String? specialization;
  DateTime? admissionDate;
  double? cgpa;
  bool? anyArrears;
  String? studentOrWorkingProfessional;

  AcademicInfo({
    this.qualification,
    this.college,
    this.passOutYear,
    this.specialization,
    this.admissionDate,
    this.cgpa,
    this.anyArrears,
    this.studentOrWorkingProfessional,
  });

  factory AcademicInfo.fromJson(Map<String, dynamic> json) => AcademicInfo(
    qualification: json["qualification"] == null
        ? null
        : Qualification.fromJson(json["qualification"]),
    college: json["college"],
    passOutYear: json["pass_out_year"],
    specialization: json["specialization"],
    admissionDate: json["admission_date"] == null
        ? null
        : DateTime.parse(json["admission_date"]),
    cgpa: json["cgpa"],
    anyArrears: json["any_arrears"],
    studentOrWorkingProfessional: json["student_or_working_professional"],
  );

  Map<String, dynamic> toJson() => {
    "qualification": qualification?.toJson(),
    "college": college,
    "pass_out_year": passOutYear,
    "specialization": specialization,
    "admission_date":
        "${admissionDate!.year.toString().padLeft(4, '0')}-${admissionDate!.month.toString().padLeft(2, '0')}-${admissionDate!.day.toString().padLeft(2, '0')}",
    "cgpa": cgpa,
    "any_arrears": anyArrears,
    "student_or_working_professional": studentOrWorkingProfessional,
  };
}

class Qualification {
  String? name;
  int? id;

  Qualification({this.name, this.id});

  factory Qualification.fromJson(Map<String, dynamic> json) =>
      Qualification(name: json["name"], id: json["id"]);

  Map<String, dynamic> toJson() => {"name": name, "id": id};
}

class ContactInfo {
  PreferredLocation? preferredLocation;
  String? parentName;
  String? parentPhone;
  String? howDidYouHear;
  String? address;
  String? pincode;
  String? district;

  ContactInfo({
    this.preferredLocation,
    this.parentName,
    this.parentPhone,
    this.howDidYouHear,
    this.address,
    this.pincode,
    this.district,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
    preferredLocation: json["preferred_location"] == null
        ? null
        : PreferredLocation.fromJson(json["preferred_location"]),
    parentName: json["parent_name"],
    parentPhone: json["parent_phone"],
    howDidYouHear: json["how_did_you_hear"],
    address: json["address"],
    pincode: json["pincode"],
    district: json["district"],
  );

  Map<String, dynamic> toJson() => {
    "preferred_location": preferredLocation?.toJson(),
    "parent_name": parentName,
    "parent_phone": parentPhone,
    "how_did_you_hear": howDidYouHear,
    "address": address,
    "pincode": pincode,
    "district": district,
  };
}

class PreferredLocation {
  String? name;

  PreferredLocation({this.name});

  factory PreferredLocation.fromJson(Map<String, dynamic> json) =>
      PreferredLocation(name: json["name"]);

  Map<String, dynamic> toJson() => {"name": name};
}

class Counselor {
  String? name;
  String? email;
  String? phone;

  Counselor({this.name, this.email, this.phone});

  factory Counselor.fromJson(Map<String, dynamic> json) =>
      Counselor(name: json["name"], email: json["email"], phone: json["phone"]);

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "phone": phone,
  };
}

class PersonalInfo {
  String? studentId;
  String? fullName;
  String? email;
  String? phone;
  String? whatsappNumber;
  DateTime? dateOfBirth;
  int? age;
  String? idProof;
  String? idProof2;
  dynamic resume;
  String? profilePicture;

  PersonalInfo({
    this.studentId,
    this.fullName,
    this.email,
    this.phone,
    this.whatsappNumber,
    this.dateOfBirth,
    this.age,
    this.idProof,
    this.idProof2,
    this.resume,
    this.profilePicture,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
    studentId: json["student_id"],
    fullName: json["full_name"],
    email: json["email"],
    phone: json["phone"],
    whatsappNumber: json["whatsapp_number"],
    dateOfBirth: json["date_of_birth"] == null
        ? null
        : DateTime.parse(json["date_of_birth"]),
    age: json["age"],
    idProof: json["id_proof"],
    idProof2: json["id_proof_2"],
    resume: json["resume"],
    profilePicture: json["profile_picture"],
  );

  Map<String, dynamic> toJson() => {
    "student_id": studentId,
    "full_name": fullName,
    "email": email,
    "phone": phone,
    "whatsapp_number": whatsappNumber,
    "date_of_birth":
        "${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}",
    "age": age,
    "id_proof": idProof,
    "id_proof_2": idProof2,
    "resume": resume,
    "profile_picture": profilePicture,
  };
}

class PlacementInfo {
  bool? placementAssistance;
  String? preferredJobLocation;

  PlacementInfo({this.placementAssistance, this.preferredJobLocation});

  factory PlacementInfo.fromJson(Map<String, dynamic> json) => PlacementInfo(
    placementAssistance: json["placement_assistance"],
    preferredJobLocation: json["preferred_job_location"],
  );

  Map<String, dynamic> toJson() => {
    "placement_assistance": placementAssistance,
    "preferred_job_location": preferredJobLocation,
  };
}

class StatusInfo {
  Status? status;
  bool? isAlumni;
  bool? isPlaced;
  bool? portalAccessEnabled;

  StatusInfo({
    this.status,
    this.isAlumni,
    this.isPlaced,
    this.portalAccessEnabled,
  });

  factory StatusInfo.fromJson(Map<String, dynamic> json) => StatusInfo(
    status: json["status"] == null ? null : Status.fromJson(json["status"]),
    isAlumni: json["is_alumni"],
    isPlaced: json["is_placed"],
    portalAccessEnabled: json["portal_access_enabled"],
  );

  Map<String, dynamic> toJson() => {
    "status": status?.toJson(),
    "is_alumni": isAlumni,
    "is_placed": isPlaced,
    "portal_access_enabled": portalAccessEnabled,
  };
}

class Status {
  String? name;
  String? value;
  String? color;

  Status({this.name, this.value, this.color});

  factory Status.fromJson(Map<String, dynamic> json) =>
      Status(name: json["name"], value: json["value"], color: json["color"]);

  Map<String, dynamic> toJson() => {
    "name": name,
    "value": value,
    "color": color,
  };
}
