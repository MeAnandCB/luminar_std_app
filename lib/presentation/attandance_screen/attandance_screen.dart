import 'package:flutter/material.dart';

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
    _generateDummyData();
  }

  void _generateDummyData() {
    // Generate 50 days of dummy attendance data with realistic values
    final now = DateTime.now();

    List<AttendanceRecord> records = [];

    // Student names for variety
    List<String> studentNames = [
      'Alice Johnson',
      'Bob Smith',
      'Carol Davis',
      'David Wilson',
      'Emma Brown',
      'Frank Miller',
      'Grace Lee',
      'Henry Garcia',
      'Ivy Chen',
      'Jack Thompson',
      'Karen White',
      'Leo Martinez',
      'Mona Lisa',
      'Nick Young',
      'Olivia Parker',
      'Peter Pan',
      'Quinn Fabray',
      'Rachel Green',
      'Sarah Connor',
      'Tom Holland',
    ];

    for (int i = 0; i < 50; i++) {
      final date = now.subtract(Duration(days: i));
      final status = _getWeightedRandomStatus();
      final checkInTime = status != 'Absent'
          ? '${8 + (i % 5)}:${i % 2 == 0 ? '00' : '30'} ${i % 3 == 0 ? 'AM' : 'AM'}'
          : '-';
      final duration = status != 'Absent'
          ? '${1 + (i % 4)}h ${(i * 7) % 60}m'
          : '-';

      records.add(
        AttendanceRecord(
          date: date,
          status: status,
          studentName: studentNames[i % studentNames.length],
          checkInTime: checkInTime,
          duration: duration,
        ),
      );
    }

    _allRecords = records;
    _applyFilters();
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
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D3436),
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
    }
  }

  void _applyFiltersAction() {
    _applyFilters();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filters applied successfully'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
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
        return Color(0xFF00B894);
      case 'Offline':
        return Colors.grey;
      case 'Recording':
        return Color(0xFFFDCB6E);
      case 'Absent':
        return Color(0xFFFF7675);
      default:
        return Color(0xFF6C5CE7);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'dd/mm/yyyy';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C5CE7).withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Attendance Record',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ],
                ),
              ),

              // Course Info Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6C5CE7).withOpacity(0.08),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6C5CE7).withOpacity(0.2),
                            Color(0xFF8B7BF2).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asp.net MVC with Angular',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Full Stack • ggf',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Legend Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Online', Color(0xFF00B894)),
                        _buildLegendItem('Offline', Colors.grey),
                        _buildLegendItem('Recording', Color(0xFFFDCB6E)),
                        _buildLegendItem('Absent', Color(0xFFFF7675)),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      'Total',
                      _stats['total'].toString(),
                      Color(0xFF6C5CE7),
                      Icons.people_rounded,
                    ),
                    _buildStatCard(
                      'Online',
                      _stats['online'].toString(),
                      Color(0xFF00B894),
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
                      Color(0xFFFDCB6E),
                      Icons.videocam_rounded,
                    ),
                    _buildStatCard(
                      'Absent',
                      _stats['absent'].toString(),
                      Color(0xFFFF7675),
                      Icons.person_off_rounded,
                    ),
                    _buildStatCard(
                      'Present',
                      _stats['present'].toString(),
                      Color(0xFF6C5CE7),
                      Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Filters Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6C5CE7).withOpacity(0.05),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filters Title
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Start Date and End Date Row
                    Row(
                      children: [
                        // Start Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context, true),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF1F3FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(_startDate),
                                        style: TextStyle(
                                          color: _startDate == null
                                              ? Colors.grey[500]
                                              : Color(0xFF2D3436),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFF6C5CE7),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // End Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context, false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF1F3FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(_endDate),
                                        style: TextStyle(
                                          color: _endDate == null
                                              ? Colors.grey[500]
                                              : Color(0xFF2D3436),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFF6C5CE7),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Status Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F3FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Color(0xFF6C5CE7),
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
                                        SizedBox(width: 8),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: status == 'All Status'
                                              ? Colors.grey[600]
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
                                  _selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Apply Filters and Clear buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFiltersAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6C5CE7),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF6C5CE7),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: Color(0xFF6C5CE7).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Results count
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${_filteredRecords.length} Records Found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Records List
              _filteredRecords.isEmpty
                  ? Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C5CE7).withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Color(0xFF6C5CE7).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              color: Color(0xFF6C5CE7),
                              size: 64,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'No Records Found',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No attendance records match your current filters.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = _filteredRecords[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(
                                  record.status,
                                ).withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
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
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.studentName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2D3436),
                                      ),
                                    ),
                                    SizedBox(height: 4),
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
                                        SizedBox(width: 6),
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
                                        SizedBox(width: 12),
                                        Text(
                                          '${record.date.day}/${record.date.month}/${record.date.year}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Check-in: ${record.checkInTime} • ${record.duration}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              SizedBox(height: 16),

              SizedBox(height: 20),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
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
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF2D3436),
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
