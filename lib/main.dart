import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart'; // Temporarily disabled
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/no_internet_widget.dart';
import 'core/config/router_config.dart';
import 'core/config/supabase_config.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/firebase_analytics_service.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preserve the splash screen while initializing
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize OneSignal with error handling - TEMPORARILY DISABLED
  // try {
  //   // Enable verbose logging for debugging (remove in production)
  //   OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  //   // Initialize with your OneSignal App ID
  //   OneSignal.initialize("49c2960f-3ac3-4542-9348-dd1248a273f3");
  //   // Use this method to prompt for push notifications.
  //   // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
  //   OneSignal.Notifications.requestPermission(true);
  // } catch (e) {
  // // Warning print removed
  // }

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Continue without .env file - will use fallback values
  }

  try {
    // Initialize Firebase with proper configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Cloud Messaging
    await FCMService.initialize();
  } catch (e) {
    // Continue without Firebase for now
  }

  try {
    // Initialize Supabase using the config class
    await SupabaseConfig.initialize();
    // Skip eager connectivity test on startup to reduce boot latency.
    // It can be triggered manually from diagnostics screens if needed.
  } catch (e) {
// Error print removed
// Warning print removed

    // Show a user-friendly error dialog if needed
    // For now, we'll let the app continue and handle errors at the feature level
  }

  try {
    // Initialize Google Auth Service
    unawaited(GoogleAuthService().initialize());
  } catch (e) {
// Warning print removed
  }

  try {
    // Initialize Firebase Analytics
    FirebaseAnalyticsService().initialize();
  } catch (e) {
// Warning print removed
  }

  // Clean up old temporary files
  unawaited(_cleanupOldTempFiles());

  // Remove the native splash screen after initialization
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: MyApp()));
}

/// Clean up old temporary image files on app startup
Future<void> _cleanupOldTempFiles() async {
  try {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory tempImagesDir =
        Directory(path.join(appDir.path, 'temp_images'));

    if (await tempImagesDir.exists()) {
      final List<FileSystemEntity> files = tempImagesDir.listSync();
      final DateTime cutoffTime =
          DateTime.now().subtract(const Duration(days: 1));

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            try {
              await file.delete();
            } catch (e) {
// Warning print removed
            }
          }
        }
      }
    }
  } catch (e) {
// Warning print removed
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return NoInternetWidget(
      child: MaterialApp.router(
        title: 'SyloNow Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
