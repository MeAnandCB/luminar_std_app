import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/attandance_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/forgot_password/controller/forgot_password.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/controller/bottom_nav_controller.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/splash_screen/splash_screen.dart';
import 'package:luminar_std/repository/attandance_screen/service.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [Permission.storage, Permission.photos].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),

        // Auth Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordController()),

        // Dashboard/Home Providers
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),

        // Feature Providers
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),

        // Attendance Service (Provider but not ChangeNotifier)
        Provider<AttendanceService>(create: (_) => AttendanceService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: context.watch<ThemeProvider>().themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
