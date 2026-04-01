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

  // Getters
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<EnrollmentBatch> get batches => _batches;
  EnrollmentBatch? get selectedBatch => _selectedBatch;
  BatchSession? get selectedSession => _selectedSession;
  AttendanceResponse? get attendanceData => _attendanceData;
  List<AttendanceRecord> get allRecords => _allRecords;
  bool get hasMore => _hasMore;

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    _error = null;
    notifyListeners();

    final response = await _service.getDashboard();

    if (response.success && response.data != null) {
      final dashboard = response.data!['dashboard'] as Map<String, dynamic>?;
      final enrollments =
          dashboard?['enrollment_details']?['enrollments'] as List<dynamic>? ??
          [];

      _batches = enrollments
          .map((e) => EnrollmentBatch.fromJson(e as Map<String, dynamic>))
          .where((b) => b.uid.isNotEmpty)
          .toList();

      if (_batches.isNotEmpty) {
        _selectedBatch = _batches.first;
        _isLoadingDashboard = false;
        notifyListeners();
        await loadAttendance();
        return;
      }
    } else {
      _error = response.message ?? 'Failed to load dashboard';
    }

    _isLoadingDashboard = false;
    notifyListeners();
  }

  Future<void> selectBatch(EnrollmentBatch batch) async {
    if (_selectedBatch?.uid == batch.uid) return;
    _selectedBatch = batch;
    _selectedSession = null;
    _allRecords = [];
    _attendanceData = null;
    _currentPage = 1;
    notifyListeners();
    await loadAttendance();
  }

  Future<void> selectSession(BatchSession? session) async {
    if (_selectedSession?.uid == session?.uid) return;
    _selectedSession = session;
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
      page: nextPage,
    );

    if (response.success && response.data != null) {
      _allRecords.addAll(response.data!.results as Iterable<AttendanceRecord>);
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
