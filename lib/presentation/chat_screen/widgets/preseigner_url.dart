import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

// ── Presigned URL response ────────────────────────────────────────────────────
class PresignedUrlResponse {
  final String uploadUrl; // https://luminar-crm-storage.s3.amazonaws.com/
  final Map<String, String>
  fields; // All S3 policy fields for the multipart POST
  final String s3Key; // chat/uuid.jpg
  final String finalUrl; // CloudFront URL — stored in the message
  final String filename; // UUID-renamed filename
  final String originalFilename; // RAKESH.jpg
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

// ── Result returned to the caller ─────────────────────────────────────────────
class UploadResult {
  final String finalUrl; // CloudFront CDN URL
  final String originalFilename; // RAKESH.jpg
  final String s3Key; // chat/uuid.jpg
  final String contentType; // image/jpeg
  final String messageType; // 'image' | 'file' | 'audio' | 'video'

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

  // ── Step 1: Ask backend for presigned fields ──────────────────────────────
  // POST /api/generate-presigned-url/
  // Body: { "file_name": "RAKESH.jpg", "folder": "chat" }
  Future<PresignedUrlResponse> getPresignedUrl({
    required String fileName,
    String folder = 'chat',
  }) async {
    final url = '$baseUrl/api/generate-presigned-url/';
    final payload = json.encode({'file_name': fileName, 'folder': folder});

    debugPrint('[Upload] POST $url');
    debugPrint('[Upload] Payload: $payload');

    final response = await http.post(
      Uri.parse(url),
      headers: _authHeaders,
      body: payload,
    );

    debugPrint('[Upload] Presigned status: ${response.statusCode}');
    debugPrint('[Upload] Presigned body  : ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception('Backend returned success=false: ${response.body}');
      }
      return PresignedUrlResponse.fromJson(data);
    }
    throw Exception(
      'Failed to get presigned URL: ${response.statusCode} — ${response.body}',
    );
  }

  // ── Step 2: Multipart POST directly to S3 ────────────────────────────────
  // S3 presigned POST requires ALL fields as form fields, with "file" last.
  // Returns 204 No Content on success.
  Future<void> _postToS3({
    required PresignedUrlResponse presigned,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('[Upload] S3 multipart POST → ${presigned.uploadUrl}');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(presigned.uploadUrl),
    );

    // All policy fields must come before the file field
    presigned.fields.forEach((k, v) => request.fields[k] = v);

    // Determine media type
    final parts = presigned.contentType.split('/');
    final mediaType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('application', 'octet-stream');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mediaType,
        filename: presigned.originalFilename,
      ),
    );

    final streamed = await request.send();
    debugPrint('[Upload] S3 response: ${streamed.statusCode}');

    // S3 presigned POST → 204 No Content on success
    if (streamed.statusCode != 204 &&
        streamed.statusCode != 200 &&
        streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('S3 upload failed: ${streamed.statusCode} — $body');
    }

    onProgress?.call(1.0);
    debugPrint(
      '[Upload] ✓ S3 upload complete. CloudFront URL: ${presigned.finalUrl}',
    );
  }

  // ── Public entry point ────────────────────────────────────────────────────
  Future<UploadResult> uploadFile(
    File file, {
    String folder = 'chat',
    void Function(double progress)? onProgress,
  }) async {
    final fileName = path.basename(file.path);
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    onProgress?.call(0.05);
    final presigned = await getPresignedUrl(fileName: fileName, folder: folder);

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

  String _resolveMessageType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('video/')) return 'video';
    return 'file';
  }
}
