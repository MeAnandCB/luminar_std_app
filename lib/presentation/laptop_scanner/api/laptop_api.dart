import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class LaptopAsset {
  final String id;
  final String assetTag;
  final String name;
  final String serialNumber;
  final int scanCount;

  LaptopAsset.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? '',
      assetTag = j['assetTag'] ?? '',
      name = j['name'] ?? '',
      serialNumber = j['serialNumber'] ?? '',
      scanCount = (j['scanCount'] ?? 0) as int;
}

class LaptopLoan {
  final String studentName;
  final String studentId;
  final String batch;
  final DateTime checkOutAt;
  final bool isEarlyReturn;
  final int accessoryCount;

  LaptopLoan.fromJson(Map<String, dynamic> j)
    : studentName   = j['studentName']   ?? '',
      studentId     = j['studentId']     ?? '',
      batch         = j['batch']         ?? '',
      checkOutAt    = DateTime.tryParse(j['checkOutAt'] ?? '') ?? DateTime.now(),
      isEarlyReturn = j['isEarlyReturn'] == true,
      accessoryCount = (j['accessoryCount'] ?? 0) as int;
}

class AccessoryInfo {
  final String id;
  final String assetTag;
  final String name;
  final String type; // charger | mouse | keyboard | bag | other
  final String status;

  AccessoryInfo.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? '',
      assetTag = j['assetTag'] ?? '',
      name = j['name'] ?? '',
      type = j['type'] ?? '',
      status = j['status'] ?? '';
}

class LaptopCounts {
  final int total;
  final int available;
  final int out;

  const LaptopCounts({
    required this.total,
    required this.available,
    required this.out,
  });

  LaptopCounts.fromJson(Map<String, dynamic> j)
    : total = (j['total'] ?? 0) as int,
      available = (j['available'] ?? 0) as int,
      out = (j['out'] ?? 0) as int;

  static const empty = LaptopCounts(total: 0, available: 0, out: 0);
}

class LookupResult {
  final String itemType; // 'laptop' | 'accessory'
  final String? state; // laptop only: 'available' | 'assigned'
  final LaptopAsset? asset;
  final LaptopLoan? loan; // laptop only, null when available
  final AccessoryInfo? accessory;
  final LaptopCounts counts;

  bool get isLaptop => itemType == 'laptop';
  bool get isAccessory => itemType == 'accessory';

  LookupResult.fromJson(Map<String, dynamic> j)
    : itemType = j['itemType'] ?? 'laptop',
      state = j['state'] as String?,
      asset = j['asset'] != null
          ? LaptopAsset.fromJson(j['asset'] as Map<String, dynamic>)
          : null,
      loan = j['loan'] != null
          ? LaptopLoan.fromJson(j['loan'] as Map<String, dynamic>)
          : null,
      accessory = j['accessory'] != null
          ? AccessoryInfo.fromJson(j['accessory'] as Map<String, dynamic>)
          : null,
      counts = j['counts'] != null
          ? LaptopCounts.fromJson(j['counts'] as Map<String, dynamic>)
          : LaptopCounts.empty;
}

class CheckedOutItem {
  final String kind; // 'laptop' | 'accessory'
  final String name;
  final String assetTag;

  bool get isLaptop => kind == 'laptop';

  CheckedOutItem.fromJson(Map<String, dynamic> j)
    : kind = j['kind'] ?? j['itemType'] ?? '',
      name = j['name'] ?? '',
      assetTag = j['assetTag'] ?? '';
}

class CheckoutActionResult {
  final LaptopCounts counts;
  final List<CheckedOutItem> items;

  CheckoutActionResult.fromJson(Map<String, dynamic> j)
    : counts = j['counts'] != null
          ? LaptopCounts.fromJson(j['counts'] as Map<String, dynamic>)
          : LaptopCounts.empty,
      items = (j['items'] as List?)
              ?.map((e) => CheckedOutItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
}

class ReturnActionResult {
  final String status; // 'returned' | 'partial'
  final LaptopCounts counts;

  bool get isFullyReturned => status == 'returned';

  ReturnActionResult.fromJson(Map<String, dynamic> j)
    : status = (j['loan'] as Map<String, dynamic>?)?['status'] as String? ??
          'returned',
      counts = j['counts'] != null
          ? LaptopCounts.fromJson(j['counts'] as Map<String, dynamic>)
          : LaptopCounts.empty;
}

class LoanHistoryEntry {
  final String id;
  final String laptopName;
  final String assetTag;
  final String serialNumber;
  final String studentName;
  final String studentId;
  final String batch;
  final DateTime checkOutAt;
  final DateTime? returnedAt;

  bool get isActive => returnedAt == null;

  LoanHistoryEntry.fromJson(Map<String, dynamic> j)
    : id          = j['id']          ?? '',
      laptopName  = j['laptopName']  ?? (j['laptop']?['name'] ?? ''),
      assetTag    = j['assetTag']    ?? (j['laptop']?['assetTag'] ?? ''),
      serialNumber= j['serialNumber']?? (j['laptop']?['serialNumber'] ?? ''),
      studentName = j['studentName'] ?? '',
      studentId   = j['studentId']   ?? '',
      batch       = j['batch']       ?? '',
      checkOutAt  = DateTime.tryParse(j['checkOutAt']  ?? '') ?? DateTime.now(),
      returnedAt  = j['returnedAt'] != null
          ? DateTime.tryParse(j['returnedAt'] as String)
          : null;
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

// ── API client ────────────────────────────────────────────────────────────────

class LaptopApi {
  final AppConfigLap config;
  LaptopApi(this.config);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': config.apiKey,
  };

  // baseUrl already contains the full path e.g. http://host/api/mobile/laptops
  String get _base => config.baseUrl;

  Future<LookupResult> lookup(String identifier) async {
    final res = await _post('$_base/lookup', {'identifier': identifier});
    return LookupResult.fromJson(res);
  }

  Future<CheckoutActionResult> checkout({
    required String identifier,
    required List<String> accessoryIdentifiers,
    required String studentName,
    required String studentId,
    String batch = '',
  }) async {
    final res = await _post('$_base/checkout', {
      'identifier':  identifier,
      'accessoryIdentifiers': accessoryIdentifiers,
      'studentName': studentName,
      'studentId':   studentId,
      if (batch.isNotEmpty) 'batch': batch,
    });
    return CheckoutActionResult.fromJson(res);
  }

  Future<List<LoanHistoryEntry>> getHistory(String studentId) async {
    assert(studentId.isNotEmpty, 'studentId must not be empty — never call /history without it');
    final uri = Uri.parse('$_base/history')
        .replace(queryParameters: {'studentId': studentId});
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = decoded is List
            ? decoded
            : (decoded as Map<String, dynamic>)['loans'] as List? ?? [];
        return list
            .cast<Map<String, dynamic>>()
            .map(LoanHistoryEntry.fromJson)
            .toList();
      }
      final err = decoded is Map ? decoded['error'] ?? 'Failed to load history' : 'Failed to load history';
      throw ApiException(res.statusCode, err as String);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, 'Cannot reach the server. Check your connection.');
    }
  }

  /// [identifiers] is whatever's being physically handed back right now —
  /// can be just the laptop, just some accessories, or everything.
  Future<ReturnActionResult> returnItems({
    required List<String> identifiers,
    String? rackCode,
    String? earlyReturnFeedback,
  }) async {
    final res = await _post('$_base/return', {
      'identifiers': identifiers,
      if (rackCode != null && rackCode.isNotEmpty) 'rackCode': rackCode,
      if (earlyReturnFeedback != null && earlyReturnFeedback.isNotEmpty)
        'earlyReturnFeedback': earlyReturnFeedback,
    });
    return ReturnActionResult.fromJson(res);
  }


  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(res.statusCode, decoded['error'] ?? 'Request failed');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        0,
        'Cannot reach the server. Check your connection.',
      );
    }
  }
}
