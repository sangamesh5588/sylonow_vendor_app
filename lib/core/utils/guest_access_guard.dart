import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/guest_auth_provider.dart';
import '../theme/app_theme.dart';

/// Utility class to guard features from guest users
///
/// Usage:
/// ```dart
/// Future<void> _handleAddTheater() async {
///   final hasAccess = await GuestAccessGuard.checkAccess(
///     context,
///     ref,
///     featureName: 'add theaters',
///   );
///
///   if (!hasAccess) return;
///
///   // Proceed with feature
///   context.push('/add-theater');
/// }
/// ```
class GuestAccessGuard {
  /// Check if user has access to a feature
  ///
  /// Returns true if user is authenticated, false if user is a guest
  ///
  /// If user is a guest, shows a dialog prompting them to sign in
  static Future<bool> checkAccess(
    BuildContext context,
    WidgetRef ref, {
    String featureName = 'this feature',
  }) async {
    final isGuestAsync = ref.read(isGuestUserProvider);
    final isGuest = isGuestAsync.valueOrNull ?? false;

    if (isGuest) {
      // Show sign-in prompt
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sign In Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You need to sign in to access $featureName.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re currently in demo mode',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (shouldSignIn == true && context.mounted) {
        // Sign out guest and go to welcome/login page
        await ref.read(guestAuthNotifierProvider.notifier).signOutGuest();
        if (context.mounted) {
          context.go('/welcome');
        }
      }

      return false; // Access denied
    }

    return true; // Access granted
  }

  /// Show a simple info message for guest users without navigation
  ///
  /// Useful for features that should be disabled for guests but don't require navigation
  static void showGuestInfoMessage(
    BuildContext context,
    String featureName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sign in to access $featureName',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Sign In',
          textColor: Colors.white,
          onPressed: () {
            context.go('/welcome');
          },
        ),
      ),
    );
  }
}
