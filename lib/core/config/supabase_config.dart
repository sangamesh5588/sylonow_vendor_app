import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseConfig has not been initialized. Call SupabaseConfig.initialize() first.',
      );
    }
    return _client!;
  }
  
  static bool get isInitialized => _isInitialized;
  
  // Debug method to test Supabase connection
  static Future<bool> testConnection() async {
    try {
      if (!_isInitialized) {
// TODO: Replace with proper logging - print('🔴 Supabase not initialized');
        return false;
      }
      
      // Test a simple query to verify connection
      await _client!.from('vendors').select('count').limit(1);
// TODO: Replace with proper logging - print('🟢 Supabase connection test successful');
      return true;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Supabase connection test failed: $e');
      return false;
    }
  }
  
  static Future<void> initialize() async {
    try {
// TODO: Replace with proper logging - print('Initializing Supabase...'); // Debug log
      
      // Check if already initialized and working
      if (_isInitialized && _client != null) {
// TODO: Replace with proper logging - print('Supabase already initialized, skipping...'); // Debug log
        return;
      }
      
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Supabase URL or Anon Key not found in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // Use PKCE flow instead of implicit for better Google integration
        ),
      );
      
      _client = Supabase.instance.client;
      _isInitialized = true;
// TODO: Replace with proper logging - print('Supabase initialized successfully'); // Debug log
      
      // Listen for auth state changes with better error handling
      _client!.auth.onAuthStateChange.listen((data) {
// TODO: Replace with proper logging - print('Auth state changed:'); // Debug log
// TODO: Replace with proper logging - print('- Event: ${data.event}'); // Debug log
// TODO: Replace with proper logging - print('- Session: ${data.session?.user.email}'); // Debug log
        
        // Handle specific auth events
        switch (data.event) {
          case AuthChangeEvent.signedOut:
// TODO: Replace with proper logging - print('🔓 User signed out');
            break;
          case AuthChangeEvent.signedIn:
// TODO: Replace with proper logging - print('🔐 User signed in: ${data.session?.user.email}');
            break;
          case AuthChangeEvent.tokenRefreshed:
// TODO: Replace with proper logging - print('🔄 Token refreshed for: ${data.session?.user.email}');
            break;
          case AuthChangeEvent.userUpdated:
// TODO: Replace with proper logging - print('👤 User updated: ${data.session?.user.email}');
            break;
          case AuthChangeEvent.passwordRecovery:
// TODO: Replace with proper logging - print('🔑 Password recovery initiated');
            break;
          // Note: AuthChangeEvent.userDeleted is deprecated
          // case AuthChangeEvent.userDeleted:
          //   print('🗑️ User deleted');
          //   break;
          case AuthChangeEvent.mfaChallengeVerified:
// TODO: Replace with proper logging - print('🔐 MFA challenge verified');
            break;
          default:
// TODO: Replace with proper logging - print('❓ Unknown auth event: ${data.event}');
        }
      }, onError: (error) {
// TODO: Replace with proper logging - print('🔴 Auth state change error: $error');
      });
      
    } catch (error) {
// TODO: Replace with proper logging - print('Error initializing Supabase: $error'); // Debug log
      _client = null;
      _isInitialized = false;
      rethrow;
    }
  }
  
  // Check if Supabase is actually working, not just initialized
  static Future<bool> isSupabaseWorking() async {
    try {
      if (!_isInitialized || _client == null) {
        return false;
      }
      
      // Test if we can access the client and make a simple query
      final client = _client!;
      await client.from('vendors').select('count').limit(1);
      return true;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Supabase not working: $e');
      return false;
    }
  }
  
  // Get client even if state says not initialized - sometimes Supabase.instance works
  static SupabaseClient? getClientSafely() {
    try {
      return Supabase.instance.client;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Cannot get Supabase client: $e');
      return null;
    }
  }
  
  // Force sync our internal state with actual Supabase state
  static Future<bool> syncState() async {
    try {
// TODO: Replace with proper logging - print('🔄 Syncing Supabase state...');
      
      final client = getClientSafely();
      if (client != null) {
        _client = client;
        _isInitialized = true;
        
        // Test if it actually works
        final working = await isSupabaseWorking();
        if (working) {
// TODO: Replace with proper logging - print('🟢 Supabase state synced successfully');
          return true;
        }
      }
      
// TODO: Replace with proper logging - print('🔴 Supabase state sync failed');
      return false;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error syncing Supabase state: $e');
      return false;
    }
  }

  // Handle network-related auth errors gracefully
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is AuthRetryableFetchException) return true;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('network') ||
           errorString.contains('connection');
  }

  // Retry auth operations with exponential backoff
  static Future<T?> retryAuthOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (isNetworkError(e) && attempt < maxRetries) {
// TODO: Replace with proper logging - print('🔄 Auth operation failed (attempt $attempt/$maxRetries), retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        
// TODO: Replace with proper logging - print('🔴 Auth operation failed after $attempt attempts: $e');
        rethrow;
      }
    }
    return null;
  }

  // Check if current session is valid and not expired
  static bool isSessionValid() {
    try {
      final session = _client?.auth.currentSession;
      if (session == null) return false;
      
      // Check if session is expired
      if (session.isExpired) {
// TODO: Replace with proper logging - print('⚠️ Session is expired');
        return false;
      }
      
      return true;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error checking session validity: $e');
      return false;
    }
  }

  // Safe method to get user with error handling
  static User? getCurrentUser() {
    try {
      return _client?.auth.currentUser;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error getting current user: $e');
      return null;
    }
  }

  // Safe method to sign out with error handling
  static Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
// TODO: Replace with proper logging - print('🔓 Successfully signed out');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error signing out: $e');
      // The signOut method should handle clearing the session internally
      // No need to manually clear session as it's handled by the auth client
    }
  }
}
 