import 'package:flutter/material.dart';
import 'package:luminar_std/repository/attandance_screen/model.dart'
    hide AttendanceResponse, AttendanceRecord;
import 'package:luminar_std/repository/attandance_screen/new_model.dart';
import 'package:luminar_std/repository/attandance_screen/service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  // Loading states
  bool _isLoadingDashboard = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingMore = false;

  // Error
  String? _error;

  // Data
  List<EnrollmentBatch> _batches = [];
  EnrollmentBatch? _selectedBatch;
  BatchSession? _selectedSession;
  AttendanceResponse? _attendanceData;
  List<AttendanceRecord> _allRecords = [];
  int _currentPage = 1;
  bool _hasMore = false;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String _statusFilter = 'All';

  // Getters
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<EnrollmentBatch> get batches => _batches;
  EnrollmentBatch? get selectedBatch => _selectedBatch;
  BatchSession? get selectedSession => _selectedSession;
  AttendanceResponse? get attendanceData => _attendanceData;
  bool get hasMore => _hasMore;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get statusFilter => _statusFilter;

  bool get hasActiveFilters =>
      _startDate != null || _endDate != null || _statusFilter != 'All';

  /// Records after client-side status filter is applied.
  List<AttendanceRecord> get allRecords {
    if (_statusFilter == 'All') return _allRecords;
    return _allRecords
        .where(
          (r) => r.status.toLowerCase() == _statusFilter.toLowerCase(),
        )
        .toList();
  }

  // Sessions for the current batch (populated from dashboard)
  List<BatchSession> _sessions = [];
  List<BatchSession> get sessions => _sessions;

  /// Called every time the screen opens — always fetches fresh data.
  ///
  /// Pass [preloadedSessions] to skip the duplicate dashboard API call when
  /// the caller already has session data from [DashboardController].
  Future<void> initWithBatch({
    required String batchId,
    required String batchName,
    String courseName = '',
    List<BatchSession> preloadedSessions = const [],
  }) async {
    _selectedBatch = EnrollmentBatch(
      uid: batchId,
      batchName: batchName,
      startDate: '',
      endDate: '',
      courseName: courseName,
      sessions: [],
    );
    _sessions = preloadedSessions;
    _selectedSession = null;
    _allRecords = [];
    _attendanceData = null;
    _currentPage = 1;
    _startDate = null;
    _endDate = null;
    _statusFilter = 'All';
    _error = null;
    notifyListeners();

    if (preloadedSessions.isNotEmpty) {
      // Sessions already provided — only fetch attendance data
      await loadAttendance();
    } else {
      // Fallback: fetch both in parallel (sessions come from dashboard API)
      await Future.wait([loadAttendance(), _loadSessions(batchId)]);
    }
  }

  /// Fetches sessions for the current batch from the dashboard API.
  /// Only called when the caller did not supply [preloadedSessions].
  Future<void> _loadSessions(String batchId) async {
    final response = await _service.getDashboard();
    if (response.success && response.data != null) {
      final dashboard = response.data!['dashboard'] as Map<String, dynamic>?;
      final enrollments =
          dashboard?['enrollment_details']?['enrollments'] as List<dynamic>? ??
          [];
      for (final e in enrollments) {
        final batch = EnrollmentBatch.fromJson(e as Map<String, dynamic>);
        if (batch.uid == batchId) {
          _sessions = batch.sessions;
          notifyListeners();
          return;
        }
      }
    }
  }

  Future<void> selectSession(BatchSession? session) async {
    if (session == null) {
      // Explicit deselect (× chip tapped)
      if (_selectedSession == null) return;
      _selectedSession = null;
    } else if (_selectedSession?.uid == session.uid) {
      // Tap same chip again → deselect
      _selectedSession = null;
    } else {
      _selectedSession = session;
    }
    _allRecords = [];
    _attendanceData = null;
    _currentPage = 1;
    notifyListeners();
    await loadAttendance();
  }

  /// Apply date + status filters and reload from page 1.
  Future<void> applyFilters({
    DateTime? startDate,
    DateTime? endDate,
    String statusFilter = 'All',
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    _statusFilter = statusFilter;
    _allRecords = [];
    _attendanceData = null;
    _currentPage = 1;
    notifyListeners();
    await loadAttendance();
  }

  /// Clear all filters and reload.
  Future<void> clearFilters() async {
    _startDate = null;
    _endDate = null;
    _statusFilter = 'All';
    _allRecords = [];
    _attendanceData = null;
    _currentPage = 1;
    notifyListeners();
    await loadAttendance();
  }

  Future<void> loadAttendance() async {
    if (_selectedBatch == null) return;

    _isLoadingAttendance = true;
    _error = null;
    notifyListeners();

    final response = await _service.getBatchAttendance(
      batchId: _selectedBatch!.uid,
      sessionId: _selectedSession?.uid,
      startDate: _startDate != null
          ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
          : null,
      endDate: _endDate != null
          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
          : null,
      page: 1,
    );

    if (response.success && response.data != null) {
      _attendanceData = response.data as AttendanceResponse;
      _allRecords = List<AttendanceRecord>.from(response.data!.results);
      _currentPage = 1;
      _hasMore = response.data!.next != null;
    } else {
      _error = response.message ?? 'Failed to load attendance';
    }

    _isLoadingAttendance = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_selectedBatch == null || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final response = await _service.getBatchAttendance(
      batchId: _selectedBatch!.uid,
      sessionId: _selectedSession?.uid,
      startDate: _startDate != null
          ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
          : null,
      endDate: _endDate != null
          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
          : null,
      page: nextPage,
    );

    if (response.success && response.data != null) {
      _allRecords.addAll(
        response.data!.results as Iterable<AttendanceRecord>,
      );
      _currentPage = nextPage;
      _hasMore = response.data!.next != null;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
