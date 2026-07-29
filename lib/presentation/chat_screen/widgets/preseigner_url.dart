import 'dart:convert';
import 'dart:io';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

// ── Presigned URL response ────────────────────────────────────────────────────
class PresignedUrlResponse {
  final String uploadUrl;
  final Map<String, String> fields;
  final String s3Key;
  final String finalUrl;
  final String filename;
  final String originalFilename;
  final String folder;
  final String contentType;

  const PresignedUrlResponse({
    required this.uploadUrl,
    required this.fields,
    required this.s3Key,
    required this.finalUrl,
    required this.filename,
    required this.originalFilename,
    required this.folder,
    required this.contentType,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'] as Map<String, dynamic>? ?? {};
    final fields = rawFields.map((k, v) => MapEntry(k, v.toString()));
    return PresignedUrlResponse(
      uploadUrl: json['url'] as String,
      fields: fields,
      s3Key: json['s3_key'] as String,
      finalUrl: json['final_url'] as String,
      filename: json['filename'] as String,
      originalFilename: json['original_filename'] as String,
      folder: json['folder'] as String,
      contentType: json['content_type'] as String,
    );
  }
}

// ── Upload result returned to caller ─────────────────────────────────────────
class UploadResult {
  final String finalUrl;
  final String originalFilename;
  final String s3Key;
  final String contentType;
  final String messageType; // 'image' | 'audio' | 'video' | 'file'

  const UploadResult({
    required this.finalUrl,
    required this.originalFilename,
    required this.s3Key,
    required this.contentType,
    required this.messageType,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────
class FileUploadService {
  final String baseUrl;
  final String token;

  FileUploadService({required this.baseUrl, required this.token});

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ── Step 1: Get presigned URL from backend ────────────────────────────────
  Future<PresignedUrlResponse> getPresignedUrl({
    required String fileName,
    String folder = 'chat',
  }) async {
    final url = '$baseUrl/api/generate-presigned-url/';
    final payload = json.encode({'file_name': fileName, 'folder': folder});

    LoggerUtils.info('[Upload] POST $url', tag: 'Upload');

    final response = await http
        .post(
          Uri.parse(url),
          headers: _authHeaders,
          body: payload,
        )
        .timeout(const Duration(seconds: 20));

    LoggerUtils.info('[Upload] Presigned status: ${response.statusCode}', tag: 'Upload');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception('Backend returned success=false: ${response.body}');
      }
      return PresignedUrlResponse.fromJson(data);
    }
    throw Exception(
      'Presigned URL failed: ${response.statusCode} — ${response.body}',
    );
  }

  // ── Step 2: Upload file directly to S3 via multipart POST ─────────────────
  Future<void> _postToS3({
    required PresignedUrlResponse presigned,
    required File file,
    void Function(double)? onProgress,
  }) async {
    LoggerUtils.info('[Upload] S3 POST → ${presigned.uploadUrl}', tag: 'Upload');

    // Determine safe MediaType — fall back to application/octet-stream
    MediaType mediaType;
    try {
      final parts = presigned.contentType.split('/');
      if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        mediaType = MediaType(parts[0], parts[1]);
      } else {
        mediaType = MediaType('application', 'octet-stream');
      }
    } catch (_) {
      mediaType = MediaType('application', 'octet-stream');
    }


    final request = http.MultipartRequest(
      'POST',
      Uri.parse(presigned.uploadUrl),
    );

    // All policy fields must come BEFORE the file field
    presigned.fields.forEach((k, v) {
      request.fields[k] = v;
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mediaType,
        filename: presigned.originalFilename,
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await streamed.stream.bytesToString();

    LoggerUtils.info('[Upload] S3 response status: ${streamed.statusCode}', tag: 'Upload');

    if (streamed.statusCode != 204 &&
        streamed.statusCode != 200 &&
        streamed.statusCode != 201) {
      throw Exception(
        'S3 upload failed: ${streamed.statusCode} — $responseBody',
      );
    }

    onProgress?.call(1.0);
    LoggerUtils.info('[Upload] ✓ S3 upload complete: ${presigned.finalUrl}', tag: 'Upload');
  }

  // ── Public entry point ────────────────────────────────────────────────────
  Future<UploadResult> uploadFile(
    File file, {
    String folder = 'chat',
    void Function(double)? onProgress,
  }) async {
    final fileName = path.basename(file.path);

    // Resolve MIME type — try by extension first, then by content
    String mimeType = lookupMimeType(file.path) ?? '';
    if (mimeType.isEmpty) {
      mimeType = _mimeFromExtension(fileName);
    }
    if (mimeType.isEmpty) {
      mimeType = 'application/octet-stream';
    }

    LoggerUtils.info(
      '[Upload] File: $fileName, detected mimeType: $mimeType',
      tag: 'Upload',
    );

    onProgress?.call(0.05);

    final presigned = await getPresignedUrl(fileName: fileName, folder: folder);
    LoggerUtils.info(
      '[Upload] Backend presigned content_type: ${presigned.contentType} '
      '(client detected: $mimeType) → finalUrl: ${presigned.finalUrl}',
      tag: 'Upload',
    );
    onProgress?.call(0.15);

    await _postToS3(
      presigned: presigned,
      file: file,
      onProgress: (p) => onProgress?.call(0.15 + p * 0.80),
    );
    onProgress?.call(1.0);

    return UploadResult(
      finalUrl: presigned.finalUrl,
      originalFilename: presigned.originalFilename,
      s3Key: presigned.s3Key,
      contentType: presigned.contentType,
      messageType: _resolveMessageType(mimeType),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps MIME type to message_type accepted by the backend.
  /// Backend only accepts: 'image' | 'audio' | 'file'
  /// Video files are sent as 'file' since backend rejects 'video'.
  String _resolveMessageType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('audio/')) return 'audio';
    // video/* → 'file' (backend does not support 'video' message_type)
    return 'file';
  }

  /// Fallback MIME lookup by file extension when mime package can't detect
  String _mimeFromExtension(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    const map = <String, String>{
      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      // Video
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      '3gp': 'video/3gpp',
      // Audio
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'opus': 'audio/opus',
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'rtf': 'application/rtf',
      // Archives
      'zip': 'application/zip',
      'rar': 'application/vnd.rar',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
    };
    return map[ext] ?? '';
  }

}
