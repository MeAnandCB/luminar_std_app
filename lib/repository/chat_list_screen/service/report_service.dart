import 'package:url_launcher/url_launcher.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';

/// Address that receives reports of objectionable content / abusive users
/// when the backend report endpoint is unavailable, so the developer can
/// act on them within 24 hours as required by Guideline 1.2.
const String kAbuseReportEmail = 'support@luminartechnohub.com';

/// Submits user reports about objectionable content or abusive users.
///
/// Tries the backend report endpoint first; if that isn't available yet,
/// falls back to opening the device's email client pre-filled with the
/// report details so it always reaches the moderation team.
class ReportService {
  final ApiService _apiService = ApiService();
  final String token;

  ReportService({required this.token});

  Future<bool> submitReport({
    required String reason,
    String? description,
    required String chatUid,
    String? messageUid,
    String? messageContent,
    int? reportedUserId,
    String? reportedUserName,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: AppEndpoints.reportContent,
        token: token,
        body: {
          'chat': chatUid,
          if (messageUid != null) 'message': messageUid,
          if (reportedUserId != null) 'reported_user': reportedUserId,
          'reason': reason,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      if (response.success) return true;
    } catch (e) {
      LoggerUtils.error('Report API failed: $e', tag: 'Report');
    }

    return _sendReportEmail(
      reason: reason,
      description: description,
      chatUid: chatUid,
      messageUid: messageUid,
      messageContent: messageContent,
      reportedUserName: reportedUserName,
    );
  }

  Future<bool> _sendReportEmail({
    required String reason,
    String? description,
    required String chatUid,
    String? messageUid,
    String? messageContent,
    String? reportedUserName,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Reason: $reason')
      ..writeln('Chat ID: $chatUid');
    if (reportedUserName != null) buffer.writeln('Reported user: $reportedUserName');
    if (messageUid != null) buffer.writeln('Message ID: $messageUid');
    if (messageContent != null && messageContent.isNotEmpty) {
      buffer.writeln('Message content: $messageContent');
    }
    if (description != null && description.isNotEmpty) {
      buffer.writeln('\nAdditional details:\n$description');
    }

    final uri = Uri(
      scheme: 'mailto',
      path: kAbuseReportEmail,
      query: 'subject=${Uri.encodeComponent('Reported content/user - Luminar App')}'
          '&body=${Uri.encodeComponent(buffer.toString())}',
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
