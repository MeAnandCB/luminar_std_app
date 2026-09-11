import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/job_community/job_community_model.dart';

class JobCommunityService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<JobCommunityListResponse>> getMyCommunities({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: AppEndpoints.jobCommunities,
        token: token,
        queryParams: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          JobCommunityListResponse.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 200,
        );
      }
      return response.cast<JobCommunityListResponse>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<JobCommunity>> getCommunityDetail(String communityUid) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: '${AppEndpoints.jobCommunities}$communityUid/',
        token: token,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          JobCommunity.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 200,
        );
      }
      return response.cast<JobCommunity>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<CommunityJobsResponse>> getCommunityJobs(
    String communityUid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: '${AppEndpoints.jobCommunityJobs}$communityUid/jobs/',
        token: token,
        queryParams: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          CommunityJobsResponse.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 200,
        );
      }
      return response.cast<CommunityJobsResponse>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  /// Same job-detail endpoint the regular Jobs feature uses — works here
  /// because a community share creates a broadcast recipient for the
  /// student, same as a direct job notification would.
  Future<ApiResponse<CommunityJobDetail>> getJobDetail(String jobUid) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: '${AppEndpoints.jobDetail}$jobUid/',
        token: token,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          CommunityJobDetail.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 200,
        );
      }
      return response.cast<CommunityJobDetail>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  // ── Chat (read-only) ───────────────────────────────────────────────────────

  Future<ApiResponse<List<CommunityMessage>>> getMessages(
    String chatUid, {
    int page = 1,
    int pageSize = 80,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: '${AppEndpoints.chatMessages}$chatUid/messages/',
        token: token,
        queryParams: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response.success) {
        final data = response.data;
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map<String, dynamic>) {
          results = data['results'] ?? data['messages'] ?? data['data'] ?? [];
        } else {
          results = [];
        }

        final messages = <CommunityMessage>[];
        for (final m in results) {
          try {
            messages.add(CommunityMessage.fromJson(m as Map<String, dynamic>));
          } catch (e) {
            debugPrint('[JobCommunityService] Skipped malformed message: $e');
          }
        }
        return ApiResponse.success(messages, response.statusCode ?? 200);
      }
      return ApiResponse.error(
        response.message ?? 'Failed to load messages',
        response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<void> markRead(String chatUid, List<String> messageUids) async {
    if (messageUids.isEmpty) return;
    try {
      final token = await AppUtils.getAccessKey();
      await _apiService.post(
        endpoint: '${AppEndpoints.markRead}$chatUid/messages/mark-read/',
        token: token,
        body: {'message_uids': messageUids},
      );
    } catch (_) {
      // Best-effort — not marking read shouldn't block the read-only view.
    }
  }

  // ── Apply ───────────────────────────────────────────────────────────────────

  Future<ApiResponse<CommunityApplyResult>> applyToJob({
    required String communityUid,
    required String jobUid,
    required String fullName,
    required String email,
    required String phone,
    required List<Map<String, dynamic>> answers,
    String? resumeFilePath,
    String? resumeUrl,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final endpoint =
          '${AppEndpoints.jobCommunityApply}$communityUid/jobs/$jobUid/apply/';

      final fields = <String, String>{
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'answers': jsonEncode(answers),
      };
      if (resumeUrl != null && resumeUrl.isNotEmpty) {
        fields['resume_url'] = resumeUrl;
      }

      final files = <http.MultipartFile>[];
      if (resumeFilePath != null && resumeFilePath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('resume', resumeFilePath));
      }

      final response = await _apiService.multipart(
        endpoint: endpoint,
        method: 'POST',
        fields: fields,
        files: files,
        token: token,
      );

      if (response.success && response.data is Map<String, dynamic>) {
        return ApiResponse.success(
          CommunityApplyResult.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 201,
        );
      }
      // Non-2xx responses come back with data=null (shared response handler
      // strips the body), but response.message already carries the
      // backend's `message` field — e.g. "You already have an active
      // application for this job." — extracted from the same JSON.
      return ApiResponse.error(
        response.message ?? 'Failed to apply',
        response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
