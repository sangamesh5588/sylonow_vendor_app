import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart'; // Temporarily disabled for iOS build

import '../../../core/services/fcm_service.dart';
import '../../../core/services/firebase_analytics_service.dart';
import '../../../core/services/location_permission_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/models/vendor.dart';
import '../../onboarding/providers/vendor_provider.dart';
import '../models/dashboard_stats.dart' as ds;
import '../models/private_theater.dart';
import '../models/theater_booking.dart';
import '../providers/dashboard_provider.dart';
import '../providers/theater_booking_provider.dart';
import '../providers/vendor_theaters_provider.dart';
import '../widgets/action_cards.dart';
import '../widgets/stats_grid.dart';

class TheaterDashboardScreen extends ConsumerStatefulWidget {
  const TheaterDashboardScreen({super.key});

  @override
  ConsumerState<TheaterDashboardScreen> createState() =>
      _TheaterDashboardScreenState();
}

class _TheaterDashboardScreenState
    extends ConsumerState<TheaterDashboardScreen> {
  int _selectedIndex = 0;
  late ValueNotifier<bool> _onlineStatusController;
  bool _isInitialized = false;
  bool _isStatusDialogOpen = false;
  int _statusSwitchRefreshSeed = 0;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _onlineStatusController = ValueNotifier<bool>(false);
    _selectedIndex = 0; // Always reset to home when screen initializes
    _audioPlayer = AudioPlayer();
    _setStatusBarColor();
    _setupNotificationListener();

    // Track screen view and upsert FCM token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService()
          .logScreenView(screenName: 'theater_dashboard_screen');
      _upsertFCMToken();
      _checkAndRequestMandatoryLocation();
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

  @override
  void dispose() {
    _onlineStatusController.dispose();
    _audioPlayer.dispose();
    super.dispose();
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

  void _setupNotificationListener() {
    // Temporarily disabled for iOS build
    /*
    // Listen for notification opened events
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
      _handleNotificationOpened(event.notification);
    });

    // Listen for foreground notification events
    OneSignal.Notifications.addForegroundWillDisplayListener(
        (OSNotificationWillDisplayEvent event) {
      _handleForegroundNotification(event.notification);
    });
    */
  }

  Future<void> _upsertFCMToken() async {
    try {
      final vendor = ref.read(vendorProvider).value;
      if (vendor?.id != null) {
        await FCMService.upsertTokenToVendor(vendor!.id!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error upserting FCM token in theater dashboard: $e');
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
            final vendorService = ref.read(vendorServiceProvider);
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

  // Temporarily disabled for iOS build
  /*
  void _handleNotificationOpened(OSNotification notification) {
    final data = notification.additionalData ?? {};
    final notificationType = data['type'] as String?;

    if (kDebugMode) {
      print('🔔 Notification opened: $notificationType');
    }

    // Navigate based on notification type
    switch (notificationType) {
      case 'new_theater_booking':
      case 'theater_booking_update':
        final bookingId = data['booking_id'] as String?;
        if (bookingId != null) {
          context.push('/theater-bookings/$bookingId');
        } else {
          context.push('/theater-bookings');
        }
        break;
      case 'new_order':
      case 'order_update':
        final orderId = data['order_id'] as String?;
        if (orderId != null) {
          context.push('/orders/$orderId');
        } else {
          context.push('/orders');
        }
        break;
      default:
        // Default to dashboard
        break;
    }
  }

  void _handleForegroundNotification(OSNotification notification) async {
    final data = notification.additionalData ?? {};
    final notificationType = data['type'] as String?;

    if (kDebugMode) {
      print('🔔 Foreground notification received: $notificationType');
    }

    // Play notification sound based on type
    if (notificationType == 'new_theater_booking' ||
        notificationType == 'new_order') {
      await _playNewOrderSound();
      _showNewOrderSnackBar(notification, notificationType);
    } else if (notificationType?.contains('update') == true) {
      await _playUpdateSound();
      _showUpdateSnackBar(notification, notificationType);
    }

    // Refresh dashboard data to show new notifications
    _handleRefresh();
  }

  Future<void> _playNewOrderSound() async {
    try {
      // Play system notification sound first
      await SystemSound.play(SystemSoundType.alert);

      // Then play custom sound (if available)
      // You can add custom sound files in assets/sounds/
      // await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing new order sound: $e');
      }
    }
  }

  Future<void> _playUpdateSound() async {
    try {
      // Play a softer sound for updates
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      if (kDebugMode) {
        print('Error playing update sound: $e');
      }
    }
  }

  void _showNewOrderSnackBar(OSNotification notification, String? type) {
    if (!mounted) return;

    String title = '🎭 New Theater Booking!';
    String message = notification.body ?? 'You have a new theater booking';

    if (type == 'new_order') {
      title = '🛍️ New Order!';
      message = notification.body ?? 'You have a new decoration order';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            _handleNotificationOpened(notification);
          },
        ),
      ),
    );
  }

  void _showUpdateSnackBar(OSNotification notification, String? type) {
    if (!mounted) return;

    String title = '📋 Booking Updated';
    if (type?.contains('theater') == true) {
      title = '🎭 Theater Booking Updated';
    } else if (type?.contains('order') == true) {
      title = '📦 Order Updated';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              notification.body ?? 'Status updated',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorProvider);
    final vendorTheatersAsync = ref.watch(vendorTheatersProvider);
    final bookingStatsAsync = ref.watch(bookingStatsProvider);
    final allBookingsAsync =
        ref.watch(vendorBookingsProvider); // For accurate total count
    // 'confirmed' + payment_status='pending' = new bookings awaiting vendor attention
    final pendingOrdersAsync = ref.watch(filteredBookingsProvider('confirmed'));
    final upcomingOrdersAsync = ref.watch(upcomingBookingsProvider);
    final hasTheatersAsync = ref.watch(vendorHasTheatersProvider);

    // Initialize controller with vendor data only once
    vendorAsync.whenData((vendor) {
      if (vendor != null && !_isInitialized) {
        final vendorOnlineStatus = vendor.isOnline == true;
        _onlineStatusController.value = vendorOnlineStatus;
        _isInitialized = true;
// TODO: Replace with proper logging - print('🟢 Initialized online status controller with: $vendorOnlineStatus');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Header
          _buildHeader(vendorAsync, vendorTheatersAsync),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(_getResponsivePadding(context), 24,
                    _getResponsivePadding(context), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner for theaters without screens
                    _buildNoScreensInfoBanner(
                        hasTheatersAsync, bookingStatsAsync),

                    // Stats Grid (2x2 responsive)
                    // Use actual bookings count from vendorBookingsProvider
                    Builder(
                      builder: (context) {
                        final actualBookingsCount = allBookingsAsync.whenOrNull(
                          data: (bookings) => bookings.length,
                        );

                        // Compute money stats from actual booking data
                        // using the correct pricing formula (not DB total_amount)
                        final moneyStats = allBookingsAsync.whenOrNull(
                          data: (bookings) => _computeMoneyStats(bookings),
                        );

                        return bookingStatsAsync.when(
                          data: (stats) => StatsGrid(
                            stats: _convertBookingStatsToGridStats(
                              stats,
                              overrideTotalBookings: actualBookingsCount,
                              overrideGrossSales: moneyStats?['grossSales'],
                              overrideTotalRevenue: moneyStats?['totalRevenue'],
                              overridePendingRevenue:
                                  moneyStats?['pendingRevenue'],
                            ),
                            isLoading: false,
                          ),
                          loading: () => const StatsGrid(
                            stats: null,
                            isLoading: true,
                          ),
                          error: (error, stack) => const StatsGrid(
                            stats: null,
                            isLoading: false,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Action Cards
                    hasTheatersAsync.when(
                      data: (hasTheaters) =>
                          ActionCards(hasTheaters: hasTheaters),
                      loading: () => const ActionCards(hasTheaters: false),
                      error: (error, stack) =>
                          const ActionCards(hasTheaters: false),
                    ),

                    const SizedBox(height: 8),

                    // Additional Action Cards
                    hasTheatersAsync.when(
                      data: (hasTheaters) =>
                          _buildAdditionalActionCards(hasTheaters),
                      loading: () => _buildAdditionalActionCards(false),
                      error: (error, stack) =>
                          _buildAdditionalActionCards(false),
                    ),

                    const SizedBox(height: 32),

                    // Orders Section - Theater Bookings
                    pendingOrdersAsync.when(
                      data: (bookings) => _buildTheaterBookingsSection(
                          bookings, 'Pending Theater Bookings'),
                      loading: () => _buildTheaterBookingsLoadingSection(),
                      error: (error, stack) => _buildTheaterBookingsSection(
                          [], 'Pending Theater Bookings'),
                    ),

                    const SizedBox(height: 24),

                    // Upcoming Theater Bookings List
                    upcomingOrdersAsync.when(
                      data: (bookings) =>
                          _buildUpcomingTheaterBookings(bookings),
                      loading: () =>
                          _buildUpcomingTheaterBookingsLoadingSkeleton(),
                      error: (error, stack) =>
                          _buildUpcomingTheaterBookings([]),
                    ),

                    // Bottom padding for navigation bar
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 80,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  ds.DashboardStats _convertBookingStatsToGridStats(
      Map<String, dynamic> bookingStats,
      {int? overrideTotalBookings,
      double? overrideGrossSales,
      double? overrideTotalRevenue,
      double? overridePendingRevenue}) {
    return ds.DashboardStats(
      vendorId: bookingStats['vendor_id']?.toString() ?? '',
      totalBookings:
          overrideTotalBookings ?? bookingStats['total_bookings'] ?? 0,
      confirmedBookings: bookingStats['confirmed_bookings'] ?? 0,
      cancelledBookings: bookingStats['cancelled_bookings'] ?? 0,
      completedBookings: bookingStats['completed_bookings'] ?? 0,
      totalRevenue: overrideTotalRevenue ??
          bookingStats['total_revenue']?.toDouble() ?? 0.0,
      pendingRevenue: overridePendingRevenue ??
          bookingStats['pending_revenue']?.toDouble() ?? 0.0,
      grossSales: overrideGrossSales ??
          bookingStats['gross_sales']?.toDouble() ?? 0.0,
      paidBookings: bookingStats['paid_bookings'] ?? 0,
      pendingPayments: bookingStats['pending_payments'] ?? 0,
      failedPayments: bookingStats['failed_payments'] ?? 0,
      todayBookings: bookingStats['today_bookings'] ?? 0,
      thisMonthBookings: bookingStats['this_month_bookings'] ?? 0,
      thisMonthRevenue: bookingStats['this_month_revenue']?.toDouble() ?? 0.0,
      upcomingBookings: bookingStats['upcoming_bookings'] ?? 0,
      avgBookingValue: bookingStats['avg_booking_value']?.toDouble(),
      totalCustomers: bookingStats['total_customers'] ?? 0,
      totalTheaters: bookingStats['total_theaters'] ?? 0,
      totalScreens: bookingStats['total_screens'] ?? 0,
      lastUpdated: bookingStats['last_updated'] != null
          ? DateTime.tryParse(bookingStats['last_updated'].toString())
          : null,
    );
  }

  /// Builds an info banner prompting users to add screens if they have theaters but no screens
  Widget _buildNoScreensInfoBanner(
    AsyncValue<bool> hasTheatersAsync,
    AsyncValue<Map<String, dynamic>> bookingStatsAsync,
  ) {
    return hasTheatersAsync.when(
      data: (hasTheaters) {
        if (!hasTheaters) return const SizedBox.shrink();

        return bookingStatsAsync.when(
          data: (stats) {
            final totalScreens = stats['total_screens'] ?? 0;
            if (totalScreens > 0) return const SizedBox.shrink();

            // Show info banner when vendor has theaters but no screens
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.warningColor.withValues(alpha: 0.15),
                    AppTheme.warningColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => context.push('/vendor-screens'),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_to_queue_rounded,
                        color: AppTheme.warningColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Your First Screen',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create screens to start receiving bookings',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.warningColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAdditionalActionCards(bool hasTheaters) {
    return Row(
      children: [
        // Add Extra Service Card - Always visible
        Expanded(
          child: _buildActionCard(
            title: 'Add Extra Service',
            subtitle: 'Boost revenue with add-ons',
            icon: Icons.add_circle_outline_rounded,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            onTap: () => context.push('/addons'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    try {
      if (kDebugMode) {
// TODO: Replace with proper logging - print('🔄 Refreshing dashboard data...');
      }

      // Track refresh action
      FirebaseAnalyticsService().logFeatureUsed(
        featureName: 'pull_to_refresh',
        screenName: 'theater_dashboard_screen',
      );

      // Show haptic feedback
      HapticFeedback.lightImpact();

      // Refresh all providers
      await Future.wait([
        ref.read(bookingStatsProvider.notifier).refresh(),
        ref.read(filteredBookingsProvider('confirmed').notifier).refresh(),
        ref.read(upcomingBookingsProvider.notifier).refresh(),
        ref.read(vendorHasTheatersProvider.notifier).refresh(),
      ]);

      if (kDebugMode) {
// TODO: Replace with proper logging - print('🟢 Dashboard refresh completed');
      }
    } catch (e) {
      if (kDebugMode) {
// TODO: Replace with proper logging - print('🔴 Dashboard refresh failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showStatusToggleConfirmation(
      WidgetRef ref, Vendor? vendor, bool newStatus) async {
    if (vendor == null) return;
    if (_isStatusDialogOpen) return;
    _isStatusDialogOpen = true;

    final statusText = newStatus ? 'online' : 'offline';
    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    newStatus ? Icons.wifi : Icons.wifi_off,
                    color:
                        newStatus ? AppTheme.successColor : AppTheme.warningColor,
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
                    ? 'You will start receiving new theater bookings and orders.'
                    : 'You will stop receiving new theater bookings and orders.',
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
                    backgroundColor:
                        newStatus ? AppTheme.successColor : AppTheme.warningColor,
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
        ) ??
        false;

    _isStatusDialogOpen = false;

    if (confirmed) {
      _toggleOnlineStatus(ref, vendor, newStatus);
      return;
    }

    // Force switch widget to rebuild to current actual status.
    if (mounted) {
      setState(() {
        _statusSwitchRefreshSeed++;
      });
    }
  }

  Future<void> _toggleOnlineStatus(
      WidgetRef ref, Vendor? vendor, bool newStatus) async {
    if (vendor == null) return;

// TODO: Replace with proper logging - print('🔄 Toggling online status from ${_onlineStatusController.value} to $newStatus');

    // Optimistically update the UI immediately
    _onlineStatusController.value = newStatus;
// TODO: Replace with proper logging - print('🔵 Controller value set to: ${_onlineStatusController.value}');

    try {
      // Show haptic feedback
      HapticFeedback.lightImpact();

      // Update the vendor online status in database
      final vendorService = ref.read(vendorServiceProvider);
      final success =
          await vendorService.updateVendorOnlineStatus(vendor.id!, newStatus);

      if (!success) {
        throw Exception('Failed to update online status in database');
      }

// TODO: Replace with proper logging - print('🟢 Database update successful');

      // Update the vendor provider state to keep it in sync
      ref.read(vendorProvider.notifier).updateOnlineStatus(newStatus);

      // Track the status change
      FirebaseAnalyticsService().logFeatureUsed(
        featureName: 'toggle_online_status',
        screenName: 'theater_dashboard_screen',
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
// TODO: Replace with proper logging - print('🔴 Error during toggle: $e, reverting UI state');
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

  Widget _buildHeader(AsyncValue vendorAsync,
      AsyncValue<List<PrivateTheater>> vendorTheatersAsync) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 15, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: vendorAsync.when(
        data: (vendor) => Column(
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
                  ),
                  child: ClipOval(
                    child: _buildHeaderProfileImage(vendor),
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 14,
                          // ignore: deprecated_member_use
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendor?.businessName ?? 'Theater Owner',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vendor?.vendorId != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.theaters_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ' ${vendor!.vendorId!}',
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
                                    ? Theme.of(context).colorScheme.onPrimary
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
                                    '$isOnline-$_statusSwitchRefreshSeed'),
                                initialValue: isOnline,
                                activeChild: const Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                inactiveChild: const Text(
                                  'Offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                activeColor: Colors.green,
                                inactiveColor: Colors.grey,
                                width: 80.0,
                                height: 32.0,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(16)),
                                onChanged: (value) =>
                                    _showStatusToggleConfirmation(
                                        ref, vendor, value),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const HeroIcon(
                          HeroIcons.bell,
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
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: vendorTheatersAsync.when(
                    data: (theaters) {
                      String locationText = 'Theater Location';
                      if (theaters.isNotEmpty) {
                        final theater = theaters.first;
                        final parts = <String>[];
                        if (theater.address.isNotEmpty) {
                          parts.add(theater.address);
                        }
                        if (theater.city.isNotEmpty) {
                          parts.add(theater.city);
                        }
                        if (theater.state.isNotEmpty) {
                          parts.add(theater.state);
                        }
                        locationText = parts.isEmpty
                            ? 'Theater Location'
                            : parts.join(', ');
                      }
                      return Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    loading: () => Text(
                      'Loading location...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    error: (error, stack) => Text(
                      'Theater Location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => _buildHeaderSkeleton(),
        error: (error, stack) => _buildHeaderError(),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 18,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderError() {
    return const Row(
      children: [
        Icon(
          Icons.theaters_rounded,
          color: Colors.white,
          size: 28,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Theater Owner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderProfileImage(Vendor vendor) {
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
          return Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.theaters_rounded,
              color: AppTheme.primaryColor,
              size: 28,
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
          Icons.theaters_rounded,
          color: AppTheme.primaryColor,
          size: 28,
        ),
      );
    }
  }

  Map<String, double> _computeMoneyStats(List<TheaterBooking> bookings) {
    double grossSales = 0.0;
    double totalRevenue = 0.0;
    double pendingRevenue = 0.0;

    for (final booking in bookings) {
      if (booking.bookingStatus.toLowerCase() == 'cancelled') continue;
      final total = _computeCorrectTotal(booking);
      grossSales += total;
      if (booking.paymentStatus.toLowerCase() == 'paid') {
        totalRevenue += total;
      } else if (booking.paymentStatus.toLowerCase() == 'pending') {
        pendingRevenue += total;
      }
    }

    return {
      'grossSales': grossSales,
      'totalRevenue': totalRevenue,
      'pendingRevenue': pendingRevenue,
    };
  }

  double _computeCorrectTotal(TheaterBooking booking) {
    final addonsTotal = booking.selectedAddons
        .map((a) => (a as Map<String, dynamic>)['total_price'] as num? ?? 0)
        .fold<double>(0, (sum, v) => sum + v.toDouble());
    final hasCapacityLimit = booking.allowedCapacity > 0;
    final extraPersons = hasCapacityLimit
        ? (booking.numberOfPeople - booking.allowedCapacity).clamp(0, 999)
        : 0;
    final extraCharges =
        extraPersons > 0 ? extraPersons * booking.chargesExtraPerPerson : 0.0;
    return booking.slotBasePrice + addonsTotal + extraCharges;
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

  // Helper method for responsive padding
  double _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return 32.0; // Desktop
    } else if (screenWidth >= 600) {
      return 24.0; // Tablet
    } else {
      return 16.0; // Mobile
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                onTap: () => _handleNavTap(1, '/theater-bookings'),
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
                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
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
                      ? AppTheme.primaryColor
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

  Widget _buildUpcomingTheaterBookings(List<TheaterBooking> bookings) {
    if (bookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Theater Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/theater-bookings'),
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
        ...bookings.map((booking) => _buildUpcomingTheaterBookingCard(booking)),
      ],
    );
  }

  Widget _buildUpcomingTheaterBookingCard(TheaterBooking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.theaters_rounded,
              color: AppTheme.successColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.celebrationName ?? 'Theater Booking',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  booking.contactName ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTheaterBookingDate(booking.bookingDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(_computeCorrectTotal(booking)),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getBookingStatusText(booking.bookingStatus ?? 'pending'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTheaterBookingsLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 180,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          2,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTheaterBookingDate(DateTime? date) {
    if (date == null) return 'Date TBD';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  String _getBookingStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Widget _buildTheaterBookingsSection(
      List<TheaterBooking> bookings, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            if (bookings.isNotEmpty)
              TextButton(
                onPressed: () => context.push('/theater-bookings'),
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
        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_available_outlined,
                    size: 20, color: AppTheme.textSecondaryColor),
                SizedBox(width: 12),
                Text(
                  'No pending bookings right now',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...bookings
              .take(3)
              .map((booking) => _buildTheaterBookingCard(booking)),
      ],
    );
  }

  Widget _buildTheaterBookingsLoadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 180,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTheaterBookingCard(TheaterBooking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/theater-bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    _getBookingStatusColor(booking.bookingStatus ?? 'pending')
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.theaters_rounded,
                color:
                    _getBookingStatusColor(booking.bookingStatus ?? 'pending'),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.celebrationName ?? 'Theater Booking',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.contactName ?? 'Customer',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTheaterBookingDate(booking.bookingDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.startTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(_computeCorrectTotal(booking)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getBookingStatusColor(
                            booking.bookingStatus ?? 'pending')
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getBookingStatusText(booking.bookingStatus ?? 'pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getBookingStatusColor(
                          booking.bookingStatus ?? 'pending'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      case 'completed':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }
}
