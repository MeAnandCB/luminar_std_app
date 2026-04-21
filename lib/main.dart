import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:luminar_std/core/services/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/firebase_options.dart';
import 'package:luminar_std/presentation/attandance_screen/controller/attandance_controller.dart';
import 'package:luminar_std/presentation/auth_screens/forgot_password/controller/forgot_password.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/bottom_nav_screen/controller/bottom_nav_controller.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'package:luminar_std/presentation/enrollment_screen/controller/controller.dart';
import 'package:luminar_std/presentation/gallery_details_screen/controller/gallery_details_screen_controller.dart';
import 'package:luminar_std/presentation/gallery_screen/controller/gallery_screen_controller.dart';
import 'package:luminar_std/presentation/live_class/controller/live_class_controller.dart';
import 'package:luminar_std/presentation/profile_screen/controller.dart';
import 'package:luminar_std/presentation/complete_your_profile/controller/complete_profile_controller.dart';
import 'package:luminar_std/presentation/nactet_registration/controller/nactet_registration_controller.dart';
import 'package:luminar_std/presentation/splash_screen/splash_screen.dart';
import 'package:luminar_std/repository/FCM/fcm_service.dart';
import 'package:luminar_std/repository/attandance_screen/service.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'package:luminar_std/core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait; video player overrides this when entering fullscreen
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Safe Firebase init
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    LoggerUtils.info('✅ Firebase initialized', tag: 'Main');
  } catch (e) {
    LoggerUtils.error('❌ Firebase init failed: $e', tag: 'Main');
  }



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

  // Safe FCM init
  try {
    await FCMService().initialize();
    LoggerUtils.info('✅ FCM initialized', tag: 'Main');
  } catch (e) {
    LoggerUtils.error('❌ FCM init failed: $e', tag: 'Main');
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

        // Attendance Service
        Provider<AttendanceService1>(create: (_) => AttendanceService1()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => FolderBrowserProvider()),
        ChangeNotifierProvider(create: (_) => LiveClassController()),

        // Chat Provider
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NactetRegistrationController()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _dialogShowing = false;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    // Initial check after first frame so navigatorKey is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 2. Connectivity check
      final results = await Connectivity().checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) {
        _showNoInternetDialog();
      } else {
        // 3. Version check (only when online)
        final newVersion = await AppUpdateService.checkForUpdate();
        if (newVersion != null && mounted) {
          _showUpdateDialog(newVersion);
        }
      }
    });
    // Listen for changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline && !_dialogShowing) {
        _showNoInternetDialog();
      } else if (!offline && _dialogShowing) {
        _dismissDialog();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _showNoInternetDialog() {
    if (!AppUtils.appReady) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    _dialogShowing = true;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Internet Connection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please check your Wi-Fi or mobile data.\nThe app will continue automatically once you\'re back online.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }

  void _dismissDialog() {
    navigatorKey.currentState?.pop();
  }

  void _showUpdateDialog(String newVersion) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.system_update_rounded, size: 48, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Update Available',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Version $newVersion is available. Please update to get the latest features and improvements.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(AppUpdateService.storeUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Update Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Later', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
          builder: (context, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        );
      },
    );
  }
}
