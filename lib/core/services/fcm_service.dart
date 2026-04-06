import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  static FirebaseMessaging? _messaging;
  static String? _currentToken;

  static FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  static Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission for iOS
      if (Platform.isIOS) {
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (kDebugMode) {
          print('FCM Permission granted: ${settings.authorizationStatus}');
        }
      }

      // Get the token
      await _refreshToken();

      // Listen to token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        if (kDebugMode) {
          print('🔄 FCM Token refreshed: $newToken');
        }
      });

      if (kDebugMode) {
        print('✅ FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM Service initialization failed: $e');
      }
    }
  }

  static Future<String?> getToken() async {
    try {
      if (_currentToken == null) {
        await _refreshToken();
      }
      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get FCM token: $e');
      }
      return null;
    }
  }

  static Future<void> _refreshToken() async {
    try {
      _currentToken = await messaging.getToken();
      if (kDebugMode) {
        print('🔑 FCM Token: $_currentToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to refresh FCM token: $e');
      }
    }
  }

  static Future<bool> upsertTokenToVendor(String vendorId) async {
    try {
      final token = await getToken();
      if (token == null) {
        if (kDebugMode) {
          print('⚠️ No FCM token available for vendor: $vendorId');
        }
        return false;
      }

      final supabase = Supabase.instance.client;
      
      // Upsert the FCM token to the vendors table
      await supabase
          .from('vendors')
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      if (kDebugMode) {
        print('✅ FCM token upserted successfully for vendor: $vendorId');
        print('🔑 Token: ${token.substring(0, 20)}...');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to upsert FCM token for vendor $vendorId: $e');
      }
      return false;
    }
  }

  static Future<bool> removeTokenFromVendor(String vendorId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Remove the FCM token from the vendors table
      await supabase
          .from('vendors')
          .update({
            'fcm_token': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      if (kDebugMode) {
        print('✅ FCM token removed successfully for vendor: $vendorId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove FCM token for vendor $vendorId: $e');
      }
      return false;
    }
  }

  static Future<void> deleteToken() async {
    try {
      await messaging.deleteToken();
      _currentToken = null;
      if (kDebugMode) {
        print('🗑️ FCM token deleted locally');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete FCM token: $e');
      }
    }
  }
}