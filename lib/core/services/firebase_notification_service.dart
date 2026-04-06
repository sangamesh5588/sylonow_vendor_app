import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/supabase_config.dart';
import '../../firebase_options.dart';
import 'full_screen_notification_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
// TODO: Replace with proper logging - print('🔔 Background message received: ${message.messageId}');
  
  // Show full-screen notification for ALL background messages
  final fullScreenService = FullScreenNotificationService();
  await fullScreenService.initialize();
  
  await fullScreenService.showFullScreenOrderNotification(
    orderId: message.data['booking_id'] ?? message.data['order_id'] ?? message.messageId ?? '',
    customerName: message.data['customer_name'] ?? message.notification?.title ?? 'Notification',
    serviceTitle: message.data['service_name'] ?? message.notification?.body ?? 'Update',
    amount: double.tryParse(message.data['amount'] ?? '0') ?? 0.0,
    bookingDate: message.data['booking_date'] ?? DateTime.now().toString(),
    additionalData: message.data,
  );
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FullScreenNotificationService fullScreenService = FullScreenNotificationService();
  late FirebaseMessaging _firebaseMessaging;
  
  bool _isInitialized = false;
  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase if not already initialized
  Future<void> _ensureFirebaseInitialized() async {
    if (_isFirebaseInitialized) return;
    
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;
// TODO: Replace with proper logging - print('🟢 Firebase initialized successfully in notification service');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Firebase initialization failed in notification service: $e');
      throw Exception('Firebase initialization failed: $e');
    }
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
// TODO: Replace with proper logging - print('🔔 Initializing Firebase notification service...');
      
      // Ensure Firebase is initialized first
      await _ensureFirebaseInitialized();
      
      // Request notification permissions
      await _requestNotificationPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize full-screen notification service
      await fullScreenService.initialize();
      
      // Initialize FCM
      await _initializeFCM();
      
      // Message handlers are set up in _initializeFCM method
      
      _isInitialized = true;
// TODO: Replace with proper logging - print('🟢 Firebase notification service initialized successfully');
      
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Failed to initialize Firebase notification service: $e');
      rethrow;
    }
  }

  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    try {
      // Request system notification permissions (Android 13+)
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
// TODO: Replace with proper logging - print('📱 System notification permission: $status');
      }
      
      // Request FCM permissions for iOS
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
// TODO: Replace with proper logging - print('📱 iOS FCM permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error requesting permissions: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

// TODO: Replace with proper logging - print('📱 Local notifications initialized');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error initializing local notifications: $e');
    }
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Full-screen notifications channel - highest priority for all FCM messages
      const AndroidNotificationChannel fullScreenChannel = AndroidNotificationChannel(
        'full_screen_fcm',
        'Full Screen FCM Notifications',
        description: 'Full screen notifications for all FCM messages',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        showBadge: true,
      );

      // Legacy channels for backward compatibility (though we'll use full-screen for everything)
      const AndroidNotificationChannel newOrdersChannel = AndroidNotificationChannel(
        'new_orders_channel',
        'New Orders',
        description: 'Notifications for new orders',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        showBadge: true,
      );

      const AndroidNotificationChannel orderUpdatesChannel = AndroidNotificationChannel(
        'order_updates_channel',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(fullScreenChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(newOrdersChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(orderUpdatesChannel);
    }
  }

  // Initialize FCM
  Future<void> _initializeFCM() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
// TODO: Replace with proper logging - print('🔑 FCM Token: $_fcmToken');
      
      // Update token in database
      if (_fcmToken != null) {
        await _updateFCMTokenInDatabase(_fcmToken!);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
// TODO: Replace with proper logging - print('🔄 FCM Token refreshed: $token');
        _updateFCMTokenInDatabase(token);
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
// TODO: Replace with proper logging - print('🟢 FCM initialized successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error initializing FCM: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
// TODO: Replace with proper logging - print('🔔 Foreground message received: ${message.messageId}');
// TODO: Replace with proper logging - print('📄 Message data: ${message.data}');
    
    // Show full-screen notification for ALL foreground messages
    fullScreenService.showFullScreenOrderNotification(
      orderId: message.data['booking_id'] ?? message.data['order_id'] ?? message.messageId ?? '',
      customerName: message.data['customer_name'] ?? message.notification?.title ?? 'Notification',
      serviceTitle: message.data['service_name'] ?? message.notification?.body ?? 'Update',
      amount: double.tryParse(message.data['amount'] ?? '0') ?? 0.0,
      bookingDate: message.data['booking_date'] ?? DateTime.now().toString(),
      additionalData: message.data,
    );
  }

  // Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message) {
// TODO: Replace with proper logging - print('🔔 FCM notification tapped: ${message.messageId}');
    _handleNotificationNavigation(message.data['type'], message.data);
  }

  // Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
// TODO: Replace with proper logging - print('📱 Local notification tapped: ${response.id}');
// TODO: Replace with proper logging - print('📄 Payload: ${response.payload}');
    
    if (response.payload != null) {
      final parts = response.payload!.split(':');
      if (parts.length >= 2) {
        final type = parts[0];
        final id = parts[1];
        // Handle both booking and order types
        if (type.contains('booking')) {
          _handleNotificationNavigation(type, {'booking_id': id});
        } else {
          _handleNotificationNavigation(type, {'order_id': id});
        }
      }
    }
  }

  // Handle notification navigation
  void _handleNotificationNavigation(String? type, Map<String, dynamic> data) {
    if (type == null) return;
    
    try {
      switch (type) {
        case 'new_booking':
        case 'new_order':
// TODO: Replace with proper logging - print('🔄 Navigating to orders screen for new booking: ${data['booking_id'] ?? data['order_id']}');
          // TODO: Implement navigation using go_router
          // context.go('/orders', extra: {'highlight': data['booking_id'] ?? data['order_id']});
          break;
        case 'booking_update':
        case 'order_update':
// TODO: Replace with proper logging - print('🔄 Navigating to booking details: ${data['booking_id'] ?? data['order_id']}');
          // TODO: Implement navigation using go_router
          // context.go('/orders/${data['booking_id'] ?? data['order_id']}');
          break;
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error handling notification navigation: $e');
    }
  }

  // Show full-screen notification for new booking (now uses full-screen by default)
  Future<void> showNewBookingNotification({
    required String bookingId,
    required String customerName,
    required String serviceName,
    required double amount,
  }) async {
    try {
      // Use full-screen notification service for all new bookings
      await fullScreenService.showFullScreenOrderNotification(
        orderId: bookingId,
        customerName: customerName,
        serviceTitle: serviceName,
        amount: amount,
        bookingDate: DateTime.now().toString(),
        additionalData: {
          'type': 'new_booking',
          'booking_id': bookingId,
          'customer_name': customerName,
          'service_name': serviceName,
          'amount': amount.toString(),
        },
      );

// TODO: Replace with proper logging - print('🟢 Full-screen booking notification shown for booking: $bookingId');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error showing new order notification: $e');
    }
  }

  // Show booking status update notification (now uses full-screen by default)
  Future<void> showBookingUpdateNotification({
    required String bookingId,
    required String status,
    required String customerName,
    required String serviceName,
  }) async {
    try {
      String title = '';
      String body = '';
      
      switch (status.toLowerCase()) {
        case 'confirmed':
          title = '✅ Order Confirmed';
          body = 'Your booking with $customerName for $serviceName has been confirmed';
          break;
        case 'cancelled':
          title = '❌ Order Cancelled';
          body = 'Booking with $customerName for $serviceName has been cancelled';
          break;
        case 'completed':
          title = '🎉 Order Completed';
          body = 'Service completed for $customerName. Please collect payment';
          break;
        case 'in_progress':
          title = '🔄 Service Started';
          body = 'Service for $customerName has started. Good luck!';
          break;
        default:
          title = '📋 Order Update';
          body = 'Status updated to $status for $customerName';
      }

      // Use full-screen notification service for all booking updates
      await fullScreenService.showFullScreenOrderNotification(
        orderId: bookingId,
        customerName: title, // Use status title as customer name for updates
        serviceTitle: body, // Use body as service title
        amount: 0.0, // No amount for updates
        bookingDate: DateTime.now().toString(),
        additionalData: {
          'type': 'booking_update',
          'booking_id': bookingId,
          'status': status,
          'customer_name': customerName,
          'service_name': serviceName,
        },
      );

// TODO: Replace with proper logging - print('🟢 Full-screen booking update notification shown for booking: $bookingId');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error showing order update notification: $e');
    }
  }

  // Update FCM token in database
  Future<void> _updateFCMTokenInDatabase(String token) async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      
      if (user != null) {
        // Update the vendor's FCM token
        await client
            .from('vendors')
            .update({'fcm_token': token})
            .eq('auth_user_id', user.id);
        
// TODO: Replace with proper logging - print('🟢 FCM token updated in database');
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error updating FCM token: $e');
      // If column doesn't exist, we'll handle it gracefully
    }
  }

  // Show full-screen notification for any FCM message (main method)
  Future<void> showFullScreenNotificationFromFCM({
    required String title,
    required String body,
    String? orderId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await fullScreenService.showFullScreenOrderNotification(
        orderId: orderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: title,
        serviceTitle: body,
        amount: double.tryParse(data?['amount'] ?? '0') ?? 0.0,
        bookingDate: DateTime.now().toString(),
        additionalData: data ?? {},
      );
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error showing full-screen FCM notification: $e');
    }
  }

  // Send test notification (now full-screen by default)
  Future<void> sendTestNotification() async {
    await showNewBookingNotification(
      bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
      customerName: 'John Doe',
      serviceName: 'Event Photography',
      amount: 5000.0,
    );
  }

  // Get notification settings
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    }
    return true; // iOS handles this differently
  }

  // Request notification permissions if not granted
  Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Clear specific notification
  Future<void> clearNotification(String bookingId) async {
    await _localNotifications.cancel(bookingId.hashCode);
    await _localNotifications.cancel(bookingId.hashCode + 1000);
    await fullScreenService.cancelNotification(bookingId);
  }

  // Stop notification sound
  Future<void> stopNotificationSound() async {
    await fullScreenService.stopNotificationSound();
  }

  // Cancel all full-screen notifications
  Future<void> cancelAllFullScreenNotifications() async {
    await fullScreenService.cancelAllNotifications();
  }

  // Get access to full-screen notification service
  FullScreenNotificationService get fullScreenNotificationService => fullScreenService;


} 