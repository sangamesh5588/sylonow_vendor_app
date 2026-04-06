import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../models/dashboard_order.dart';
import '../models/dashboard_stats.dart';

final dashboardServiceProvider = Provider((ref) => DashboardService());

class DashboardService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<DashboardStats> getDashboardStats(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Getting dashboard stats for vendor: $vendorId');

      // Get the vendor's auth_user_id
      final vendorResponse = await _client
          .from('vendors')
          .select('auth_user_id')
          .eq('id', vendorId)
          .single();

      final authUserId = vendorResponse['auth_user_id'];

      // Get screen count across all theaters for the vendor
      int screenCount = 0;
      if (authUserId != null) {
        if (kDebugMode) {
          print('🔵 DEBUG: Getting theaters for auth_user_id: $authUserId');
        }

        // First get all theaters for this vendor
        final theaterResponse = await _client
            .from('private_theaters')
            .select('id')
            .eq('owner_id', authUserId);

        if (kDebugMode) {
          print('🔵 DEBUG: Found ${theaterResponse.length} theaters: $theaterResponse');
        }

        // Count screens across all theaters
        if (theaterResponse.isNotEmpty) {
          for (final theater in theaterResponse) {
            final theaterId = theater['id'] as String;
            if (kDebugMode) {
              print('🔵 DEBUG: Checking screens for theater_id: $theaterId');
            }

            final screenResponse = await _client
                .from('theater_screens')
                .select('id')
                .eq('theater_id', theaterId);

            if (kDebugMode) {
              print('🔵 DEBUG: Found ${screenResponse.length} screens for theater $theaterId: $screenResponse');
            }
            screenCount += screenResponse.length;
          }
        }
        if (kDebugMode) {
          print('🟢 DashboardService: Total found $screenCount screens for auth_user_id: $authUserId');
        }
      }

      // Get booking stats
      // Note: theater_booking_stats view uses owner_id (auth_user_id) as vendor_id
      // The view groups by theater_id, so we may have multiple rows per vendor
      try {
        final response = await _client
            .from('theater_booking_stats')
            .select('*')
            .eq('vendor_id', authUserId);

        if (response.isEmpty) {
// TODO: Replace with proper logging - print('🟡 DashboardService: No booking stats found, returning stats with screen count: $screenCount');
          return DashboardStats(
            vendorId: vendorId,
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
            totalCustomers: 0,
            totalTheaters: response.length,
            totalScreens: screenCount,
          );
        }

        // Aggregate stats from all theaters owned by this vendor
        int totalBookings = 0;
        int confirmedBookings = 0;
        int cancelledBookings = 0;
        int completedBookings = 0;
        double totalRevenue = 0.0;
        double pendingRevenue = 0.0;
        double grossSales = 0.0;
        int paidBookings = 0;
        int pendingPayments = 0;
        int failedPayments = 0;
        int todayBookings = 0;
        int thisMonthBookings = 0;
        double thisMonthRevenue = 0.0;
        int upcomingBookings = 0;
        int totalCustomers = 0;

        for (final row in response) {
          totalBookings += (row['total_bookings'] as num?)?.toInt() ?? 0;
          confirmedBookings += (row['confirmed_bookings'] as num?)?.toInt() ?? 0;
          cancelledBookings += (row['cancelled_bookings'] as num?)?.toInt() ?? 0;
          completedBookings += (row['completed_bookings'] as num?)?.toInt() ?? 0;
          totalRevenue += (row['total_revenue'] as num?)?.toDouble() ?? 0.0;
          pendingRevenue += (row['pending_revenue'] as num?)?.toDouble() ?? 0.0;
          grossSales += (row['gross_sales'] as num?)?.toDouble() ?? 0.0;
          paidBookings += (row['paid_bookings'] as num?)?.toInt() ?? 0;
          pendingPayments += (row['pending_payments'] as num?)?.toInt() ?? 0;
          failedPayments += (row['failed_payments'] as num?)?.toInt() ?? 0;
          todayBookings += (row['today_bookings'] as num?)?.toInt() ?? 0;
          thisMonthBookings += (row['this_month_bookings'] as num?)?.toInt() ?? 0;
          thisMonthRevenue += (row['this_month_revenue'] as num?)?.toDouble() ?? 0.0;
          upcomingBookings += (row['upcoming_bookings'] as num?)?.toInt() ?? 0;
          totalCustomers += (row['unique_customers'] as num?)?.toInt() ?? 0;
        }

// TODO: Replace with proper logging - print('🟢 DashboardService: Dashboard stats aggregated from ${response.length} theaters with $screenCount screens');
        return DashboardStats(
          vendorId: vendorId,
          totalBookings: totalBookings,
          confirmedBookings: confirmedBookings,
          cancelledBookings: cancelledBookings,
          completedBookings: completedBookings,
          totalRevenue: totalRevenue,
          pendingRevenue: pendingRevenue,
          grossSales: grossSales,
          paidBookings: paidBookings,
          pendingPayments: pendingPayments,
          failedPayments: failedPayments,
          todayBookings: todayBookings,
          thisMonthBookings: thisMonthBookings,
          thisMonthRevenue: thisMonthRevenue,
          upcomingBookings: upcomingBookings,
          totalCustomers: totalCustomers,
          totalTheaters: response.length,
          totalScreens: screenCount,
        );
      } catch (statsError) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error fetching stats: $statsError');
        rethrow;
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error getting dashboard stats: $e');
      // Return empty stats with screen count even when there's an error
      try {
        final vendorResponse = await _client
            .from('vendors')
            .select('auth_user_id')
            .eq('id', vendorId)
            .single();

        final authUserId = vendorResponse['auth_user_id'];

        int screenCount = 0;
        if (authUserId != null) {
          // First get all theaters for this vendor
          final theaterResponse = await _client
              .from('private_theaters')
              .select('id')
              .eq('owner_id', authUserId);

          // Count screens across all theaters
          if (theaterResponse.isNotEmpty) {
            for (final theater in theaterResponse) {
              final theaterId = theater['id'] as String;
              final screenResponse = await _client
                  .from('theater_screens')
                  .select('id')
                  .eq('theater_id', theaterId);
              screenCount += screenResponse.length;
            }
          }
        }

        return DashboardStats(
          vendorId: vendorId,
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
          totalCustomers: 0,
          totalTheaters: 0,
          totalScreens: screenCount,
        );
      } catch (fallbackError) {
        rethrow;
      }
    }
  }

  Future<List<DashboardOrder>> getPendingOrders(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Getting pending orders for vendor: $vendorId');

      final response = await _client
          .from('vendor_pending_orders')
          .select('*')
          .eq('vendor_id', vendorId)
          .order('booking_date', ascending: true)
          .limit(10);

// TODO: Replace with proper logging - print('🟢 DashboardService: Found ${response.length} pending orders');
      return response.map((json) => DashboardOrder.fromJson(json)).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error getting pending orders: $e');
      rethrow;
    }
  }

  Future<List<DashboardOrder>> getUpcomingOrders(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Getting upcoming orders for vendor: $vendorId');

      final response = await _client
          .from('vendor_upcoming_orders')
          .select('*')
          .eq('vendor_id', vendorId)
          .limit(5);

// TODO: Replace with proper logging - print('🟢 DashboardService: Found ${response.length} upcoming orders');
      return response.map((json) => DashboardOrder.fromJson(json)).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error getting upcoming orders: $e');
      rethrow;
    }
  }

  Future<OrderActionResult> acceptOrder(String orderId) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Accepting order: $orderId');

      final response = await _client
          .from('orders')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

// TODO: Replace with proper logging - print('🟢 DashboardService: Order accepted successfully');

      return OrderActionResult(
        success: true,
        message: 'Order accepted successfully',
        updatedOrder: DashboardOrder.fromJson(response),
      );
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error accepting order: $e');
      return OrderActionResult(
        success: false,
        message: 'Failed to accept order: ${e.toString()}',
      );
    }
  }

  Future<OrderActionResult> rejectOrder(String orderId,
      {String? reason}) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Rejecting order: $orderId');

      final updateData = {
        'status': 'rejected',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reason != null && reason.isNotEmpty) {
        updateData['rejection_reason'] = reason;
      }

      final response = await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .select()
          .single();

// TODO: Replace with proper logging - print('🟢 DashboardService: Order rejected successfully');

      return OrderActionResult(
        success: true,
        message: 'Order rejected successfully',
        updatedOrder: DashboardOrder.fromJson(response),
      );
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error rejecting order: $e');
      return OrderActionResult(
        success: false,
        message: 'Failed to reject order: ${e.toString()}',
      );
    }
  }

  Future<DashboardOrder> getOrderDetails(String orderId) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Getting order details: $orderId');

      final response =
          await _client.from('orders').select('*').eq('id', orderId).single();

// TODO: Replace with proper logging - print('🟢 DashboardService: Order details retrieved successfully');

      return DashboardOrder.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error getting order details: $e');
      rethrow;
    }
  }

  Future<bool> hasAnyTheaters(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 DashboardService: Checking if vendor has theaters: $vendorId');

      // First get the vendor's auth_user_id
      final vendorResponse = await _client
          .from('vendors')
          .select('auth_user_id')
          .eq('id', vendorId)
          .single();

      final authUserId = vendorResponse['auth_user_id'];
      if (authUserId == null) {
// TODO: Replace with proper logging - print('🔴 DashboardService: No auth_user_id found for vendor: $vendorId');
        return false;
      }

      // Then check theaters using auth_user_id
      final response = await _client
          .from('private_theaters')
          .select('id')
          .eq('owner_id', authUserId)
          .limit(1);

      final hasTheaters = response.isNotEmpty;
// TODO: Replace with proper logging - print('🟢 DashboardService: Vendor has theaters: $hasTheaters (auth_user_id: $authUserId)');

      return hasTheaters;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error checking theaters: $e');
      return false;
    }
  }

  Stream<DashboardStats> watchDashboardStats(String vendorId) async* {
    // First get the auth_user_id for the vendor
    String? authUserId;
    try {
      final vendorResponse = await _client
          .from('vendors')
          .select('auth_user_id')
          .eq('id', vendorId)
          .single();
      authUserId = vendorResponse['auth_user_id'];
    } catch (e) {
      // If we can't get auth_user_id, yield empty stats
      yield DashboardStats(
        vendorId: vendorId,
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
        totalCustomers: 0,
        totalTheaters: 0,
        totalScreens: 0,
      );
      return;
    }

    if (authUserId == null) {
      yield DashboardStats(
        vendorId: vendorId,
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
        totalCustomers: 0,
        totalTheaters: 0,
        totalScreens: 0,
      );
      return;
    }

    // Note: theater_booking_stats view uses owner_id (auth_user_id) as vendor_id
    final authId = authUserId; // Capture for use in closure
    yield* _client
        .from('theater_booking_stats')
        .stream(primaryKey: ['vendor_id'])
        .eq('vendor_id', authId)
        .asyncMap((data) async {
          // Get screen count for real-time updates
          int screenCount = 0;
          try {
            // First get all theaters for this vendor
            final theaterResponse = await _client
                .from('private_theaters')
                .select('id')
                .eq('owner_id', authId);

            // Count screens across all theaters
            if (theaterResponse.isNotEmpty) {
              for (final theater in theaterResponse) {
                final theaterId = theater['id'] as String;
                final screenResponse = await _client
                    .from('theater_screens')
                    .select('id')
                    .eq('theater_id', theaterId);
                screenCount += screenResponse.length;
              }
            }
          } catch (e) {
// TODO: Replace with proper logging - print('🔴 DashboardService: Error getting screen count in stream: $e');
          }

          if (data.isEmpty) {
            return DashboardStats(
              vendorId: vendorId,
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
              totalCustomers: 0,
              totalTheaters: 0,
              totalScreens: screenCount,
            );
          }

          // Aggregate stats from all theaters (view groups by theater_id)
          int totalBookings = 0;
          int confirmedBookings = 0;
          int cancelledBookings = 0;
          int completedBookings = 0;
          double totalRevenue = 0.0;
          double pendingRevenue = 0.0;
          double grossSales = 0.0;
          int paidBookings = 0;
          int pendingPayments = 0;
          int failedPayments = 0;
          int todayBookings = 0;
          int thisMonthBookings = 0;
          double thisMonthRevenue = 0.0;
          int upcomingBookings = 0;
          int totalCustomers = 0;

          for (final row in data) {
            totalBookings += (row['total_bookings'] as num?)?.toInt() ?? 0;
            confirmedBookings += (row['confirmed_bookings'] as num?)?.toInt() ?? 0;
            cancelledBookings += (row['cancelled_bookings'] as num?)?.toInt() ?? 0;
            completedBookings += (row['completed_bookings'] as num?)?.toInt() ?? 0;
            totalRevenue += (row['total_revenue'] as num?)?.toDouble() ?? 0.0;
            pendingRevenue += (row['pending_revenue'] as num?)?.toDouble() ?? 0.0;
            grossSales += (row['gross_sales'] as num?)?.toDouble() ?? 0.0;
            paidBookings += (row['paid_bookings'] as num?)?.toInt() ?? 0;
            pendingPayments += (row['pending_payments'] as num?)?.toInt() ?? 0;
            failedPayments += (row['failed_payments'] as num?)?.toInt() ?? 0;
            todayBookings += (row['today_bookings'] as num?)?.toInt() ?? 0;
            thisMonthBookings += (row['this_month_bookings'] as num?)?.toInt() ?? 0;
            thisMonthRevenue += (row['this_month_revenue'] as num?)?.toDouble() ?? 0.0;
            upcomingBookings += (row['upcoming_bookings'] as num?)?.toInt() ?? 0;
            totalCustomers += (row['unique_customers'] as num?)?.toInt() ?? 0;
          }

          return DashboardStats(
            vendorId: vendorId,
            totalBookings: totalBookings,
            confirmedBookings: confirmedBookings,
            cancelledBookings: cancelledBookings,
            completedBookings: completedBookings,
            totalRevenue: totalRevenue,
            pendingRevenue: pendingRevenue,
            grossSales: grossSales,
            paidBookings: paidBookings,
            pendingPayments: pendingPayments,
            failedPayments: failedPayments,
            todayBookings: todayBookings,
            thisMonthBookings: thisMonthBookings,
            thisMonthRevenue: thisMonthRevenue,
            upcomingBookings: upcomingBookings,
            totalCustomers: totalCustomers,
            totalTheaters: data.length,
            totalScreens: screenCount,
          );
        });
  }

  Stream<List<DashboardOrder>> watchPendingOrders(String vendorId) {
    return _client
        .from('vendor_pending_orders')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .order('booking_date', ascending: true)
        .limit(10)
        .map((data) =>
            data.map((json) => DashboardOrder.fromJson(json)).toList());
  }

  Stream<List<DashboardOrder>> watchUpcomingOrders(String vendorId) {
    return _client
        .from('vendor_upcoming_orders')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .limit(5)
        .map((data) =>
            data.map((json) => DashboardOrder.fromJson(json)).toList());
  }
}
