import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class FullScreenNotificationService {
  static final FullScreenNotificationService _instance = FullScreenNotificationService._internal();
  factory FullScreenNotificationService() => _instance;
  FullScreenNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isRingingNotification = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the full-screen notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
      await _requestPermissions();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('🟢 Full-screen notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Failed to initialize full-screen notification service: $e');
      }
      rethrow;
    }
  }

  /// Initialize local notifications with full-screen intent
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create high priority notification channel for full-screen notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'full_screen_orders',
      'Full Screen Order Notifications',
      description: 'Full screen notifications for incoming orders',
      importance: Importance.max,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request system alert window permission for full-screen notifications
      final overlayPermission = await Permission.systemAlertWindow.request();
      if (kDebugMode) {
        print('📱 System alert window permission: $overlayPermission');
      }

      // Request notification permission
      final notificationPermission = await Permission.notification.request();
      if (kDebugMode) {
        print('📱 Notification permission: $notificationPermission');
      }

      // Request phone permission for accepting calls
      final phonePermission = await Permission.phone.request();
      if (kDebugMode) {
        print('📱 Phone permission: $phonePermission');
      }
    }
  }

  /// Show full-screen notification for new order
  Future<void> showFullScreenOrderNotification({
    required String orderId,
    required String customerName,
    required String serviceTitle,
    required double amount,
    required String bookingDate,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Start continuous ringing
      await _startNotificationSound();
      
      // Show full-screen notification
      await _showFullScreenNotification(
        orderId: orderId,
        customerName: customerName,
        serviceTitle: serviceTitle,
        amount: amount,
        bookingDate: bookingDate,
        additionalData: additionalData,
      );

      if (kDebugMode) {
        print('🔔 Full-screen notification shown for order: $orderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error showing full-screen notification: $e');
      }
    }
  }

  /// Show the actual full-screen notification
  Future<void> _showFullScreenNotification({
    required String orderId,
    required String customerName,
    required String serviceTitle,
    required double amount,
    required String bookingDate,
    Map<String, dynamic>? additionalData,
  }) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'full_screen_orders',
        'Full Screen Order Notifications',
        channelDescription: 'Full screen notifications for incoming orders',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        showWhen: true,
        when: null,
        usesChronometer: false,
        onlyAlertOnce: false,
        ongoing: false, // Changed to false so it can be dismissed
        autoCancel: true, // Changed to true so it auto-cancels when tapped
        enableVibration: true,
        enableLights: true,
        ledColor: Color.fromARGB(255, 0, 120, 215),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        // Remove custom sound for now to use default
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'view_order',
            'View Order',
            titleColor: Color.fromARGB(255, 0, 120, 215),
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
        // Add more properties to make it more likely to show full-screen
        timeoutAfter: 30000, // 30 seconds
        ticker: '🛍️ New Order Available!',
        subText: 'Tap to view order details',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        categoryIdentifier: 'order_category',
      ),
    );

    await _localNotifications.show(
      orderId.hashCode,
      '🛍️ New Order from $customerName',
      '$serviceTitle • ₹${amount.toStringAsFixed(0)}',
      platformChannelSpecifics,
      payload: orderId, // Simplified payload
    );
  }

  /// Start notification sound (continuous ringing)
  Future<void> _startNotificationSound() async {
    if (_isRingingNotification) return;

    _isRingingNotification = true;

    try {
      // Use system ringtone for maximum attention
      if (Platform.isAndroid) {
        FlutterRingtonePlayer().play(
          android: AndroidSounds.notification,
          ios: IosSounds.glass,
          looping: true,
          volume: 1.0,
          asAlarm: true,
        );
      }

      // Add vibration pattern
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [0, 1000, 500, 1000, 500, 1000],
          repeat: 0, // Repeat indefinitely
        );
      }

      // Also trigger system alert sound
      SystemSound.play(SystemSoundType.alert);

      if (kDebugMode) {
        print('🔊 Started notification ringing');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error starting notification sound: $e');
      }
    }
  }

  /// Stop notification sound
  Future<void> stopNotificationSound() async {
    if (!_isRingingNotification) return;

    _isRingingNotification = false;

    try {
      // Stop ringtone
      FlutterRingtonePlayer().stop();
      
      // Stop vibration
      Vibration.cancel();
      
      // Stop audio player
      await _audioPlayer.stop();

      if (kDebugMode) {
        print('🔇 Stopped notification ringing');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error stopping notification sound: $e');
      }
    }
  }

  /// Handle notification response (accept/decline)
  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    final orderId = payload; // Simplified - payload is just the order ID
    final action = response.actionId;

    // Stop ringing immediately when user interacts
    await stopNotificationSound();

    // Cancel the notification
    await _localNotifications.cancel(orderId.hashCode);

    if (kDebugMode) {
      print('🔔 Notification response: $action for order: $orderId');
    }

    // Handle the action
    switch (action) {
      case 'view_order':
        await _openOrderDetails(orderId);
        break;
      case 'accept_order':
        await _handleAcceptOrder(orderId);
        break;
      case 'decline_order':
        await _handleDeclineOrder(orderId);
        break;
      default:
        // Default tap - open the app to order details
        await _openOrderDetails(orderId);
        break;
    }
  }

  /// Handle accept order action
  Future<void> _handleAcceptOrder(String orderId) async {
    try {
      // Here you would call your booking service to accept the order
      // For now, we'll just print and potentially navigate
      if (kDebugMode) {
        print('✅ Accepting order: $orderId');
      }
      
      // You can emit an event or use a stream controller to notify the app
      _notifyOrderAction('accept', orderId);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error accepting order: $e');
      }
    }
  }

  /// Handle decline order action
  Future<void> _handleDeclineOrder(String orderId) async {
    try {
      if (kDebugMode) {
        print('❌ Declining order: $orderId');
      }
      
      // You can emit an event or use a stream controller to notify the app
      _notifyOrderAction('decline', orderId);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error declining order: $e');
      }
    }
  }

  /// Open order details
  Future<void> _openOrderDetails(String orderId) async {
    try {
      if (kDebugMode) {
        print('📱 Opening order details for: $orderId');
      }
      
      // Navigate to order details screen
      _notifyOrderAction('view', orderId);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error opening order details: $e');
      }
    }
  }

  /// Notify the app about order actions
  void _notifyOrderAction(String action, String orderId) {
    // This could be implemented using a stream controller
    // or by calling a global callback function
    // For now, we'll use a simple print statement
    if (kDebugMode) {
      print('📢 Order action: $action for order: $orderId');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    await stopNotificationSound();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(String orderId) async {
    await _localNotifications.cancel(orderId.hashCode);
    await stopNotificationSound();
  }

  /// Dispose the service
  Future<void> dispose() async {
    await stopNotificationSound();
    await _audioPlayer.dispose();
  }
}