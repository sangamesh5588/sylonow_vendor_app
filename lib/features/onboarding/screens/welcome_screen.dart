import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_analytics_service.dart';
import '../../../core/providers/guest_auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService().logScreenView(screenName: 'welcome_screen');
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleGuestLogin() async {
    FirebaseAnalyticsService().logFeatureUsed(
      featureName: 'guest_login_button',
      screenName: 'welcome_screen',
    );

    const defaultBusinessType = 'Private Theater';
    await ref
        .read(guestAuthNotifierProvider.notifier)
        .signInAsGuest(defaultBusinessType);

    // Wait for SharedPreferences to save
    await Future.delayed(const Duration(milliseconds: 100));

    FirebaseAnalyticsService().logCustomEvent(
      eventName: 'guest_login',
      parameters: {
        'business_type': defaultBusinessType,
        'source': 'welcome_screen',
      },
    );

    if (mounted) {
      // Refresh the guest provider to pick up the change
      final _ = ref.refresh(isGuestUserProvider);
      // Small delay to let the provider update before navigation
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Column(
        children: [
          // Top Half - Primary Color Background for Branding
          Expanded(
            flex: 5,
            child: Container(
              color: AppTheme.primaryColor,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'SYLONOW PARTNER',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Your trusted partner for business growth',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.storefront,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sylonow Partner App',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Half - White Background for Functionality
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Terms Checkbox
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _termsAccepted = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                              checkColor: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/terms-conditions'),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    children: const [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms and Conditions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Continue with Phone Button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _termsAccepted
                                ? () async {
                                    final navigator = GoRouter.of(context);

                                    FirebaseAnalyticsService().logFeatureUsed(
                                      featureName: 'phone_signin_button',
                                      screenName: 'welcome_screen',
                                    );

                                    // Clear guest session if user was previously a guest
                                    await ref
                                        .read(
                                            guestAuthNotifierProvider.notifier)
                                        .signOutGuest();

                                    if (mounted) {
                                      navigator.go('/phone');
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.45),
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone),
                                SizedBox(width: 8),
                                Text('Continue with Phone'),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Continue as Guest Button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _handleGuestLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                  color: AppTheme.primaryColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Continue as Guest'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
