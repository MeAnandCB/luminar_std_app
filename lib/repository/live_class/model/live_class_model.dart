class LiveClassResModel {
  String? status;
  List<LiveClassRes>? liveClassResModel;

  LiveClassResModel({this.status, this.liveClassResModel});

  factory LiveClassResModel.fromJson(Map<String, dynamic> json) =>
      LiveClassResModel(
        status: json["status"],
        liveClassResModel: json["enrollments"] == null
            ? []
            : List<LiveClassRes>.from(
                json["enrollments"]!.map((x) => LiveClassRes.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "enrollments": liveClassResModel == null
        ? []
        : List<dynamic>.from(liveClassResModel!.map((x) => x.toJson())),
  };
}

class LiveClassRes {
  bool? crmAccess;
  String? uid;
  String? batchName;
  String? enrollmentStatus;

  LiveClassRes({
    this.crmAccess,
    this.uid,
    this.batchName,
    this.enrollmentStatus,
  });

  factory LiveClassRes.fromJson(Map<String, dynamic> json) => LiveClassRes(
    crmAccess: json["crm_access"],
    uid: json["uid"],
    batchName: json["batch_name"],
    enrollmentStatus: json["enrollment_status"],
  );

  Map<String, dynamic> toJson() => {
    "crm_access": crmAccess,
    "uid": uid,
    "batch_name": batchName,
    "enrollment_status": enrollmentStatus,
  };
}

// class link model here

class ClasslinkResModel {
  String? status;
  ClassLink? classLinkData;

  ClasslinkResModel({this.status, this.classLinkData});

  factory ClasslinkResModel.fromJson(Map<String, dynamic> json) =>
      ClasslinkResModel(
        status: json["status"],
        classLinkData: json["data"] == null
            ? null
            : ClassLink.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": classLinkData?.toJson(),
  };
}

class ClassLink {
  String? joinUrl;

  ClassLink({this.joinUrl});

  factory ClassLink.fromJson(Map<String, dynamic> json) =>
      ClassLink(joinUrl: json["join_url"]);

  Map<String, dynamic> toJson() => {"join_url": joinUrl};
}
