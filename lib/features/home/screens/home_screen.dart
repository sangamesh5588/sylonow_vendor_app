import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:sylonow_vendor/features/dashboard/models/activity_item.dart';
import 'package:sylonow_vendor/features/dashboard/models/booking.dart';
import 'package:sylonow_vendor/features/dashboard/models/dashboard_stats.dart';
import 'package:sylonow_vendor/features/dashboard/providers/dashboard_provider.dart';
import 'package:sylonow_vendor/features/dashboard/services/booking_service.dart';
import 'package:sylonow_vendor/features/onboarding/models/vendor.dart';
import 'package:sylonow_vendor/features/onboarding/service/vendor_service.dart'
    as vendor_service;
import 'package:sylonow_vendor/features/orders/models/order.dart';
import 'package:sylonow_vendor/features/orders/providers/order_provider.dart';
import 'package:sylonow_vendor/features/orders/service/order_service.dart';

import '../../../core/providers/app_version_provider.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_analytics_service.dart';
import '../../../core/services/location_permission_service.dart';
import '../../../core/widgets/app_update_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/guest_auth_provider.dart';
import '../../onboarding/providers/vendor_provider.dart';
import '../../onboarding/service/vendor_service.dart' as vendor_svc;
import '../../service_addon/widgets/service_addon_summary_card.dart';
import '../service/demo_data_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isOnline = false;
  bool _isToggling = false; // Prevent sync during toggle operations
  int _selectedIndex = 0;
  int _switchRebuildKey = 0; // Forces switch to recreate when dialog is cancelled
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ValueNotifier<bool> _onlineStatusController;
  bool _isInitialized = false;
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _onlineStatusController = ValueNotifier<bool>(false);
    _selectedIndex = 0; // Always reset to home when screen initializes
    _setupAnimations();
    _startAnimations();
    _setStatusBarColor();

    // Track screen view and upsert FCM token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService().logScreenView(screenName: 'home_screen');
      _upsertFCMToken();
      _checkAndRequestMandatoryLocation();
      _checkAppVersion();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset navigation to home whenever this screen is active
    if (_selectedIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
  }

  void _setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _onlineStatusController.dispose();
    super.dispose();
  }

  Future<void> _checkAppVersion() async {
    if (!mounted) return;
    final info = await ref.read(appVersionCheckProvider.future);
    if (info != null && mounted) {
      await AppUpdateDialog.showIfNeeded(context, info);
    }
  }

  Future<void> _upsertFCMToken() async {
    try {
      final vendor = ref.read(vendorProvider).value;
      if (vendor?.id != null) {
        await FCMService.upsertTokenToVendor(vendor!.id!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error upserting FCM token in home screen: $e');
      }
    }
  }

  Future<void> _checkAndRequestMandatoryLocation() async {
    try {
      final vendor = ref.read(vendorProvider).value;

      if (vendor == null || vendor.id == null) {
        if (kDebugMode) {
          print('⚠️ Vendor not loaded yet, skipping location check');
        }
        return;
      }

      // Check if vendor already has location
      if (vendor.latitude != null && vendor.longitude != null) {
        if (kDebugMode) {
          print('✅ Vendor already has location coordinates');
        }
        return;
      }

      if (kDebugMode) {
        print('⚠️ Vendor missing location - showing mandatory prompt');
      }

      // Show mandatory location permission dialog
      if (mounted) {
        await LocationPermissionService.checkAndRequestMandatoryLocation(
          context: context,
          vendor: vendor,
          onLocationGranted: (lat, lng) async {
            // Save location to database
            final vendorService = ref.read(vendor_svc.vendorServiceProvider);
            final success = await vendorService.updateVendorLocation(
              vendor.id!,
              lat,
              lng,
            );

            if (success) {
              if (kDebugMode) {
                print('✅ Location saved to database');
              }
              // Refresh vendor data to update UI
              ref.invalidate(vendorProvider);
            } else {
              if (kDebugMode) {
                print('❌ Failed to save location to database');
              }
            }
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in mandatory location check: $e');
      }
    }
  }

  String _getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated first - this takes precedence over guest status
    final vendorAsync = ref.watch(vendorProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = currentUser != null;

    // Check if user is a guest (only matters if NOT authenticated)
    final isGuestAsync = ref.watch(isGuestUserProvider);
    final isGuest = !isAuthenticated && (isGuestAsync.valueOrNull ?? false);
    final guestBusinessType = ref.watch(guestBusinessTypeProvider).valueOrNull;

    // For guest users, use demo data; for authenticated users, use real data
    final dashboardDataAsync = isGuest
        ? AsyncValue.data(DemoDataService.getDemoDashboardData(
            guestBusinessType ?? 'Private Theater'))
        : ref.watch(dashboardDataProvider);

    // Initialize controller with vendor data only once
    vendorAsync.whenData((vendor) {
      if (vendor != null && !_isInitialized) {
        final vendorOnlineStatus = vendor.isOnline == true;
        _onlineStatusController.value = vendorOnlineStatus;
        _isInitialized = true;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigation(),
      body: dashboardDataAsync.when(
        data: (dashboardData) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Minimalistic Header
                _buildHeader(vendorAsync),

                // Main Content - Flexible and Scrollable with Pull-to-Refresh
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.surfaceColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 80), // Added padding
                      child: Column(
                        children: [
                          _buildStatsGrid(dashboardData.stats),
                          const SizedBox(height: 24),
                          const ServiceAddonSummaryCard(),
                          const SizedBox(height: 24),
                          _buildRecentOrdersSection(),
                          const SizedBox(height: 24),
                          _buildRecentActivity(dashboardData.recentActivities),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Column(
          children: [
            _buildHeader(vendorAsync),
            const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))),
          ],
        ),
        error: (error, stack) => Column(
          children: [
            _buildHeader(vendorAsync),
            Expanded(
              child: Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(vendorProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(recentUnseenOrdersProvider);
    await Future.delayed(const Duration(seconds: 1));
  }

  Widget _buildHeader(AsyncValue vendorAsync) {
    // Check if user is a guest
    final isGuestAsync = ref.watch(isGuestUserProvider);
    final isGuest = isGuestAsync.valueOrNull ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 15, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: vendorAsync.when(
        data: (vendor) {
          // Initialize local state on first load if not set
          // Skip for guest users (vendor will be null)
          if (!isGuest &&
              vendor != null &&
              !_isToggling &&
              _isOnline != vendor.isOnline) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isToggling) {
                setState(() {
                  _isOnline = vendor.isOnline;
                });
              }
            });
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Profile Picture
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [AppTheme.cardShadow],
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8), width: 1),
                    ),
                    child: ClipOval(
                      child: isGuest || vendor == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: AppTheme.primaryColor,
                              size: 28,
                            )
                          : _buildHeaderProfileImage(vendor!),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest
                              ? 'Exploring SyloNow Partner'
                              : 'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isGuest
                                    ? 'Guest User'
                                    : (vendor?.businessName ??
                                        'Vendor Partner'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isGuest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'DEMO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!isGuest && vendor?.vendorId != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vendor.vendorId!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status & Notifications
                  Row(
                    children: [
                      // Only show online/offline toggle for authenticated users, not guests
                      if (!isGuest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: _onlineStatusController,
                                builder: (context, isOnline, child) {
                                  return Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: isOnline
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Colors.red,
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              ValueListenableBuilder<bool>(
                                valueListenable: _onlineStatusController,
                                builder: (context, isOnline, child) {
                                  return AdvancedSwitch(
                                    key: ValueKey(
                                        '$isOnline-$_switchRebuildKey'),
                                    initialValue: isOnline,
                                    activeChild: const Text(
                                      'Online',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    inactiveChild: const Text(
                                      'Offline',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    activeColor: Colors.green,
                                    inactiveColor: Colors.grey,
                                    width: 86.0,
                                    height: 34.0,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(18)),
                                    thumb: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black54
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onChanged: (value) =>
                                        _showStatusToggleConfirmation(
                                            ref, vendor, value),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (!isGuest) const SizedBox(width: 12),
                      const SizedBox(width: 12),
                      if (!isGuest)
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location
              Row(
                children: [
                  HeroIcon(
                    HeroIcons.map,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isGuest
                          ? 'Demo Location'
                          : (vendor?.serviceArea ?? 'Location not set'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => _buildHeaderSkeleton(),
        error: (error, stack) => _buildHeaderError(),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 28, backgroundColor: Colors.white24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 100, color: Colors.white24),
                  const SizedBox(height: 6),
                  Container(height: 18, width: 150, color: Colors.white24),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: Colors.white24),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.white24, size: 16),
            const SizedBox(width: 8),
            Container(height: 14, width: 200, color: Colors.white24),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderError() {
    return const Center(
      child: Text(
        'Failed to load vendor data.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderProfileImage(Vendor vendor) {
    // Debug information for home screen
// TODO: Replace with proper logging - print('🔍 Home Header Profile Image Debug:');
// TODO: Replace with proper logging - print('🔍 Vendor ID: ${vendor.id ?? 'null'}');
// TODO: Replace with proper logging - print('🔍 Profile Picture URL: ${vendor.profilePicture}');
// TODO: Replace with proper logging - print('🔍 Profile Picture null? ${vendor.profilePicture == null}');
    // TODO: Replace with proper logging - print('🔍 Profile Picture empty? ${vendor.profilePicture?.isEmpty ?? true}');

    if (vendor.profilePicture != null && vendor.profilePicture!.isNotEmpty) {
      return Image.network(
        vendor.profilePicture!,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white.withValues(alpha: 0.8),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
// TODO: Replace with proper logging - print('🔴 Home header profile picture loading error: $error');
// TODO: Replace with proper logging - print('🔴 Image URL: ${vendor.profilePicture}');
// TODO: Replace with proper logging - print('🔴 Stack trace: $stackTrace');
          return Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 6,
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
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppTheme.primaryColor,
          size: 28,
        ),
      );
    }
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    double childAspectRatio = 0.95;

    if (screenWidth >= 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1.3;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.4;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _HomeStatCard(
          path: 'assets/animations/growth.json',
          label: 'Gross Sales',
          value: _formatCurrency(stats.grossSales),
          color: AppTheme.successColor,
          isLoading: false,
          onTap: null, // Non-clickable
        ),
        _HomeStatCard(
          path: 'assets/animations/earning.json',
          label: 'Earnings',
          value: _formatCurrency(_calculateEarnings(stats.grossSales)),
          color: AppTheme.primaryColor,
          isLoading: false,
          onTap: null,
        ),
        _HomeStatCard(
          path: 'assets/animations/orders.json',
          label: 'Total Orders',
          value: '${stats.totalBookings}',
          color: AppTheme.accentBlue,
          isLoading: false,
          onTap: (context) => context.push('/orders'),
        ),
        _HomeStatCard(
          path: 'assets/animations/service.json',
          label: 'Service Listings',
          value: '${stats.totalTheaters}',
          color: AppTheme.accentTeal,
          isLoading: false,
          onTap: (context) => context.push('/service-listings'),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  // Vendor earnings = gross sales minus platform fee (5% + 18% GST on that = 5.9%)
  double _calculateEarnings(double grossSales) {
    const double platformFeeRate = 0.05;
    const double gstRate = 0.18;
    final double platformFee = grossSales * platformFeeRate * (1 + gstRate);
    return grossSales - platformFee;
  }

  Widget _buildRecentOrdersSection() {
    return Consumer(
      builder: (context, ref, child) {
        // Check if user is a guest
        final isGuestAsync = ref.watch(isGuestUserProvider);
        final isGuest = isGuestAsync.valueOrNull ?? false;
        final guestBusinessType =
            ref.watch(guestBusinessTypeProvider).valueOrNull;

        // For guest users, use demo orders; for authenticated users, use real orders
        if (isGuest) {
          final demoOrders = DemoDataService.getDemoOrders(
              guestBusinessType ?? 'Private Theater');
          return _buildRecentOrdersList(demoOrders);
        }

        final recentOrdersAsync = ref.watch(recentUnseenOrdersProvider);

        return recentOrdersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return _buildNoOrdersCard();
            } else {
              return _buildRecentOrdersList(orders);
            }
          },
          loading: () => _buildRecentOrdersLoading(),
          error: (error, stack) => _buildNoOrdersCard(),
        );
      },
    );
  }

  Widget _buildNoOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Looking for new orders...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you as soon as a customer places an order. Keep your notifications enabled!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Notifications Active',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(List<Order> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/orders'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...orders.take(3).map((order) => _buildRecentOrderCard(order)),
      ],
    );
  }

  Widget _buildRecentOrdersLoading() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading recent orders...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(Order order) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.serviceTitle ?? 'Unknown Service',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getOrderStatusText(order.status ?? 'pending'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order.customerName != null && order.customerName!.isNotEmpty)
            Text(
              order.customerName!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withValues(alpha: 0.9),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy')
                    .format(order.bookingDate ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              if (order.bookingTime != null &&
                  order.bookingTime!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  order.bookingTime!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final orderValuesAsync =
                      ref.watch(orderValuesProvider(order));
                  return orderValuesAsync.when(
                    data: (orderValues) => Text(
                      '₹${orderValues['totalOrderValue']!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 60,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    error: (error, stack) => Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              if ((order.status ?? 'pending').toLowerCase() == 'pending')
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final isGuest =
                            ref.read(isGuestUserProvider).valueOrNull ?? false;
                        if (isGuest) {
                          _showLoginDialog();
                        } else {
                          _showAcceptOrderConfirmation(order);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Accept',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _viewOrderDetails(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('View',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: () => _viewOrderDetails(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewBookingCard(Booking? booking) {
    if (booking == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Looking for new bookings...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'ll notify you as soon as a customer books your service. Keep your notifications enabled!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Notifications Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.serviceTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NEW', // Placeholder for timer
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('E, MMM d - h:mm a').format(booking.bookingDate),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${booking.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  // Accept Button
                  ElevatedButton(
                    onPressed: () => _showAcceptBookingConfirmation(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  // View Button
                  OutlinedButton(
                    onPressed: () => _viewBookingDetails(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('View',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<ActivityItem> recentActivities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Center(
              child: Text(
                'No recent activity found.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          )
        else
          ...recentActivities.take(3).map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDynamicActivityItem(activity),
              )),
      ],
    );
  }

  Widget _buildDynamicActivityItem(ActivityItem activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity.icon,
              color: activity.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.subtitle} • ${_getRelativeTime(activity.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (activity.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activity.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity.displayStatus,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: activity.iconColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: 'fab_home',
      onPressed: () async {
        // Check if user is guest - show popup if so
        final isGuest = ref.read(isGuestUserProvider).valueOrNull ?? false;
        if (isGuest) {
          _showFabLoginDialog(context);
        } else {
          context.push('/add-service');
        }
      },
      foregroundColor: Colors.white,
      backgroundColor: AppTheme.primaryColor,
      child: const HeroIcon(HeroIcons.plusCircle),
    );
  }

  void _showFabLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please login to add new services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/welcome');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: HeroIcons.home,
                label: 'Home',
                index: 0,
                isSelected: _selectedIndex == 0,
                onTap: () => _handleNavTap(0),
              ),
              _buildNavItem(
                icon: HeroIcons.shoppingBag,
                label: 'Orders',
                index: 1,
                isSelected: _selectedIndex == 1,
                onTap: () => _handleNavTap(1, '/orders'),
              ),
              _buildNavItem(
                icon: HeroIcons.lifebuoy,
                label: 'Support',
                index: 2,
                isSelected: _selectedIndex == 2,
                onTap: () => _handleNavTap(2, '/support'),
              ),
              _buildNavItem(
                icon: HeroIcons.user,
                label: 'Profile',
                index: 3,
                isSelected: _selectedIndex == 3,
                onTap: () => _handleNavTap(3, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required HeroIcons icon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with Material 3 style indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: isSelected ? 64 : 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isSelected ? 1.1 : 1.0,
                        child: HeroIcon(
                          icon,
                          size: 24,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondaryColor,
                          style: isSelected
                              ? HeroIconStyle.solid
                              : HeroIconStyle.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Label with animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : AppTheme.textSecondaryColor,
                  height: 1.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavTap(int index, [String? route]) {
    if (route != null) {
      // For navigation to other screens, don't update state
      // The state will be reset when user returns
      context.push(route);
    } else if (_selectedIndex != index) {
      // Only update state if staying on current screen (Home)
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _showAcceptBookingConfirmation(Booking booking) async {
    final bool? shouldAccept = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.event_available, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Accept Booking?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to accept this booking?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceTitle ?? 'Booking',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (booking.customerName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${booking.customerName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept Booking'),
            ),
          ],
        );
      },
    );

    if (shouldAccept == true) {
      await _acceptBooking(booking);
    }
  }

  // Accept booking functionality
  Future<void> _acceptBooking(Booking booking) async {
    try {
// TODO: Replace with proper logging - print('🔄 Accepting booking: ${booking.id}');
// TODO: Replace with proper logging - print('🔍 Full booking data: ${booking.toJson()}');

      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Accepting booking...'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final success = await _bookingService.acceptBooking(booking.id);

      if (success) {
        if (mounted) {
          // Clear any existing snackbars
          ScaffoldMessenger.of(context).clearSnackBars();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Booking Accepted Successfully! 🎉',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Customer will be notified. Looking for next booking...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Refresh the dashboard data to update the UI and clear the accepted booking
          ref.invalidate(dashboardDataProvider);
        }
      } else {
        if (mounted) {
          // Clear any existing snackbars
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Failed to accept booking. Please try again.'),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
// Error print removed
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Error accepting booking: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // View booking details functionality
  void _viewBookingDetails(Booking booking) {
// TODO: Replace with proper logging - print('🔍 Navigating to booking details: ${booking.id}');
// TODO: Replace with proper logging - print('🔍 Navigation path: /booking-details/${booking.id}');

    if (booking.id.isEmpty) {
// Error print removed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Booking ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Use Uri.encodeComponent to properly encode the booking ID for URL
      final encodedBookingId = Uri.encodeComponent(booking.id);
      final navigationPath = '/booking-details/$encodedBookingId';

// TODO: Replace with proper logging - print('🔍 Encoded navigation path: $navigationPath');

      context.push(navigationPath).then((result) {
        // If the booking was accepted or declined, refresh the data
        if (result == true) {
          ref.invalidate(dashboardDataProvider);
        }
      }).catchError((error) {
// Error print removed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } catch (e) {
// Error print removed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStatusToggleConfirmation(
      WidgetRef ref, Vendor? vendor, bool newStatus) async {
    if (vendor == null) return;

    final statusText = newStatus ? 'online' : 'offline';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                newStatus ? Icons.wifi : Icons.wifi_off,
                color: newStatus ? AppTheme.successColor : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Go $statusText?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            newStatus
                ? 'You will start receiving new orders and bookings.'
                : 'You will stop receiving new orders and bookings.',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
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
                backgroundColor: newStatus ? AppTheme.successColor : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Go $statusText',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _toggleOnlineStatusAdvanced(ref, vendor, newStatus);
    } else {
      // Force the switch to recreate with its original value
      // (handles cancel button, back gesture, and tapping outside)
      setState(() => _switchRebuildKey++);
    }
  }

  Future<void> _toggleOnlineStatusAdvanced(
      WidgetRef ref, Vendor? vendor, bool newStatus) async {
    if (vendor == null) return;

    // Optimistically update the UI immediately
    _onlineStatusController.value = newStatus;

    try {
      // Show haptic feedback
      HapticFeedback.lightImpact();

      // Update the vendor online status in database
      final vendorService = ref.read(vendor_service.vendorServiceProvider);
      final success =
          await vendorService.updateVendorOnlineStatus(vendor.id!, newStatus);

      if (!success) {
        throw Exception('Failed to update online status in database');
      }

      // Update the vendor provider state to keep it in sync
      ref.read(vendorProvider.notifier).updateOnlineStatus(newStatus);

      // Track the status change
      FirebaseAnalyticsService().logFeatureUsed(
        featureName: 'toggle_online_status',
        screenName: 'home_screen',
        additionalParams: {'new_status': newStatus.toString()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'You are now online and available for orders'
                  : 'You are now offline',
            ),
            backgroundColor:
                newStatus ? AppTheme.successColor : AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert the optimistic update on error
      _onlineStatusController.value = !newStatus;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleOnlineStatus(Vendor vendor, bool newStatus) async {
    if (vendor.id == null) return;

    // Set toggling flag and optimistic state
    setState(() {
      _isToggling = true;
      _isOnline = newStatus; // Show immediate feedback
    });

    try {
      // Update on server
      await ref
          .read(vendor_service.vendorServiceProvider)
          .updateVendorOnlineStatus(vendor.id!, newStatus);

      // Refresh provider data
      ref.invalidate(vendorProvider);

      // Give a moment for provider to update, then clear toggling flag
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    } catch (e) {
      // On error, clear toggling flag and let switch show server state
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  // Order-related helper methods
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return AppTheme.accentBlue;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'NEW';
      case 'confirmed':
        return 'CONFIRMED';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _showAcceptOrderConfirmation(Order order) async {
    final bool? shouldAccept = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.assignment_turned_in, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Accept Order?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to accept this order?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.serviceTitle ?? 'Order',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer(
                      builder: (context, ref, child) {
                        final orderValuesAsync =
                            ref.watch(orderValuesProvider(order));
                        return orderValuesAsync.when(
                          data: (orderValues) => Text(
                            '₹${orderValues['totalOrderValue']!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          error: (_, __) => Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                    if (order.customerName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${order.customerName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final isGuest =
                    ref.read(isGuestUserProvider).valueOrNull ?? false;
                Navigator.of(context).pop(); // Close the dialog
                if (isGuest) {
                  // Show login popup for guest users
                  _showLoginDialog();
                } else {
                  // For authenticated users, accept the order
                  await _acceptOrder(order);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept Order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Accepting order...'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final orderService = ref.read(orderServiceProvider);
      await orderService.updateOrderStatus(
        orderId: order.id ?? '',
        status: 'confirmed',
      );

      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Order Accepted Successfully! 🎉',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Customer will be notified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Refresh the data
        ref.invalidate(recentUnseenOrdersProvider);
        ref.invalidate(dashboardDataProvider);
      }
    } catch (e) {
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Error accepting order: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _viewOrderDetails(Order order) {
    // Check if user is a guest
    final isGuest = ref.read(isGuestUserProvider).valueOrNull ?? false;
    if (isGuest) {
      _showLoginDialog();
      return;
    }

    if (order.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Order ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Use Uri.encodeComponent to properly encode the order ID for URL
      final encodedOrderId = Uri.encodeComponent(order.id);
      final navigationPath = '/order-detail/$encodedOrderId';

      context.push(navigationPath).then((result) {
        // If the order was updated, refresh the data
        if (result == true) {
          ref.invalidate(recentUnseenOrdersProvider);
          ref.invalidate(dashboardDataProvider);
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please login to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/welcome');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  final String path;
  final String label;
  final String value;
  final Color color;
  final bool isLoading;
  final void Function(BuildContext)? onTap;

  const _HomeStatCard({
    required this.path,
    required this.label,
    required this.value,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Lottie.asset(
              path,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (isLoading)
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap!(context),
          borderRadius: BorderRadius.circular(16),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
