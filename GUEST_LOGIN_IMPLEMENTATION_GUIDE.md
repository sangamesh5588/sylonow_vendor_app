# Guest Login Implementation Guide

## Overview
This guide outlines the complete implementation of the Guest Login feature for SyloNow Partner app.

## Current Status ✅
The following has been implemented:

###1. Guest Auth Service (`lib/core/services/guest_auth_service.dart`)
- ✅ Check if user is guest
- ✅ Store guest business type (Private Theater / Event Decorator)
- ✅ Sign in as guest
- ✅ Sign out guest
- ✅ Uses SharedPreferences for persistence

### 2. Guest Auth Provider (`lib/core/providers/guest_auth_provider.dart`)
- ✅ Riverpod providers for guest state
- ✅ `guestAuthNotifierProvider` for managing guest login/logout
- ✅ `isGuestUserProvider` to check guest status
- ✅ `guestBusinessTypeProvider` to get business type

### 3. Phone Screen Updates (`lib/features/onboarding/screens/phone_screen.dart`)
- ✅ Guest login button added
- ✅ Business type selection dialog (Private Theater / Event Decorator)
- ✅ Navigation to home after guest selection
- ✅ Firebase Analytics tracking for guest login

## Remaining Implementation

### 4. Router Configuration Update

**File**: `lib/core/config/router_config.dart`

**Changes Needed**:

1. **Import guest auth provider**:
```dart
import '../providers/guest_auth_provider.dart';
```

2. **Update `GoRouterRefreshStream` to listen to guest auth**:
```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this._ref) {
    // Existing listeners...

    // ADD: Listen to guest auth state changes
    _ref.listen(
      guestAuthNotifierProvider,
      (previous, next) {
        if (!_disposed) {
          notifyListeners();
        }
      },
    );
  }

  // ... rest of the code
}
```

3. **Update redirect logic to handle guests**:
```dart
redirect: (context, state) {
  final authState = ref.watch(authStateProvider);
  final vendorState = ref.watch(vendorProvider);
  final splashComplete = ref.watch(splashAnimationCompletedProvider);
  final guestState = ref.watch(guestAuthNotifierProvider); // ADD THIS
  final isAuthenticated = authState.valueOrNull?.session != null;
  final isGuest = guestState.valueOrNull ?? false; // ADD THIS

  final isGoingToSplash = state.matchedLocation == '/splash' || state.matchedLocation == '/';
  final publicRoutes = ['/welcome', '/phone', '/verify-otp', '/cookies-policy', '/terms-conditions', '/revenue-policy', '/privacy-policy'];
  final isGoingToPublicRoute = publicRoutes.contains(state.matchedLocation);

  // ADD: Define guest-allowed routes
  final guestAllowedRoutes = [
    '/home',
    '/profile',
    '/support',
    '/privacy-policy',
    '/terms-conditions',
    '/cookies-policy',
    '/revenue-policy',
    '/app-info',
  ];
  final isGuestAllowedRoute = guestAllowedRoutes.contains(state.matchedLocation);

  // CRITICAL: Do not allow navigation away from splash until animation completes
  if (!splashComplete) {
    return isGoingToSplash ? null : '/splash';
  }

  // ALWAYS stay on splash if auth is loading
  if (authState.isLoading) {
    return isGoingToSplash ? null : '/splash';
  }

  // ADD: Handle guest users
  if (isGuest && !isAuthenticated) {
    // Guest user trying to access auth-required route
    if (!isGuestAllowedRoute && !isGoingToPublicRoute && !isGoingToSplash) {
      // Show sign-in prompt or redirect to profile
      return '/home';
    }
    // Allow navigation to guest-allowed routes
    if (isGoingToSplash || isGoingToPublicRoute) {
      return '/home';
    }
    return null;
  }

  // If user is not authenticated and not guest, allow public routes or redirect to welcome
  if (!isAuthenticated) {
    return isGoingToPublicRoute ? null : '/welcome';
  }

  // Rest of existing auth redirect logic...
  // (keep all existing authenticated user logic as is)
}
```

### 5. Home Screen Updates

**File**: `lib/features/home/screens/home_screen.dart`

**Changes Needed**:

1. **Add demo data service**:
```dart
// Create lib/features/home/services/demo_data_service.dart
class DemoDataService {
  static List<Order> getDemoOrders() {
    return [
      Order(
        id: 'demo-1',
        vendorId: 'demo',
        customerName: 'Demo Customer 1',
        serviceType: 'Private Theater',
        status: 'confirmed',
        totalAmount: 2500.0,
        // ... more demo data
      ),
      // Add 2-3 more demo orders
    ];
  }

  static Map<String, dynamic> getDemoStats() {
    return {
      'total_orders': 15,
      'pending_orders': 3,
      'completed_orders': 10,
      'total_revenue': 37500.0,
    };
  }
}
```

2. **Update home screen to check guest status**:
```dart
@override
Widget build(BuildContext context) {
  final isGuest = ref.watch(isGuestUserProvider).valueOrNull ?? false;

  return Scaffold(
    appBar: AppBar(
      title: Text(isGuest ? 'SyloNow Partner - Demo Mode' : 'Dashboard'),
      // Add demo indicator badge if guest
      actions: [
        if (isGuest)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'DEMO',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    ),
    body: isGuest ? _buildDemoContent() : _buildRealContent(),
  );
}

Widget _buildDemoContent() {
  // Show demo orders and stats
  final demoOrders = DemoDataService.getDemoOrders();
  final demoStats = DemoDataService.getDemoStats();

  return ListView(
    children: [
      _buildStatsCard(demoStats),
      _buildOrdersList(demoOrders, isDemo: true),
    ],
  );
}
```

### 6. Profile Screen Updates

**File**: `lib/features/profile/screens/profile_screen.dart`

**Changes Needed**:

1. **Check guest status and show limited options**:
```dart
@override
Widget build(BuildContext context) {
  final isGuest = ref.watch(isGuestUserProvider).valueOrNull ?? false;

  return Scaffold(
    appBar: AppBar(
      title: Text('Profile'),
    ),
    body: ListView(
      children: [
        if (isGuest) _buildGuestHeader(),
        if (!isGuest) _buildAuthenticatedUserHeader(),

        // Show only these options for guests
        if (isGuest) ...[
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Terms & Conditions'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => context.push('/terms-conditions'),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => context.push('/app-info'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.login, color: AppTheme.primaryColor),
            title: Text(
              'Sign In',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
            onTap: () async {
              // Sign out guest and navigate to login
              await ref.read(guestAuthNotifierProvider.notifier).signOutGuest();
              if (context.mounted) {
                context.go('/phone');
              }
            },
          ),
        ],

        // Show all options for authenticated users
        if (!isGuest) ...[
          // ... existing profile options
        ],
      ],
    ),
  );
}

Widget _buildGuestHeader() {
  return Container(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
        ),
        SizedBox(height: 16),
        Text(
          'Guest User',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Exploring in Demo Mode',
            style: TextStyle(color: Colors.orange[700], fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
```

### 7. Feature Access Guards

**Create**: `lib/core/utils/guest_access_guard.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/guest_auth_provider.dart';
import '../theme/app_theme.dart';

class GuestAccessGuard {
  static Future<bool> checkAccess(
    BuildContext context,
    WidgetRef ref, {
    String featureName = 'this feature',
  }) async {
    final isGuest = ref.watch(isGuestUserProvider).valueOrNull ?? false;

    if (isGuest) {
      // Show sign-in prompt
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sign In Required'),
          content: Text(
            'You need to sign in to access $featureName. Would you like to sign in now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text('Sign In'),
            ),
          ],
        ),
      );

      if (shouldSignIn == true && context.mounted) {
        // Sign out guest and go to login
        await ref.read(guestAuthNotifierProvider.notifier).signOutGuest();
        if (context.mounted) {
          context.go('/phone');
        }
      }

      return false; // Access denied
    }

    return true; // Access granted
  }
}
```

**Usage Example**:
```dart
// In any screen that requires authentication
Future<void> _handleAddTheater() async {
  final hasAccess = await GuestAccessGuard.checkAccess(
    context,
    ref,
    featureName: 'add theaters',
  );

  if (!hasAccess) return;

  // Proceed with feature
  context.push('/add-theater');
}
```

### 8. Add Guards to Feature Screens

Add `GuestAccessGuard` checks to:
- Add Theater screens
- Add Service screens
- Order management screens
- Edit Profile screens
- Payment settings screens
- Any screen that modifies data

Example:
```dart
FloatingActionButton(
  onPressed: () async {
    final hasAccess = await GuestAccessGuard.checkAccess(
      context, ref, featureName: 'create orders'
    );
    if (!hasAccess) return;
    // Your existing logic
  },
  child: Icon(Icons.add),
),
```

## Testing Checklist

- [ ] Guest can tap "Continue as Guest" on phone screen
- [ ] Business type selection dialog appears
- [ ] Guest is redirected to home after selection
- [ ] Home screen shows demo data for guests
- [ ] Home screen shows "DEMO" badge for guests
- [ ] Profile screen shows limited options (Privacy Policy, About, Terms, Sign In)
- [ ] Guest cannot access auth-required features
- [ ] Sign-in prompt appears when guest tries restricted features
- [ ] Guest can sign in from profile screen
- [ ] After sign-in, guest status is cleared
- [ ] Normal auth flow works after guest sign-out

## Summary

**Completed** ✅:
1. Guest auth service and providers
2. Phone screen with guest login button
3. Business type selection dialog

**Remaining** ⏳:
1. Router configuration update (15 minutes)
2. Home screen demo data (20 minutes)
3. Profile screen guest view (15 minutes)
4. Feature access guards (30 minutes)
5. Apply guards to feature screens (20 minutes)
6. Testing (30 minutes)

**Total Estimated Time**: ~2 hours

---

**Implementation Priority**:
1. **Router** - Critical for navigation
2. **Profile Screen** - User needs way to sign in
3. **Home Screen** - Shows demo data
4. **Access Guards** - Prevents unauthorized actions
5. **Testing** - Ensure everything works

This implementation provides a complete guest experience while maintaining security and proper user flow!
