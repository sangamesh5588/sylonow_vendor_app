import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  late final FirebaseAnalytics _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;

  /// Initialize Firebase Analytics
  void initialize() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);
      _isInitialized = true;
      
      // Enable analytics collection (disabled by default in debug mode)
      _analytics.setAnalyticsCollectionEnabled(true);
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('🔥📊 Firebase Analytics initialized');
      }
    } catch (e) {
      if (kDebugMode) {
// Warning print removed
      }
    }
  }

  /// Get the observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _isInitialized ? _observer : null;

  // ==========================================
  // USER PROPERTIES
  // ==========================================

  /// Set user properties for better analytics segmentation
  Future<void> setUserProperties({
    required String userId,
    String? userType,
    String? businessType,
    String? location,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.setUserId(id: userId);
      
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      
      if (businessType != null) {
        await _analytics.setUserProperty(name: 'business_type', value: businessType);
      }
      
      if (location != null) {
        await _analytics.setUserProperty(name: 'location', value: location);
      }
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 User properties set: userId=$userId, type=$userType');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  // ==========================================
  // AUTHENTICATION EVENTS
  // ==========================================

  /// Track user login
  Future<void> logLogin({required String method}) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logLogin(loginMethod: method);
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Login tracked: $method');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  /// Track user sign up
  Future<void> logSignUp({required String method}) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logSignUp(signUpMethod: method);
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Sign up tracked: $method');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  // ==========================================
  // ONBOARDING EVENTS
  // ==========================================

  /// Track onboarding step completion
  Future<void> logOnboardingStep({
    required String stepName,
    required int stepNumber,
    Map<String, Object>? additionalParams,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      final params = <String, Object>{
        'step_name': stepName,
        'step_number': stepNumber,
        ...?additionalParams,
      };
      
      await _analytics.logEvent(
        name: 'onboarding_step_completed',
        parameters: params,
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Onboarding step tracked: $stepName (step $stepNumber)');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  /// Track onboarding completion
  Future<void> logOnboardingCompleted({
    required Duration timeSpent,
    required int totalSteps,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: 'onboarding_completed',
        parameters: {
          'time_spent_seconds': timeSpent.inSeconds,
          'total_steps': totalSteps,
        },
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Onboarding completion tracked: ${timeSpent.inSeconds}s, $totalSteps steps');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  // ==========================================
  // BUSINESS EVENTS
  // ==========================================

  /// Track service listing creation
  Future<void> logServiceCreated({
    required String serviceType,
    required double price,
    String? location,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: 'service_created',
        parameters: {
          'service_type': serviceType,
          'price': price,
          if (location != null) 'location': location,
        },
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Service creation tracked: $serviceType, \$$price');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  /// Track booking received
  Future<void> logBookingReceived({
    required String bookingId,
    required String serviceType,
    required double value,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: 'booking_received',
        parameters: {
          'booking_id': bookingId,
          'service_type': serviceType,
          'booking_value': value,
        },
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Booking received tracked: $bookingId, \$$value');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  /// Track booking status change
  Future<void> logBookingStatusChanged({
    required String bookingId,
    required String oldStatus,
    required String newStatus,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: 'booking_status_changed',
        parameters: {
          'booking_id': bookingId,
          'old_status': oldStatus,
          'new_status': newStatus,
        },
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Booking status change tracked: $bookingId, $oldStatus → $newStatus');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  // ==========================================
  // APP USAGE EVENTS
  // ==========================================

  /// Track screen views
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Screen view tracked: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  /// Track button/feature usage
  Future<void> logFeatureUsed({
    required String featureName,
    String? screenName,
    Map<String, Object>? additionalParams,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      final params = <String, Object>{
        'feature_name': featureName,
        if (screenName != null) 'screen_name': screenName,
        ...?additionalParams,
      };
      
      await _analytics.logEvent(
        name: 'feature_used',
        parameters: params,
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Feature usage tracked: $featureName');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  /// Track errors and crashes
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          if (screenName != null) 'screen_name': screenName,
        },
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Error tracked: $errorType - $errorMessage');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  // ==========================================
  // FINANCIAL EVENTS
  // ==========================================

  /// Track earnings/revenue
  Future<void> logEarnings({
    required double amount,
    required String currency,
    required String source, // 'booking', 'tip', etc.
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: 'earnings_received',
        parameters: {
          'amount': amount,
          'currency': currency,
          'source': source,
        },
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Earnings tracked: \$$amount from $source');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }

  // ==========================================
  // CUSTOM EVENTS
  // ==========================================

  /// Log custom events
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
// Warning print removed
      }
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      
      if (kDebugMode) {
// TODO: Replace with proper logging - print('📊 Custom event tracked: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
// Error print removed
      }
    }
  }
}
