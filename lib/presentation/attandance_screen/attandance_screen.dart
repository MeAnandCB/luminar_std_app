import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Filter states
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'All Status';

  // Temporary filter states for dialog
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  String _tempSelectedStatus = 'All Status';

  // Available status options
  final List<String> _statusOptions = [
    'All Status',
    'Online',
    'Offline',
    'Recording',
    'Absent',
  ];

  // Dummy attendance data
  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> _filteredRecords = [];

  // Dummy recording videos
  final List<RecordingVideo> _recordingVideos = [
    RecordingVideo(
      title: 'ASP.NET MVC Introduction',
      thumbnail: 'https://img.youtube.com/vi/kzpS-A3QJqE/0.jpg',
      uploadedBy: 'John Smith',
      uploadedDate: DateTime(2026, 3, 4),
      duration: '45:30',
      views: 234,
    ),
    RecordingVideo(
      title: 'Angular Components Deep Dive',
      thumbnail: 'https://img.youtube.com/vi/3qBXWUpoPHo/0.jpg',
      uploadedBy: 'Sarah Wilson',
      uploadedDate: DateTime(2026, 3, 3),
      duration: '52:15',
      views: 156,
    ),
    RecordingVideo(
      title: 'Database Connectivity with Entity Framework',
      thumbnail: 'https://img.youtube.com/vi/8jcL7Hn2KPI/0.jpg',
      uploadedBy: 'Mike Johnson',
      uploadedDate: DateTime(2026, 3, 2),
      duration: '1:08:22',
      views: 89,
    ),
    RecordingVideo(
      title: 'REST API Development',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg',
      uploadedBy: 'Emma Davis',
      uploadedDate: DateTime(2026, 3, 1),
      duration: '38:45',
      views: 412,
    ),
    RecordingVideo(
      title: 'Authentication in ASP.NET Core',
      thumbnail: 'https://img.youtube.com/vi/1ukSR1GRtMU/0.jpg',
      uploadedBy: 'John Smith',
      uploadedDate: DateTime(2026, 2, 28),
      duration: '55:10',
      views: 178,
    ),
  ];

  // Summary stats
  Map<String, int> _stats = {
    'total': 1,
    'online': 0,
    'offline': 0,
    'recording': 0,
    'absent': 0,
    'present': 0,
  };

  @override
  void initState() {
    super.initState();
  }

  String _getWeightedRandomStatus() {
    // Make stats look realistic: more Online/Offline, fewer Absent/Recording
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    if (random < 35) return 'Online'; // 35% Online
    if (random < 65) return 'Offline'; // 30% Offline
    if (random < 85) return 'Recording'; // 20% Recording
    return 'Absent'; // 15% Absent
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        // Apply start date filter
        if (_startDate != null) {
          if (record.date.isBefore(_startDate!)) {
            return false;
          }
        }

        // Apply end date filter
        if (_endDate != null) {
          if (record.date.isAfter(_endDate!)) {
            return false;
          }
        }

        // Apply status filter
        if (_selectedStatus != 'All Status') {
          if (record.status != _selectedStatus) {
            return false;
          }
        }

        return true;
      }).toList();

      // Update stats based on filtered records
      _updateStats();
    });
  }

  void _updateStats() {
    int total = _filteredRecords.length;
    int online = _filteredRecords.where((r) => r.status == 'Online').length;
    int offline = _filteredRecords.where((r) => r.status == 'Offline').length;
    int recording = _filteredRecords
        .where((r) => r.status == 'Recording')
        .length;
    int absent = _filteredRecords.where((r) => r.status == 'Absent').length;
    int present = total - absent;

    setState(() {
      _stats = {
        'total': total,
        'online': online,
        'offline': offline,
        'recording': recording,
        'absent': absent,
        'present': present,
      };
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _applyFilters();
    }
  }

  void _showFilterDialog() {
    // Initialize temp values with current filter values
    _tempStartDate = _startDate;
    _tempEndDate = _endDate;
    _tempSelectedStatus = _selectedStatus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Attendance',
                          style: AppTextStyles.heading2,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Date Range Section
                    Text('Date Range', style: AppTextStyles.statLabel),
                    const SizedBox(height: 12),

                    // Start Date
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _tempStartDate ?? DateTime.now(),
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2026, 12, 31),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.white,
                                  surface: AppColors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _tempStartDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _tempStartDate == null
                                  ? 'Start Date'
                                  : 'From: ${_formatDate(_tempStartDate)}',
                              style: TextStyle(
                                color: _tempStartDate == null
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // End Date
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _tempEndDate ?? DateTime.now(),
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2026, 12, 31),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.white,
                                  surface: AppColors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _tempEndDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _tempEndDate == null
                                  ? 'End Date'
                                  : 'To: ${_formatDate(_tempEndDate)}',
                              style: TextStyle(
                                color: _tempEndDate == null
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    Text('Status', style: AppTextStyles.statLabel),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tempSelectedStatus,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.primary,
                          ),
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  if (status != 'All Status')
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (status != 'All Status')
                                    const SizedBox(width: 8),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'All Status'
                                          ? AppColors.textSecondary
                                          : _getStatusColor(status),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _tempSelectedStatus = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Clear temp filters
                              setState(() {
                                _tempStartDate = null;
                                _tempEndDate = null;
                                _tempSelectedStatus = 'All Status';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Apply filters
                              setState(() {
                                _startDate = _tempStartDate;
                                _endDate = _tempEndDate;
                                _selectedStatus = _tempSelectedStatus;
                              });
                              _applyFilters();
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Filters applied successfully',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedStatus = 'All Status';
    });
    _applyFilters();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Online':
        return AppColors.statsGreen;
      case 'Offline':
        return Colors.grey;
      case 'Recording':
        return AppColors.statsOrange;
      case 'Absent':
        return const Color(0xFFFF7675);
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'dd/mm/yyyy';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatUploadDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Attendance & Recordings',
                      style: AppTextStyles.heading2.copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ),

              // Course Info Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primaryLight.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asp.net MVC with Angular',
                            style: AppTextStyles.activityTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Full Stack • ggf',
                            style: AppTextStyles.activitySubtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Legend Section
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Online', AppColors.statsGreen),
                        _buildLegendItem('Offline', Colors.grey),
                        _buildLegendItem('Recording', AppColors.statsOrange),
                        _buildLegendItem('Absent', const Color(0xFFFF7675)),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      'Total',
                      _stats['total'].toString(),
                      AppColors.primary,
                      Icons.people_rounded,
                    ),
                    _buildStatCard(
                      'Online',
                      _stats['online'].toString(),
                      AppColors.statsGreen,
                      Icons.wifi_rounded,
                    ),
                    _buildStatCard(
                      'Offline',
                      _stats['offline'].toString(),
                      Colors.grey,
                      Icons.wifi_off_rounded,
                    ),
                    _buildStatCard(
                      'Recording',
                      _stats['recording'].toString(),
                      AppColors.statsOrange,
                      Icons.videocam_rounded,
                    ),
                    _buildStatCard(
                      'Absent',
                      _stats['absent'].toString(),
                      const Color(0xFFFF7675),
                      Icons.person_off_rounded,
                    ),
                    _buildStatCard(
                      'Present',
                      _stats['present'].toString(),
                      AppColors.primary,
                      Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Filter Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _showFilterDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_list_rounded),
                              const SizedBox(width: 8),
                              const Text(
                                'Filter Attendance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_startDate != null ||
                        _endDate != null ||
                        _selectedStatus != 'All Status')
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _clearFilters,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFFF7675),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Active Filters Display
              if (_startDate != null ||
                  _endDate != null ||
                  _selectedStatus != 'All Status')
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Filters:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_startDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'From: ${_formatDate(_startDate)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            if (_endDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'To: ${_formatDate(_endDate)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            if (_selectedStatus != 'All Status')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _selectedStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_selectedStatus),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getStatusColor(_selectedStatus),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${_filteredRecords.length} Attendance Records',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Attendance Records List
              _filteredRecords.isEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              color: AppColors.primary,
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Records Found',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attendance records match your current filters.',
                            style: AppTextStyles.bodyText,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = _filteredRecords[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(
                                  record.status,
                                ).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    record.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    '${record.date.day}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: _getStatusColor(record.status),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.studentName,
                                      style: AppTextStyles.activityTitle,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              record.status,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          record.status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getStatusColor(
                                              record.status,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${record.date.day}/${record.date.month}/${record.date.year}',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Check-in: ${record.checkInTime} • ${record.duration}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AttendanceRecord {
  final DateTime date;
  final String status;
  final String studentName;
  final String checkInTime;
  final String duration;

  AttendanceRecord({
    required this.date,
    required this.status,
    required this.studentName,
    required this.checkInTime,
    required this.duration,
  });
}

class RecordingVideo {
  final String title;
  final String thumbnail;
  final String uploadedBy;
  final DateTime uploadedDate;
  final String duration;
  final int views;

  RecordingVideo({
    required this.title,
    required this.thumbnail,
    required this.uploadedBy,
    required this.uploadedDate,
    required this.duration,
    required this.views,
  });
}
