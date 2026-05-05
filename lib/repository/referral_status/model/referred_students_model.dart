class ReferredStudentsModel {
  String? status;
  String? message;
  ReferrerInfo? referrer;
  int? count;
  int? page;
  int? pageSize;
  List<ReferredStudent>? results;

  ReferredStudentsModel({
    this.status,
    this.message,
    this.referrer,
    this.count,
    this.page,
    this.pageSize,
    this.results,
  });

  factory ReferredStudentsModel.fromJson(Map<String, dynamic> json) {
    return ReferredStudentsModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      referrer: json['referrer'] is Map
          ? ReferrerInfo.fromJson(json['referrer'])
          : null,
      count: int.tryParse(json['count']?.toString() ?? '0'),
      page: int.tryParse(json['page']?.toString() ?? '0'),
      pageSize: int.tryParse(json['page_size']?.toString() ?? '0'),
      results: json['results'] is List
          ? (json['results'] as List)
              .map((i) => ReferredStudent.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class ReferrerInfo {
  String? studentProfileId;
  String? studentId;
  String? fullName;
  String? userUid;

  ReferrerInfo({
    this.studentProfileId,
    this.studentId,
    this.fullName,
    this.userUid,
  });

  factory ReferrerInfo.fromJson(Map<dynamic, dynamic> json) {
    return ReferrerInfo(
      studentProfileId: json['student_profile_id']?.toString(),
      studentId: json['student_id']?.toString(),
      fullName: json['full_name']?.toString(),
      userUid: json['user_uid']?.toString(),
    );
  }
}

class ReferredStudent {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? status;
  String? courseName;
  String? qualificationName;
  DateTime? createdAt;

  ReferredStudent({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.status,
    this.courseName,
    this.qualificationName,
    this.createdAt,
  });

  factory ReferredStudent.fromJson(Map<dynamic, dynamic> json) {
    return ReferredStudent(
      id: json['student_id']?.toString() ?? json['id']?.toString() ?? json['uid']?.toString() ?? json['user_uid']?.toString(),
      name: json['name']?.toString() ?? json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString(),
      courseName: json['course_name']?.toString() ?? json['course']?.toString(),
      qualificationName: json['qualification_name']?.toString() ?? json['qualification']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
