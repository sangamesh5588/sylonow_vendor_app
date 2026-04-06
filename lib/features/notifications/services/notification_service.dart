import '../../../core/config/supabase_config.dart';
import '../models/notification.dart';

class NotificationService {
  static const String _tableName = 'vendor_notifications';

  Future<List<VendorNotification>> getNotifications({
    required String vendorId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
// TODO: Replace with proper logging - print('📱 Fetching notifications for vendor: $vendorId');
      
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

// TODO: Replace with proper logging - print('📱 Notifications query successful, found ${response.length} notifications');
      
      return response
          .map((json) => VendorNotification.fromJson(json))
          .toList();
    } catch (e) {
// Error print removed
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<List<VendorNotification>> getUnreadNotifications({
    required String vendorId,
  }) async {
    try {
// TODO: Replace with proper logging - print('📱 Fetching unread notifications for vendor: $vendorId');
      
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

// TODO: Replace with proper logging - print('📱 Unread notifications query successful, found ${response.length} unread notifications');
      
      return response
          .map((json) => VendorNotification.fromJson(json))
          .toList();
    } catch (e) {
// Error print removed
      throw Exception('Failed to load unread notifications: $e');
    }
  }

  Future<int> getUnreadCount({required String vendorId}) async {
    try {
// TODO: Replace with proper logging - print('📱 Getting unread count for vendor: $vendorId');
      
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('is_read', false);

      final count = response.length;
// TODO: Replace with proper logging - print('📱 Unread count: $count');
      
      return count;
    } catch (e) {
// Error print removed
      return 0;
    }
  }

  Future<bool> markAsRead({required String notificationId}) async {
    try {
// TODO: Replace with proper logging - print('📱 Marking notification as read: $notificationId');
      
      await SupabaseConfig.client
          .from(_tableName)
          .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

// Success print removed
      return true;
    } catch (e) {
// Error print removed
      return false;
    }
  }

  Future<bool> markAllAsRead({required String vendorId}) async {
    try {
// TODO: Replace with proper logging - print('📱 Marking all notifications as read for vendor: $vendorId');
      
      await SupabaseConfig.client
          .from(_tableName)
          .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('vendor_id', vendorId)
          .eq('is_read', false);

// Success print removed
      return true;
    } catch (e) {
// Error print removed
      return false;
    }
  }

  Future<bool> deleteNotification({required String notificationId}) async {
    try {
// TODO: Replace with proper logging - print('📱 Deleting notification: $notificationId');
      
      await SupabaseConfig.client
          .from(_tableName)
          .delete()
          .eq('id', notificationId);

// Success print removed
      return true;
    } catch (e) {
// Error print removed
      return false;
    }
  }

  Future<VendorNotification?> createNotification({
    required String vendorId,
    required String title,
    required String message,
    required String type,
    String? actionData,
    String? imageUrl,
  }) async {
    try {
// TODO: Replace with proper logging - print('📱 Creating notification for vendor: $vendorId');
// TODO: Replace with proper logging - print('📱 Notification type: $type, title: $title');
      
      final response = await SupabaseConfig.client
          .from(_tableName)
          .insert({
            'vendor_id': vendorId,
            'title': title,
            'message': message,
            'type': type,
            'action_data': actionData,
            'image_url': imageUrl,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

// Success print removed
      return VendorNotification.fromJson(response);
    } catch (e) {
// Error print removed
      return null;
    }
  }

  // Real-time subscription for new notifications
  Stream<List<VendorNotification>> subscribeToNotifications({
    required String vendorId,
  }) {
// TODO: Replace with proper logging - print('📱 Setting up real-time subscription for vendor notifications: $vendorId');
    
    return SupabaseConfig.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => VendorNotification.fromJson(json))
            .toList());
  }

  // Get notifications by type
  Future<List<VendorNotification>> getNotificationsByType({
    required String vendorId,
    required String type,
    int limit = 20,
  }) async {
    try {
// TODO: Replace with proper logging - print('📱 Fetching $type notifications for vendor: $vendorId');
      
      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('vendor_id', vendorId)
          .eq('type', type)
          .order('created_at', ascending: false)
          .limit(limit);

// TODO: Replace with proper logging - print('📱 Found ${response.length} $type notifications');
      
      return response
          .map((json) => VendorNotification.fromJson(json))
          .toList();
    } catch (e) {
// Error print removed
      throw Exception('Failed to load $type notifications: $e');
    }
  }
}