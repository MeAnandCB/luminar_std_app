import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/auth_screens/forgot_password/controller/forgot_password.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/controller/bottom_nav_controller.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/controller/chat_list_screen_controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/gallery_details_screen/controller/gallery_details_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_screen/controller/gallery_screen_controller.dart';
import 'package:luminar_std/presentation/live_class/controller/live_class_controller.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/complete_your_profile/controller/complete_profile_controller.dart';
import 'package:luminar_std/presentation/splash_screen/splash_screen.dart';
import 'package:luminar_std/repository/attandance_screen/service.dart';

import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'package:luminar_std/core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [Permission.storage, Permission.photos].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();

  // Pre-load token for chat service
  String? accessToken;
  try {
    accessToken = await AppUtils.getAccessKey();
    LoggerUtils.info('Token loaded in main: ${accessToken != null ? 'Yes' : 'No'}', tag: 'Main');
    if (accessToken != null) {
      LoggerUtils.info('Token preview: ${accessToken.substring(0, 10)}...', tag: 'Main');
    }
  } catch (e) {
    LoggerUtils.error('Error loading token in main: $e', tag: 'Main');
  }

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
        ChangeNotifierProvider(create: (_) => CompleteProfileController()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),

        // Attendance Service (Provider but not ChangeNotifier)
        Provider<AttendanceService>(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => FolderBrowserProvider()),
        ChangeNotifierProvider(create: (_) => LiveClassController()),

        // Existing ChatProvider from your codebase
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
          title: 'Luminar Student App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
