class ReferredStudentsModel {
  String? status;
  String? message;
  int? count;
  int? page;
  int? pageSize;
  List<ReferredStudent>? results;

  ReferredStudentsModel({
    this.status,
    this.message,
    this.count,
    this.page,
    this.pageSize,
    this.results,
  });

  factory ReferredStudentsModel.fromJson(Map<String, dynamic> json) {
    return ReferredStudentsModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
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

class ReferredStudent {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? status;
  String? statusColorHex;
  String? courseName;
  String? qualificationName;
  DateTime? createdAt;

  ReferredStudent({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.status,
    this.statusColorHex,
    this.courseName,
    this.qualificationName,
    this.createdAt,
  });

  factory ReferredStudent.fromJson(Map<dynamic, dynamic> json) {
    String? parsedStatus = json['status']?.toString();
    String? parsedColor;

    if (json['lead_status_details'] is Map) {
      final details = json['lead_status_details'] as Map;
      parsedStatus = details['name']?.toString() ?? parsedStatus;
      parsedColor = details['color']?.toString();
    }

    String? parsedCourse = json['course_name']?.toString() ?? json['course']?.toString();
    if (json['course_details'] is Map) {
      parsedCourse = json['course_details']['name']?.toString() ?? parsedCourse;
    }

    String? parsedQual = json['qualification_name']?.toString() ?? json['qualification']?.toString();
    if (json['qualification_details'] is Map) {
      parsedQual = json['qualification_details']['name']?.toString() ?? parsedQual;
    }

    return ReferredStudent(
      id: json['id']?.toString() ?? json['uid']?.toString(),
      name: json['name']?.toString() ?? json['full_name']?.toString(),
      phone: json['phone_number']?.toString() ?? json['phone']?.toString(),
      email: json['email']?.toString(),
      status: parsedStatus,
      statusColorHex: parsedColor,
      courseName: parsedCourse,
      qualificationName: parsedQual,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
