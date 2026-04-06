import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/guest_auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/providers/vendor_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is authenticated first - this takes precedence over guest status
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = currentUser != null;

    // Check if user is a guest (only matters if NOT authenticated)
    final isGuestAsync = ref.watch(isGuestUserProvider);
    final isGuest = !isAuthenticated && (isGuestAsync.valueOrNull ?? false);

    final vendorAsync = ref.watch(vendorProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with Profile Info
              isGuest
                  ? _buildGuestHeader(context, ref)
                  : _buildProfileHeader(context, vendorAsync, currentUser),

              // Profile Options
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Show limited options for guests
                    if (isGuest) ...[
                      // Guest Info Section
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.cardShadow],
                        ),
                        child: Column(
                          children: [
                            _buildProfileOption(
                              context: context,
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'Read our privacy policy',
                              onTap: () {
                                context.push('/legal/privacy-policy');
                              },
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              context: context,
                              icon: Icons.description_outlined,
                              title: 'Terms & Conditions',
                              subtitle: 'View terms and conditions',
                              onTap: () {
                                context.push('/legal/terms-conditions');
                              },
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              context: context,
                              icon: Icons.info_outline,
                              title: 'About',
                              subtitle: 'App version and information',
                              onTap: () {
                                context.push('/app-info');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button for Guests
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.cardShadow],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              // Sign out guest and navigate to welcome screen
                              await ref
                                  .read(guestAuthNotifierProvider.notifier)
                                  .signOutGuest();
                              if (context.mounted) {
                                context.go('/welcome');
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Sign In to Your Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Show all options for authenticated users
                    if (!isGuest) ...[
                      // Profile Options Container
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.cardShadow],
                        ),
                        child: Column(
                          children: [
                            _buildProfileOption(
                              context: context,
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              subtitle: 'Update your personal information',
                              onTap: () {
                                context.push('/edit-profile');
                              },
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              context: context,
                              icon: Icons.business_outlined,
                              title: 'Business Details',
                              subtitle: 'Manage your business information',
                              onTap: () {
                                context.push('/business-details');
                              },
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              context: context,
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Payment Settings',
                              subtitle: 'Manage payment methods',
                              onTap: () {
                                context.push('/payment-settings');
                              },
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              context: context,
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Get help and contact support',
                              onTap: () {
                                context.push('/support');
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // About Section
                      _buildSectionHeader('About'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.cardShadow],
                        ),
                        child: Column(
                          children: [
                            _buildProfileOption(
                              context: context,
                              icon: Icons.info_outline,
                              title: 'App Information',
                              subtitle: 'Version, updates and app details',
                              onTap: () {
                                context.push('/app-info');
                              },
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              context: context,
                              icon: Icons.description_outlined,
                              title: 'Legal Documents',
                              subtitle: 'Privacy policy, terms and conditions',
                              onTap: () {
                                _showLegalDocumentsBottomSheet(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Danger Zone Section
                      _buildSectionHeader('Danger Zone'),
                      const SizedBox(height: 12),

                      // Delete Account Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.cardShadow],
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showDeleteAccountDialog(context, ref),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_forever_outlined,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delete Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Permanently delete your account',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: AppTheme.errorColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.cardShadow],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showLogoutDialog(context, ref),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Logout',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Sign out of your account',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: AppTheme.errorColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // App Logo at bottom
                    Center(
                      child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            'assets/svgs/app_logo.svg',
                            color: AppTheme.primaryColor,
                          )),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    try {
// TODO: Replace with proper logging - print('🔄 Refreshing profile screen data...');

      // Show haptic feedback
      HapticFeedback.lightImpact();

      // Use safer refresh approach that doesn't trigger router
      ref.read(vendorProvider.notifier).invalidateAndRefresh();

      // Small delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 300));

// TODO: Replace with proper logging - print('🟢 Profile screen refresh completed');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Profile screen refresh failed: $e');
    }
  }

  void _showLegalDocumentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Legal Documents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Legal options
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textSecondaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildProfileOption(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/legal/privacy-policy');
                    },
                  ),
                  _buildDivider(),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'View terms and conditions',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/legal/terms-conditions');
                    },
                  ),
                  _buildDivider(),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.monetization_on_outlined,
                    title: 'Revenue Policy',
                    subtitle: 'Commission and payment policy',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/legal/revenue-policy');
                    },
                  ),
                ],
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AsyncValue vendorAsync, currentUser) {
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 48), // To balance the back button
            ],
          ),

          const SizedBox(height: 20),

          // Profile Info
          vendorAsync.when(
            data: (vendor) => Column(
              children: [
                // Profile Picture
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(vendor),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  vendor?.fullName ?? 'Vendor Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Vendor ID
                if (vendor?.vendorId != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vendor!.vendorId!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Email or Phone
                Text(
                  vendor?.phone?.isNotEmpty == true
                      ? vendor!.phone!
                      : vendor?.email?.isNotEmpty == true
                          ? vendor!.email!
                          : currentUser?.email ?? 'No contact info',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Verification Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: vendor?.verificationStatus == 'verified'
                        ? AppTheme.successColor
                        : vendor?.verificationStatus == 'rejected'
                            ? AppTheme.errorColor
                            : AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vendor?.verificationStatus == 'verified'
                            ? Icons.verified
                            : vendor?.verificationStatus == 'rejected'
                                ? Icons.cancel
                                : Icons.pending,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vendor?.verificationStatus == 'verified'
                            ? 'Verified Partner'
                            : vendor?.verificationStatus == 'rejected'
                                ? 'Verification Rejected'
                                : 'Pending Verification',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (vendor?.businessName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    vendor!.businessName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            loading: () => _buildProfileHeaderSkeleton(),
            error: (error, stack) => _buildProfileHeaderError(currentUser),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderSkeleton() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 24,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeaderError(currentUser) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [AppTheme.cardShadow],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppTheme.primaryColor,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Unable to load profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentUser?.email ?? 'No contact info',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.errorColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Failed to load data',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: AppTheme.borderColor,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.read(vendorProvider);
    final phoneNumber = vendorAsync.value?.phone;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete account: Phone number not found'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _DeleteAccountDialog(
          phoneNumber: phoneNumber,
          onDeleted: () {
            // Clear all data and navigate to welcome
            ref.read(vendorProvider.notifier).clearVendorData();
            ref.invalidate(vendorProvider);
            ref.invalidate(authStateProvider);
            context.go('/welcome');
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                context.pop();
                await _handleLogout(context, ref);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
// TODO: Replace with proper logging - print('🔵 Logout: Starting logout process...');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );

      // Clear vendor data first (before auth logout)
// TODO: Replace with proper logging - print('🔵 Logout: Clearing vendor data...');
      ref.read(vendorProvider.notifier).clearVendorData();

      // Perform logout from Supabase
// TODO: Replace with proper logging - print('🔵 Logout: Signing out from Supabase...');
      await SupabaseConfig.client.auth.signOut();

      // Force invalidate all providers to clear cached data
// TODO: Replace with proper logging - print('🔵 Logout: Invalidating providers...');
      ref.invalidate(vendorProvider);
      ref.invalidate(authStateProvider);

      // Small delay to ensure state propagation
      await Future.delayed(const Duration(milliseconds: 200));

// TODO: Replace with proper logging - print('🟢 Logout: Logout successful, navigating to welcome...');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to welcome screen and clear the navigation stack
        context.go('/welcome');

        // Fallback: If go() doesn't work, force navigation after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            final currentRoute = GoRouterState.of(context).matchedLocation;
            if (currentRoute != '/welcome') {
// TODO: Replace with proper logging - print('🔴 Logout: Router redirect failed, forcing navigation...');
              context.pushReplacement('/welcome');
            }
          }
        });
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Logout: Error during logout: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Even on error, try to navigate to welcome
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            context.go('/welcome');
          }
        });
      }
    }
  }

  Widget _buildGuestHeader(BuildContext context, WidgetRef ref) {
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 48), // To balance the back button
            ],
          ),

          const SizedBox(height: 20),

          // Guest Profile Info
          Column(
            children: [
              // Guest Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),

              // Guest Name
              const Text(
                'Guest User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Demo Mode Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Exploring in Demo Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Text(
                'Sign in to access all features',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(vendor) {
    // Debug information
// TODO: Replace with proper logging - print('🔍 Profile Image Debug:');
// TODO: Replace with proper logging - print('🔍 Vendor ID: ${vendor?.id}');
// TODO: Replace with proper logging - print('🔍 Profile Picture URL: ${vendor?.profilePicture}');
// TODO: Replace with proper logging - print('🔍 Profile Picture null? ${vendor?.profilePicture == null}');
    // TODO: Replace with proper logging - print('🔍 Profile Picture empty? ${vendor?.profilePicture?.isEmpty ?? true}');

    if (vendor?.profilePicture != null && vendor!.profilePicture!.isNotEmpty) {
      return Image.network(
        vendor.profilePicture!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryColor,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
// TODO: Replace with proper logging - print('🔴 Profile picture loading error: $error');
// TODO: Replace with proper logging - print('🔴 Image URL: ${vendor.profilePicture}');
// TODO: Replace with proper logging - print('🔴 Stack trace: $stackTrace');
          return Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  'Image Error',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppTheme.primaryColor,
          size: 50,
        ),
      );
    }
  }
}

// Delete Account Dialog Widget with OTP Verification
class _DeleteAccountDialog extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onDeleted;

  const _DeleteAccountDialog({
    required this.phoneNumber,
    required this.onDeleted,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  int _step = 0; // 0 = confirmation, 1 = OTP entry
  bool _isLoading = false;
  bool _isSendingOtp = false;
  final _otpController = TextEditingController();
  int _resendTimer = 0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      await SupabaseConfig.client.auth.signInWithOtp(
        phone: widget.phoneNumber,
        shouldCreateUser: false,
      );

      if (mounted) {
        setState(() {
          _step = 1;
          _isSendingOtp = false;
          _resendTimer = 60;
        });

        // Start countdown timer
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${widget.phoneNumber}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _verifyOtpAndDelete() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP
      await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.sms,
        phone: widget.phoneNumber,
        token: otp,
      );

      // Delete vendor account from database
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        // Delete vendor record
        await SupabaseConfig.client
            .from('vendors')
            .delete()
            .eq('auth_user_id', user.id);

        // Delete auth user
        await SupabaseConfig.client.rpc('delete_user');
      }

      // Sign out
      await SupabaseConfig.client.auth.signOut();

      if (mounted) {
        Navigator.of(context).pop();
        widget.onDeleted();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been permanently deleted'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppTheme.surfaceColor,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
      content: _step == 0 ? _buildConfirmationStep() : _buildOtpStep(),
      actions: _step == 0
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isSendingOtp ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _isSendingOtp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ]
          : [
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _step = 0;
                          _otpController.clear();
                        });
                      },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'All your data will be permanently deleted:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDeleteItem(
              Icons.person_off, 'Your profile and account details'),
          _buildDeleteItem(
              Icons.business_center_outlined, 'Business information'),
          _buildDeleteItem(
              Icons.image_outlined, 'Uploaded documents and images'),
          _buildDeleteItem(Icons.receipt_long_outlined, 'Order history'),
          _buildDeleteItem(Icons.account_balance_wallet_outlined,
              'Wallet and transaction history'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'We will send an OTP to ${widget.phoneNumber} for verification',
                    style: const TextStyle(
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
    );
  }

  Widget _buildDeleteItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.errorColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the OTP sent to your phone',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.phoneNumber,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '------',
              counterText: '',
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_resendTimer > 0)
            Center(
              child: Text(
                'Resend OTP in ${_resendTimer}s',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: _sendOtp,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
