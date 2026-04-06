import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/firebase_notification_service.dart';

part 'firebase_notification_provider.g.dart';

@riverpod
class FirebaseNotificationNotifier extends _$FirebaseNotificationNotifier {
  late final FirebaseNotificationService _notificationService;

  @override
  Future<bool> build() async {
    _notificationService = FirebaseNotificationService();
    
    try {
// TODO: Replace with proper logging - print('🔔 Initializing Firebase notification provider...');
      await _notificationService.initialize();
// TODO: Replace with proper logging - print('🟢 Firebase notification provider initialized successfully');
      return true;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error initializing Firebase notification provider: $e');
      return false;
    }
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error sending test notification: $e');
    }
  }

  // Get FCM token
  String? get fcmToken => _notificationService.fcmToken;

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    return await _notificationService.requestNotificationPermissions();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
  }

  // Clear specific notification
  Future<void> clearNotification(String bookingId) async {
    await _notificationService.clearNotification(bookingId);
  }

  // Show new booking notification manually (for testing)
  Future<void> showNewBookingNotification({
    required String bookingId,
    required String customerName,
    required String serviceName,
    required double amount,
  }) async {
    await _notificationService.showNewBookingNotification(
      bookingId: bookingId,
      customerName: customerName,
      serviceName: serviceName,
      amount: amount,
    );
  }

  // Show booking update notification manually (for testing)
  Future<void> showBookingUpdateNotification({
    required String bookingId,
    required String status,
    required String customerName,
    required String serviceName,
  }) async {
    await _notificationService.showBookingUpdateNotification(
      bookingId: bookingId,
      status: status,
      customerName: customerName,
      serviceName: serviceName,
    );
  }

  // Show full-screen order notification manually (for testing)
  Future<void> showFullScreenOrderNotification({
    required String orderId,
    required String customerName,
    required String serviceTitle,
    required double amount,
    required String bookingDate,
    Map<String, dynamic>? additionalData,
  }) async {
    await _notificationService.fullScreenService.showFullScreenOrderNotification(
      orderId: orderId,
      customerName: customerName,
      serviceTitle: serviceTitle,
      amount: amount,
      bookingDate: bookingDate,
      additionalData: additionalData,
    );
  }

  // Stop notification sounds
  Future<void> stopNotificationSound() async {
    await _notificationService.fullScreenService.stopNotificationSound();
  }

  // Cancel all notifications including full-screen
  Future<void> cancelAllFullScreenNotifications() async {
    await _notificationService.fullScreenService.cancelAllNotifications();
  }
} 