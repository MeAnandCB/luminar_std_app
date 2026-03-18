// models/folder_model.dart
class FolderModel {
  final String uid;
  final String name;
  final String description;
  final String icon;
  final String gallery;
  final String? parentFolder;
  final int displayOrder;
  final int videosCount;
  final int subfoldersCount;
  final int createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.uid,
    required this.name,
    required this.description,
    required this.icon,
    required this.gallery,
    this.parentFolder,
    required this.displayOrder,
    required this.videosCount,
    required this.subfoldersCount,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      gallery: json['gallery'] ?? '',
      parentFolder: json['parent_folder'],
      displayOrder: json['display_order'] ?? 0,
      videosCount: json['videos_count'] ?? 0,
      subfoldersCount: json['subfolders_count'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      createdByName: json['created_by_name'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// models/video_model.dart
class VideoModel {
  final String uid;
  final String title;
  final String description;
  final String videoSource;
  final String? videoUrl;
  final String? videoFile;
  final String? thumbnailUrl;
  final String? thumbnail;
  final int? duration;
  final int? fileSize;
  final int displayOrder;
  final String gallery;
  final String? folder;
  final int uploadedBy;
  final String uploadedByName;
  final bool isActive;
  final String locationPath;
  final String? videoLink;
  final String? thumbnailLink;
  final String? embedCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoModel({
    required this.uid,
    required this.title,
    required this.description,
    required this.videoSource,
    this.videoUrl,
    this.videoFile,
    this.thumbnailUrl,
    this.thumbnail,
    this.duration,
    this.fileSize,
    required this.displayOrder,
    required this.gallery,
    this.folder,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.isActive,
    required this.locationPath,
    this.videoLink,
    this.thumbnailLink,
    this.embedCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      uid: json['uid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoSource: json['video_source'] ?? '',
      videoUrl: json['video_url'],
      videoFile: json['video_file'],
      thumbnailUrl: json['thumbnail_url'],
      thumbnail: json['thumbnail'],
      duration: json['duration'],
      fileSize: json['file_size'],
      displayOrder: json['display_order'] ?? 0,
      gallery: json['gallery'] ?? '',
      folder: json['folder'],
      uploadedBy: json['uploaded_by'] ?? 0,
      uploadedByName: json['uploaded_by_name'] ?? '',
      isActive: json['is_active'] ?? true,
      locationPath: json['location_path'] ?? '',
      videoLink: json['video_link'],
      thumbnailLink: json['thumbnail_link'],
      embedCode: json['embed_code'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// models/folder_response_model.dart
class FolderResponseModel {
  final String status;
  final List<FolderModel> folders;
  final FolderSummary summary;

  FolderResponseModel({required this.status, required this.folders, required this.summary});

  factory FolderResponseModel.fromJson(Map<String, dynamic> json) {
    return FolderResponseModel(
      status: json['status'] ?? '',
      folders: (json['folders'] as List?)?.map((item) => FolderModel.fromJson(item)).toList() ?? [],
      summary: FolderSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class FolderSummary {
  final int totalFolders;
  final int totalVideos;

  FolderSummary({required this.totalFolders, required this.totalVideos});

  factory FolderSummary.fromJson(Map<String, dynamic> json) {
    return FolderSummary(totalFolders: json['total_folders'] ?? 0, totalVideos: json['total_videos'] ?? 0);
  }
}

// models/video_response_model.dart
class VideoResponseModel {
  final String status;
  final List<VideoModel> videos;
  final VideoSummary summary;
  final VideoPagination pagination;

  VideoResponseModel({required this.status, required this.videos, required this.summary, required this.pagination});

  factory VideoResponseModel.fromJson(Map<String, dynamic> json) {
    return VideoResponseModel(
      status: json['status'] ?? '',
      videos: (json['videos'] as List?)?.map((item) => VideoModel.fromJson(item)).toList() ?? [],
      summary: VideoSummary.fromJson(json['summary'] ?? {}),
      pagination: VideoPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class VideoSummary {
  final int totalVideos;
  final int activeVideos;
  final int totalDuration;
  final int totalSize;

  VideoSummary({
    required this.totalVideos,
    required this.activeVideos,
    required this.totalDuration,
    required this.totalSize,
  });

  factory VideoSummary.fromJson(Map<String, dynamic> json) {
    return VideoSummary(
      totalVideos: json['total_videos'] ?? 0,
      activeVideos: json['active_videos'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      totalSize: json['total_size'] ?? 0,
    );
  }
}

class VideoPagination {
  final int count;
  final dynamic next;
  final dynamic previous;
  final int currentPage;
  final int totalPages;
  final int pageSize;

  VideoPagination({
    required this.count,
    this.next,
    this.previous,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
  });

  factory VideoPagination.fromJson(Map<String, dynamic> json) {
    return VideoPagination(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      pageSize: json['page_size'] ?? 10,
    );
  }
}

// models/gallery_detail_model.dart
class GalleryDetailData {
  final List<FolderModel> folders;
  final List<VideoModel> videos;
  final FolderSummary folderSummary;
  final VideoSummary videoSummary;
  final VideoPagination videoPagination;

  GalleryDetailData({
    required this.folders,
    required this.videos,
    required this.folderSummary,
    required this.videoSummary,
    required this.videoPagination,
  });
}

// models/folder_path_model.dart
class FolderPathItem {
  final String uid;
  final String name;
  final String? parentFolderUid;

  FolderPathItem({required this.uid, required this.name, this.parentFolderUid});
}

// models/folder_content_model.dart
class FolderContent {
  final List<FolderModel> subfolders;
  final List<VideoModel> videos;
  final FolderSummary folderSummary;
  final VideoSummary videoSummary;
  final VideoPagination videoPagination;
  final String currentFolderUid;
  final String currentFolderName;

  FolderContent({
    required this.subfolders,
    required this.videos,
    required this.folderSummary,
    required this.videoSummary,
    required this.videoPagination,
    required this.currentFolderUid,
    required this.currentFolderName,
  });
}
