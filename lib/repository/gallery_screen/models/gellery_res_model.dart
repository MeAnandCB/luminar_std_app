import 'dart:convert';

GalleryResModel galleryResModelFromJson(String str) => GalleryResModel.fromJson(json.decode(str));

String galleryResModelToJson(GalleryResModel data) => json.encode(data.toJson());

class GalleryResModel {
  String status;
  int count;
  dynamic next;
  dynamic previous;
  int pageSize;
  int currentPage;
  int totalPages;
  List<Gallery> galleries;
  Summary summary;

  GalleryResModel({
    required this.status,
    required this.count,
    required this.next,
    required this.previous,
    required this.pageSize,
    required this.currentPage,
    required this.totalPages,
    required this.galleries,
    required this.summary,
  });

  factory GalleryResModel.fromJson(Map<String, dynamic> json) => GalleryResModel(
    status: json["status"],
    count: json["count"],
    next: json["next"],
    previous: json["previous"],
    pageSize: json["page_size"],
    currentPage: json["current_page"],
    totalPages: json["total_pages"],
    galleries: List<Gallery>.from(json["galleries"].map((x) => Gallery.fromJson(x))),
    summary: Summary.fromJson(json["summary"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "count": count,
    "next": next,
    "previous": previous,
    "page_size": pageSize,
    "current_page": currentPage,
    "total_pages": totalPages,
    "galleries": List<dynamic>.from(galleries.map((x) => x.toJson())),
    "summary": summary.toJson(),
  };
}

class Gallery {
  String uid;
  String name;
  String description;
  dynamic thumbnail;
  bool isCommon;
  bool isActive;
  int videosCount;
  int foldersCount;
  int createdBy;
  String createdByName;
  dynamic assignedBatches;
  DateTime createdAt;
  DateTime updatedAt;

  Gallery({
    required this.uid,
    required this.name,
    required this.description,
    required this.thumbnail,
    required this.isCommon,
    required this.isActive,
    required this.videosCount,
    required this.foldersCount,
    required this.createdBy,
    required this.createdByName,
    required this.assignedBatches,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) => Gallery(
    uid: json["uid"],
    name: json["name"],
    description: json["description"],
    thumbnail: json["thumbnail"],
    isCommon: json["is_common"],
    isActive: json["is_active"],
    videosCount: json["videos_count"],
    foldersCount: json["folders_count"],
    createdBy: json["created_by"],
    createdByName: json["created_by_name"],
    assignedBatches: json["assigned_batches"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "name": name,
    "description": description,
    "thumbnail": thumbnail,
    "is_common": isCommon,
    "is_active": isActive,
    "videos_count": videosCount,
    "folders_count": foldersCount,
    "created_by": createdBy,
    "created_by_name": createdByName,
    "assigned_batches": assignedBatches,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

class AssignedBatch {
  String uid;
  String batchName;
  String courseName;
  bool isActive;

  AssignedBatch({required this.uid, required this.batchName, required this.courseName, required this.isActive});

  factory AssignedBatch.fromJson(Map<String, dynamic> json) => AssignedBatch(
    uid: json["uid"],
    batchName: json["batch_name"],
    courseName: json["course_name"],
    isActive: json["is_active"],
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "batch_name": batchName,
    "course_name": courseName,
    "is_active": isActive,
  };
}

class Summary {
  int totalGalleries;
  int commonGalleries;
  int activeGalleries;
  int totalVideos;
  int totalFolders;

  Summary({
    required this.totalGalleries,
    required this.commonGalleries,
    required this.activeGalleries,
    required this.totalVideos,
    required this.totalFolders,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    totalGalleries: json["total_galleries"],
    commonGalleries: json["common_galleries"],
    activeGalleries: json["active_galleries"],
    totalVideos: json["total_videos"],
    totalFolders: json["total_folders"],
  );

  Map<String, dynamic> toJson() => {
    "total_galleries": totalGalleries,
    "common_galleries": commonGalleries,
    "active_galleries": activeGalleries,
    "total_videos": totalVideos,
    "total_folders": totalFolders,
  };
}
