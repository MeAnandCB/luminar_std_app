import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/auth_screens/forgot_password/controller/forgot_password.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/controller/bottom_nav_controller.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/home_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/message_screen/controller/controller/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/gallery_details_screen/controller/gallery_details_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_screen/controller/gallery_screen_controller.dart';
import 'package:luminar_std/presentation/live_class/controller/live_class_controller.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/splash_screen/splash_screen.dart';
import 'package:luminar_std/repository/attandance_screen/service.dart';
import 'package:luminar_std/repository/message_screen/service/message_service.dart';
import 'package:luminar_std/repository/message_screen/websocket/web_socket_data.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
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
    print('Token loaded in main: ${accessToken != null ? 'Yes' : 'No'}');
    if (accessToken != null) {
      print('Token preview: ${accessToken.substring(0, 10)}...');
    }
  } catch (e) {
    print('Error loading token in main: $e');
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
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),

        // Attendance Service (Provider but not ChangeNotifier)
        Provider<AttendanceService>(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => FolderBrowserProvider()),
        ChangeNotifierProvider(create: (_) => LiveClassController()),

        // Existing ChatProvider from your codebase
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            apiService: MessageApiService(),
            webSocketService: WebSocketService(),
          ),
        ),
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

          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
