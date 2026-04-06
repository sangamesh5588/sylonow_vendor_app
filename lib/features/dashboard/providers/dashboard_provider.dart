import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylonow_vendor/core/providers/auth_provider.dart';
import 'package:sylonow_vendor/features/dashboard/models/dashboard_data.dart';
import 'package:sylonow_vendor/features/dashboard/models/dashboard_stats.dart';
import 'package:sylonow_vendor/features/dashboard/models/activity_item.dart';
import '../services/recent_activity_service.dart';
import '../services/dashboard_stats_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../../onboarding/providers/vendor_provider.dart';

final recentActivityServiceProvider = Provider<RecentActivityService>((ref) {
  return RecentActivityService();
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

// TODO: Replace with proper logging - print('🔄 Loading dashboard data for user: ${user.id}');

  // Get vendor info first
  final vendorAsync = ref.watch(vendorProvider);
  final vendor = await vendorAsync.when(
    data: (vendor) async => vendor,
    loading: () async => null,
    error: (_, __) async => null,
  );

  if (vendor?.id == null) {
    throw Exception('Vendor not found');
  }

  DashboardStats dashboardStats;
  Booking? latestPendingBooking;
  
  try {
    // Get real dashboard stats using our new service
    final dashboardStatsService = ref.read(dashboardStatsServiceProvider);
    dashboardStats = await dashboardStatsService.getDashboardStats(vendor!.id!);
    
    // Get latest pending booking
    final bookingService = BookingService();
    final pendingBookings = await bookingService.getRecentPendingBookings(vendor.id!, limit: 1);
    latestPendingBooking = pendingBookings.isNotEmpty ? pendingBookings.first : null;
    
// TODO: Replace with proper logging - print('🟢 Dashboard stats loaded: ${dashboardStats.totalBookings} orders, ${dashboardStats.totalTheaters} listings');
  } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error loading dashboard stats: $e');
    
    // Fallback: Create empty dashboard stats
    dashboardStats = DashboardStats(
      vendorId: vendor!.id!,
      totalBookings: 0,
      confirmedBookings: 0,
      cancelledBookings: 0,
      completedBookings: 0,
      totalRevenue: 0.0,
      pendingRevenue: 0.0,
      grossSales: 0.0,
      paidBookings: 0,
      pendingPayments: 0,
      failedPayments: 0,
      todayBookings: 0,
      thisMonthBookings: 0,
      thisMonthRevenue: 0.0,
      upcomingBookings: 0,
      avgBookingValue: 0.0,
      totalCustomers: 0,
      totalTheaters: 0,
      lastUpdated: DateTime.now(),
    );
    latestPendingBooking = null;
  }

  // Get recent activities
  final recentActivities = await vendorAsync.when(
    data: (vendor) async {
      if (vendor?.id != null) {
        final activityService = ref.read(recentActivityServiceProvider);
        return await activityService.getRecentActivities(vendor!.id!);
      }
      return <ActivityItem>[];
    },
    loading: () async => <ActivityItem>[],
    error: (_, __) async => <ActivityItem>[],
  );

  // Create dashboard data
  final dashboardData = DashboardData(
    stats: dashboardStats,
    latestPendingBooking: latestPendingBooking,
    recentActivities: recentActivities,
  );

  return dashboardData;
}); 