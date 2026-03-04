// import 'package:avatar_glow/avatar_glow.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:luminar_std/core/theme/app_text_styles.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<Map<String, dynamic>> activityList = [
//     {
//       "title": "Profile and User Information Updated",
//       "description": "Updated fields: user.whatsapp_number",
//       "time": "2026-03-02T08:00:15.726945Z",
//       "performed_by": "MBtest",
//     },
//     {
//       "title": "New Course Enrollment",
//       "description": "User enrolled in Flutter Advanced Course",
//       "time": "2026-03-01T10:22:30.123456Z",
//       "performed_by": "AdminUser",
//     },
//     {
//       "title": "Payment Successful",
//       "description": "Course fee payment of ₹15,000 completed",
//       "time": "2026-02-28T14:45:50.654321Z",
//       "performed_by": "System",
//     },
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 buildHeader(),
//                 const SizedBox(height: 20),
//                 buildInsuranceCard(),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Welcome Back",
//                   style: AppTextStyles.bodyLarge.copyWith(
//                     fontSize: 17,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // buildQuickActionExpansionTile(
//                 //         // icon: Icons.history,
//                 //         title: activityList[index]["title"] ?? "",
//                 //         sub: activityList[index]["description"] ?? "",
//                 //         price: activityList[index]["description"] ?? "",
//                 //         bgColor: Colors.orange.withOpacity(0.1),
//                 //         context: context, // Pass context for theming
//                 //       ),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: NeverScrollableScrollPhysics(),
//                   itemCount: activityList.length,
//                   itemBuilder: (context, index) =>
//                       buildQuickActionExpansionTile(
//                         icon: Icons.assignment_outlined,
//                         title: activityList[index]["title"] ?? "",
//                         sub: activityList[index]["description"] ?? "",
//                         time: activityList[index]["time"] ?? "",
//                         icon1: Icons.keyboard_arrow_down_rounded,
//                         bgColor: Colors.orange.withOpacity(0.1),
//                         context: context, // Pass context for theming
//                       ),
//                 ),

//                 Column(
//                   children: [
//                     /// HEADER
//                     const SizedBox(height: 20),

//                     /// GRID CARDS
//                     GridView.count(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisCount: 2,
//                       mainAxisSpacing: 16,
//                       crossAxisSpacing: 16,
//                       childAspectRatio:
//                           MediaQuery.of(context).size.width / 2 / 100,
//                       children: [
//                         statCard(
//                           "Health Score",
//                           "87",

//                           const Color(0xffE6DDF4),
//                           icon: Icons.lock,
//                         ),

//                         statCard(
//                           "Sleep",
//                           "8:00 h",

//                           const Color(0xffDFF4F4),
//                           icon: Icons.nightlight,
//                         ),

//                         statCard(
//                           "Lungs Capacity",
//                           "4.76 L",

//                           const Color(0xffE1F4DF),
//                           icon: Icons.air,
//                         ),

//                         statCard(
//                           "Heart Rate",
//                           "87 bpm",

//                           const Color(0xffF6E0EA),
//                           icon: Icons.favorite,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildHeader() {
//     return Row(
//       children: [
//         const CircleAvatar(
//           radius: 25,
//           backgroundColor: Color(0xFF7B51FF),
//           child: CircleAvatar(
//             radius: 23,
//             backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a'),
//           ),
//         ),
//         const SizedBox(width: 12),
//         const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Hello 👋 ANAND!",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               "Welcome Back",
//               style: TextStyle(color: Colors.grey, fontSize: 14),
//             ),
//           ],
//         ),
//         const Spacer(),
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(shape: BoxShape.circle),
//           child: AvatarGlow(
//             glowColor: Colors.purple,
//             child: CircleAvatar(
//               backgroundColor: Colors.transparent,
//               child: Icon(
//                 Icons.notifications_active_outlined,
//                 color: Colors.purple,
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget buildInsuranceCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF8E66FF), Color(0xFF6B38FB)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.verified_user, color: Colors.white, size: 30),
//                   SizedBox(width: 10),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Course",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         "Flutter Mobile Apllication Development",
//                         style: TextStyle(color: Colors.white70),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.north_east,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Courses",
//                     style: TextStyle(color: Colors.white70, fontSize: 12),
//                   ),
//                   Text(
//                     "1",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 25,
//                     ),
//                   ),
//                 ],
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     "Pending Fees",
//                     style: TextStyle(color: Colors.white70, fontSize: 12),
//                   ),
//                   Text(
//                     "₹59000",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 25,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           Text(
//             "Progress",
//             style: TextStyle(color: Colors.white70, fontSize: 12),
//           ),
//           SizedBox(height: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               SizedBox(
//                 width: double.infinity,
//                 child: LinearProgressIndicator(
//                   minHeight: 6,
//                   value: 0.7,
//                   backgroundColor: Colors.white24,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 248, 118, 31),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                 ),
//                 child: const Text("Continue Learning"),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildQuickActionExpansionTile({
//     required IconData icon,
//     required IconData icon1,
//     required String title,
//     required String sub,
//     required String time,
//     required Color bgColor,
//     required BuildContext context, // Passed in from the build method
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Theme(
//         // This removes the default divider lines that ExpansionTile adds
//         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//         child: ExpansionTile(
//           tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//           childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
//           leading: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: Colors.orange[800]),
//           ),
//           title: Text(
//             title,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//           ),
//           subtitle: Row(
//             children: [
//               const Text(
//                 "Date : ",
//                 style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
//               ),
//               Text(
//                 DateFormat(
//                   'dd MMM yyyy',
//                 ).format(DateTime.parse(time).toLocal()),
//                 style: const TextStyle(color: Colors.grey, fontSize: 12),
//               ),
//             ],
//           ),
//           trailing: Icon(icon1, color: Colors.orange[800]),
//           children: [
//             // Add your expanded content here
//             const Divider(height: 1),
//             const SizedBox(height: 10),
//             Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
//           ],
//         ),
//       ),
//     );
//   }

//   /// STAT CARD WIDGET
//   Widget statCard(
//     String title,
//     String subtitle,
//     Color color, {
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           ),
//           Text(
//             subtitle,
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildCourseCard(),
            const SizedBox(height: 24),
            _buildQuickStatsGrid(),

            const SizedBox(height: 24),
            _buildSectionTitle("Recent Activities"),
            const SizedBox(height: 12),
            _buildActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Status: Active",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              "Total Fees",
              "₹29,000",
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            _buildStatCard("Paid", "₹1,000", Icons.check_circle, Colors.green),
            _buildStatCard(
              "Pending",
              "₹28,000",
              Icons.pending_actions,
              Colors.orange,
            ),
            _buildStatCard("Progress", "3.45%", Icons.speed, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildCourseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CURRENT ENROLLMENT",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Asp.net MVC with Angular - Full Stack",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseInfoItem("Batch", "ggf"),
              _buildCourseInfoItem("Starts", "Mar 12, 2026"),
              _buildCourseInfoItem("Mode", "Hybrid"),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            child: LinearProgressIndicator(
              minHeight: 8,
              value: 0.345,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActivityList() {
    // Mimicking the JSON's 'recent_activities'
    final activities = [
      {
        "title": "Profile Updated",
        "desc": "WhatsApp number changed",
        "time": "1 day ago",
        "icon": Icons.person_outline,
      },
      {
        "title": "Receipt Generated",
        "desc": "ADM2026030001 - ₹1000",
        "time": "1 day ago",
        "icon": Icons.receipt_long,
      },
      {
        "title": "Payment Received",
        "desc": "Manual payment of ₹1000",
        "time": "1 day ago",
        "icon": Icons.payment,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = activities[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(
                item['icon'] as IconData,
                color: Colors.blue,
                size: 20,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item['desc'] as String),
            trailing: Text(
              item['time'] as String,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFF7B51FF),
          child: CircleAvatar(
            radius: 23,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a'),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello 👋 ANAND!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Welcome Back",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: AvatarGlow(
            glowColor: Colors.purple,
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.notifications_active_outlined,
                color: Colors.purple,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
