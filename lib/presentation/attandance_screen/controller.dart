// import 'package:flutter/material.dart';
// import 'package:luminar_std/core/utils/app_utils.dart';
// import 'package:luminar_std/repository/attandance_screen/model.dart';
// import 'package:luminar_std/repository/attandance_screen/service.dart';

// class AttendanceProvider with ChangeNotifier {
//   final AttendanceService _service;
//   final BuildContext context;

//   // State variables
//   AttandanceModel? _attendanceData;
//   bool _isLoading = false;
//   String? _errorMessage;
//   bool _hasError = false;

//   // Filter states
//   DateTime? _startDate;
//   DateTime? _endDate;
//   String? _selectedStatus;

//   // Pagination
//   int _currentPage = 1;
//   bool _hasMorePages = true;
//   bool _isLoadingMore = false;

//   // Current batch and student
//   String? _currentBatchId;
//   String? _currentStudentId;

//   // Constructor
//   AttendanceProvider({
//     required AttendanceService service,
//     required this.context,
//   }) : _service = service;

//   // Getters
//   AttandanceModel? get attendanceData => _attendanceData;
//   bool get isLoading => _isLoading;
//   bool get isLoadingMore => _isLoadingMore;
//   String? get errorMessage => _errorMessage;
//   bool get hasError => _hasError;
//   DateTime? get startDate => _startDate;
//   DateTime? get endDate => _endDate;
//   String? get selectedStatus => _selectedStatus;
//   bool get hasMorePages => _hasMorePages;
//   int get currentPage => _currentPage;

//   // Summary getters from API response
//   int get totalDays => _attendanceData?.summary?.totalDays ?? 0;
//   int get onlineCount => _attendanceData?.summary?.online ?? 0;
//   int get offlineCount => _attendanceData?.summary?.offline ?? 0;
//   int get recordingCount => _attendanceData?.summary?.recording ?? 0;
//   int get absentCount => _attendanceData?.summary?.absent ?? 0;

//   // Calculate present count
//   int get presentCount => onlineCount + offlineCount + recordingCount;

//   // Percentage getters
//   int get onlinePercentage => _attendanceData?.summary?.onlinePercentage ?? 0;
//   int get offlinePercentage => _attendanceData?.summary?.offlinePercentage ?? 0;
//   int get recordingPercentage =>
//       _attendanceData?.summary?.recordingPercentage ?? 0;
//   int get absentPercentage => _attendanceData?.summary?.absentPercentage ?? 0;

//   // Filter status options
//   final List<String> statusOptions = const [
//     'All Status',
//     'Online',
//     'Offline',
//     'Recording',
//     'Absent',
//   ];

//   // Initialize or refresh attendance data
//   Future<void> loadAttendance({
//     required String batchId,
//     String? studentId,
//     bool resetPagination = true,
//   }) async {
//     if (resetPagination) {
//       _currentPage = 1;
//       _hasMorePages = true;
//     }

//     _currentBatchId = batchId;
//     _currentStudentId = studentId;

//     await _fetchAttendanceData(resetPagination: resetPagination);
//   }

//   // Load more data for pagination
//   Future<void> loadMoreAttendance() async {
//     if (!_hasMorePages || _isLoadingMore || _isLoading) return;

//     _currentPage++;
//     await _fetchAttendanceData(resetPagination: false, isLoadMore: true);
//   }

//   // Core fetch method
//   Future<void> _fetchAttendanceData({
//     bool resetPagination = true,
//     bool isLoadMore = false,
//   }) async {
//     // Set loading state
//     if (isLoadMore) {
//       _isLoadingMore = true;
//     } else {
//       _isLoading = true;
//       _errorMessage = null;
//       _hasError = false;
//     }
//     notifyListeners();

//     try {
//       final response = await _service.getBatchAttendance(
//         context: context,
//         batchId: _currentBatchId!,
//         startDate: _startDate,
//         endDate: _endDate,
//         page: _currentPage,
//         pageSize: 20,
//       );

//       // Handle response
//       if (resetPagination) {
//         _attendanceData = response;
//       } else {
//         // Append new results for pagination
//         if (_attendanceData != null && response.results != null) {
//           final currentResults = List<dynamic>.from(
//             _attendanceData!.results ?? [],
//           );
//           final newResults = List<dynamic>.from(response.results ?? []);

//           currentResults.addAll(newResults);

//           _attendanceData = AttandanceModel(
//             status: response.status,
//             batchId: response.batchId,
//             studentId: response.studentId,
//             message: response.message,
//             summary: response.summary,
//             filtersApplied: response.filtersApplied,
//             count: response.count,
//             totalPages: response.totalPages,
//             currentPage: response.currentPage,
//             pageSize: response.pageSize,
//             next: response.next,
//             previous: response.previous,
//             results: currentResults,
//           );
//         }
//       }

//       // Update pagination state
//       _hasMorePages = response.next != null;
//       _errorMessage = null;
//       _hasError = false;
//     } catch (e) {
//       _errorMessage = e.toString().contains('ApiException')
//           ? AppUtils.getCleanErrorMessage(e.toString())
//           : 'Failed to load attendance data';
//       _hasError = true;
//       debugPrint('Error in provider: $e');
//     } finally {
//       _isLoading = false;
//       _isLoadingMore = false;
//       notifyListeners();
//     }
//   }

//   // Apply filters
//   Future<void> applyFilters({
//     DateTime? startDate,
//     DateTime? endDate,
//     String? status,
//   }) async {
//     // Update filter states
//     _startDate = startDate;
//     _endDate = endDate;
//     _selectedStatus = status != 'All Status' ? status : null;

//     // Reset to first page and reload
//     await loadAttendance(
//       batchId: _currentBatchId!,
//       studentId: _currentStudentId,
//       resetPagination: true,
//     );
//   }

//   // Clear all filters
//   Future<void> clearFilters() async {
//     _startDate = null;
//     _endDate = null;
//     _selectedStatus = null;

//     await loadAttendance(
//       batchId: _currentBatchId!,
//       studentId: _currentStudentId,
//       resetPagination: true,
//     );
//   }

//   // Refresh data (pull to refresh)
//   Future<void> refreshAttendance() async {
//     await loadAttendance(
//       batchId: _currentBatchId!,
//       studentId: _currentStudentId,
//       resetPagination: true,
//     );
//   }

//   // Retry after error
//   Future<void> retry() async {
//     if (_currentBatchId != null) {
//       await loadAttendance(
//         batchId: _currentBatchId!,
//         studentId: _currentStudentId,
//         resetPagination: true,
//       );
//     }
//   }

//   // Format date helper
//   String formatDate(DateTime? date) {
//     if (date == null) return 'dd/mm/yyyy';
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }

//   // Format date for API (YYYY-MM-DD)
//   String formatDateForApi(DateTime? date) {
//     if (date == null) return '';
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }

//   // Get status color
//   Color getStatusColor(String status) {
//     switch (status) {
//       case 'Online':
//         return Colors.green;
//       case 'Offline':
//         return Colors.grey;
//       case 'Recording':
//         return Colors.orange;
//       case 'Absent':
//         return const Color(0xFFFF7675);
//       default:
//         return Colors.blue;
//     }
//   }

//   // Get status icon
//   IconData getStatusIcon(String status) {
//     switch (status) {
//       case 'Online':
//         return Icons.wifi_rounded;
//       case 'Offline':
//         return Icons.wifi_off_rounded;
//       case 'Recording':
//         return Icons.videocam_rounded;
//       case 'Absent':
//         return Icons.person_off_rounded;
//       default:
//         return Icons.help_rounded;
//     }
//   }

//   // Check if any filter is active
//   bool get hasActiveFilters {
//     return _startDate != null || _endDate != null || _selectedStatus != null;
//   }

//   // Get active filters summary
//   Map<String, dynamic> get activeFilters {
//     final filters = <String, dynamic>{};
//     if (_startDate != null) filters['startDate'] = _startDate;
//     if (_endDate != null) filters['endDate'] = _endDate;
//     if (_selectedStatus != null) filters['status'] = _selectedStatus;
//     return filters;
//   }

//   // Export attendance
//   Future<String?> exportAttendance({required String format}) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final exportUrl = await _service.exportAttendance(
//         context: context,
//         batchId: _currentBatchId!,
//         startDate: _startDate,
//         endDate: _endDate,
//         format: format,
//       );

//       return exportUrl;
//     } catch (e) {
//       _errorMessage = e.toString().contains('ApiException')
//           ? AppUtils.getCleanErrorMessage(e.toString())
//           : 'Failed to export attendance';
//       _hasError = true;
//       return null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Get record status from API data
//   String getRecordStatus(dynamic record) {
//     if (record is Map<String, dynamic>) {
//       return record['status'] ?? 'Unknown';
//     }
//     return 'Unknown';
//   }

//   // Get record date from API data
//   DateTime getRecordDate(dynamic record) {
//     if (record is Map<String, dynamic> && record['date'] != null) {
//       try {
//         return DateTime.parse(record['date']);
//       } catch (e) {
//         return DateTime.now();
//       }
//     }
//     return DateTime.now();
//   }

//   // Get student name from API data
//   String getStudentName(dynamic record) {
//     if (record is Map<String, dynamic>) {
//       return record['student_name'] ??
//           record['student']?['name'] ??
//           'Unknown Student';
//     }
//     return 'Unknown Student';
//   }

//   // Get check-in time from API data
//   String getCheckInTime(dynamic record) {
//     if (record is Map<String, dynamic>) {
//       return record['check_in_time'] ?? '--:--';
//     }
//     return '--:--';
//   }

//   // Get duration from API data
//   String getDuration(dynamic record) {
//     if (record is Map<String, dynamic>) {
//       final duration = record['duration'] ?? record['total_duration'] ?? '0';

//       if (duration is int) {
//         final minutes = duration ~/ 60;
//         final hours = minutes ~/ 60;

//         if (hours > 0) {
//           return '${hours}h ${minutes % 60}m';
//         }
//         return '${minutes}m';
//       }

//       return duration.toString();
//     }
//     return '0 min';
//   }

//   // Dispose
//   @override
//   void dispose() {
//     super.dispose();
//   }
// }
