import 'package:flutter/material.dart';
import 'dart:ui';

// Import your screens here
import 'package:luminar_std/presentation/attandance_screen/attandance_screen.dart';
import 'package:luminar_std/presentation/live_class/live_class.dart';
import 'package:luminar_std/presentation/payment_screen/payment_screen.dart';
import 'package:luminar_std/presentation/recorder_video_screen/recorder_video_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<MoreItem> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Navigation methods for each feature
  void _navigateToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(),
        settings: RouteSettings(
          arguments: {
            'title': 'Attendance',
            'course': 'Asp.net MVC with Angular',
            'batch': 'ggf',
          },
        ),
      ),
    );
  }

  void _navigateToVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideosScreen(),
        settings: RouteSettings(
          arguments: {
            'title': 'Videos',
            'course': 'Asp.net MVC with Angular',
            'batch': 'ggf',
            'videoCount': 24,
            'newVideos': 12,
          },
        ),
      ),
    );
  }

  void _navigateToPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentsScreen(),
        settings: RouteSettings(
          arguments: {
            'title': 'Payments',
            'amount': '₹27,000',
            'lastPayment': 'Mar 12, 2026',
            'status': 'Paid',
          },
        ),
      ),
    );
  }

  void _navigateToLiveClass() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveClassScreen(),
        settings: RouteSettings(
          arguments: {
            'title': 'Live Class',
            'nextClass': 'Today 5:00 PM',
            'topic': 'ASP.NET MVC with Angular',
            'instructor': 'John Doe',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Simple Header without gradient and search
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      Text(
                        'Explore all features',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Main Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Quick Stats Row
                  // Removed as per your code, but keeping structure
                  SizedBox(height: 28),

                  // Section Title
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Attendance Card - Navigates to AttendanceScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.calendar_month,
                      title: 'Attendance',
                      subtitle: 'Track your daily attendance',
                      color: Color(0xFF6C5CE7),
                      badge: '85%',
                      stats: 'Present: 42 days',
                    ),
                    index: 0,
                    onTap: _navigateToAttendance,
                  ),

                  // Videos Card - Navigates to VideosScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.video_library_rounded,
                      title: 'Videos',
                      subtitle: 'Course recordings & lectures',
                      color: Color(0xFF00B894),
                      badge: '12 new',
                      stats: 'Total: 24 videos',
                    ),
                    index: 1,
                    onTap: _navigateToVideos,
                  ),

                  // Payments Card - Navigates to PaymentsScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.payment_rounded,
                      title: 'Payments',
                      subtitle: 'Fee details & transactions',
                      color: Color(0xFFFDCB6E),
                      badge: 'Paid',
                      stats: 'Last: Mar 12, 2026',
                    ),
                    index: 2,
                    onTap: _navigateToPayments,
                  ),

                  // Live Class Card - Navigates to LiveClassScreen
                  _buildMenuItem(
                    item: MoreItem(
                      icon: Icons.video_camera_front_rounded,
                      title: 'Live Class',
                      subtitle: 'Join ongoing sessions',
                      color: Color(0xFFFF7675),
                      badge: 'LIVE NOW',
                      stats: 'Next: Today 5:00 PM',
                    ),
                    index: 3,
                    onTap: _navigateToLiveClass,
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Function()? onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6C5CE7).withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Color(0xFF6C5CE7), size: 20),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3436),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required MoreItem item,
    required int index,
    required VoidCallback onTap, // Add onTap parameter
  }) {
    return FadeTransition(
      opacity: _animationController.drive(
        CurveTween(curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap, // Use the passed onTap function
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.color.withOpacity(0.2),
                          item.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  SizedBox(width: 16),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            SizedBox(width: 8),
                            if (item.badge.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.title == 'Live Class'
                                      ? Color(0xFFFF7675)
                                      : item.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.badge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.title == 'Live Class'
                                        ? Colors.white
                                        : item.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.stats,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFeatureDialog(MoreItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 50),
              ),
              SizedBox(height: 20),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3436),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This feature is coming soon!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening ${item.title}...'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Open'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String badge;
  final String stats;

  MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badge,
    required this.stats,
  });
}

// Example of how to receive data in destination screens:

// In your AttendanceScreen, you can receive data like this:
/*
class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get arguments passed from MoreScreen
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(args?['title'] ?? 'Attendance'),
      ),
      body: Container(
        // Your attendance screen UI
        child: Center(
          child: Text('Course: ${args?['course']}\nBatch: ${args?['batch']}'),
        ),
      ),
    );
  }
}
*/

// Similarly for other screens...
