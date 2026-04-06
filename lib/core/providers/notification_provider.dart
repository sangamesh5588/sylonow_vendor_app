import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/notification_service.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  late final NotificationService _notificationService;

  @override
  Future<bool> build() async { 
    _notificationService = NotificationService();
    
    try {
// TODO: Replace with proper logging - print('Initializing notification provider...'); // Debug log
      await _notificationService.initialize();
// TODO: Replace with proper logging - print('Notification provider initialized successfully'); // Debug log
      return true;
    } catch (e) {
// TODO: Replace with proper logging - print('Error initializing notification provider: $e'); // Debug log
      return false;
    }
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
    } catch (e) {
// TODO: Replace with proper logging - print('Error sending test notification: $e'); // Debug log
    }
  }
} 