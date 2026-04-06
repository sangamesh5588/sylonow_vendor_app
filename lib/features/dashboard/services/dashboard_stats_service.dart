import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/dashboard_stats.dart';

final dashboardStatsServiceProvider = Provider<DashboardStatsService>((ref) {
  return DashboardStatsService();
});

class DashboardStatsService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<DashboardStats> getDashboardStats(String vendorId) async {
    try {
      // ── 1. Service listings count ──────────────────────────────────────────
      final serviceListingsResponse = await _client
          .from('service_listings')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('is_active', true);
      final totalServiceListings = serviceListingsResponse.length;

      // ── 2. All orders for this vendor ──────────────────────────────────────
      final ordersResponse = await _client
          .from('orders')
          .select('id, status, payment_status, booking_date, user_id, '
              'customer_phone, service_listing_id, total_amount')
          .eq('vendor_id', vendorId);

      final orders = ordersResponse as List;
      final totalOrders = orders.length;
      if (totalOrders == 0) {
        return _emptyStats(vendorId, totalServiceListings);
      }

      // ── 3. Batch-fetch offer prices for all unique service_listing_ids ─────
      final listingIds = orders
          .map((o) => o['service_listing_id'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, double> offerPriceMap = {};
      if (listingIds.isNotEmpty) {
        final listingsResponse = await _client
            .from('service_listings')
            .select('id, offer_price, price')
            .inFilter('id', listingIds);
        for (final l in listingsResponse as List) {
          final id = l['id'] as String;
          // prefer offer_price; fall back to price
          final op = (l['offer_price'] as num?)?.toDouble();
          final p  = (l['price'] as num?)?.toDouble() ?? 0.0;
          offerPriceMap[id] = (op != null && op > 0) ? op : p;
        }
      }

      // ── 4. Batch-fetch addon totals for all order ids ─────────────────────
      final orderIds = orders.map((o) => o['id'] as String).toList();
      final Map<String, double> addonTotalMap = {};
      if (orderIds.isNotEmpty) {
        final addonsResponse = await _client
            .from('order_add_ons')
            .select('order_id, quantity, price_at_booking')
            .inFilter('order_id', orderIds);
        for (final a in addonsResponse as List) {
          final oid = a['order_id'] as String;
          final qty = (a['quantity'] as num?)?.toDouble() ?? 1.0;
          final price = (a['price_at_booking'] as num?)?.toDouble() ?? 0.0;
          addonTotalMap[oid] = (addonTotalMap[oid] ?? 0.0) + (price * qty);
        }
      }

      // ── 5. Aggregate stats ────────────────────────────────────────────────
      double grossSales = 0.0;
      double totalRevenue = 0.0;
      int confirmedBookings = 0;
      int cancelledBookings = 0;
      int completedBookings = 0;
      int paidBookings = 0;
      int pendingPayments = 0;
      int failedPayments = 0;
      int todayBookings = 0;
      int thisMonthBookings = 0;
      double thisMonthRevenue = 0.0;
      int upcomingBookings = 0;
      final Set<String> uniqueCustomers = {};

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonth = DateTime(now.year, now.month);

      for (final order in orders) {
        final orderId = order['id'] as String;
        final status = (order['status'] as String? ?? '').toLowerCase();
        final paymentStatus = (order['payment_status'] as String? ?? '').toLowerCase();
        final bookingDate = DateTime.tryParse(order['booking_date'] as String? ?? '');
        final customerId = order['user_id'] as String? ?? '';
        final customerPhone = order['customer_phone'] as String? ?? '';
        final listingId = order['service_listing_id'] as String? ?? '';

        // Correct total = offer_price of service + sum(addons price_at_booking × qty)
        final servicePrice = offerPriceMap[listingId]
            ?? (order['total_amount'] as num?)?.toDouble()
            ?? 0.0;
        final addonTotal = addonTotalMap[orderId] ?? 0.0;
        final orderValue = servicePrice + addonTotal;

        // Gross Sales = confirmed + completed orders at their correct offer price
        if (status == 'confirmed' || status == 'completed' || status == 'started') {
          grossSales += orderValue;
        }
        totalRevenue += orderValue;

        // Status counts
        switch (status) {
          case 'confirmed':   confirmedBookings++;  break;
          case 'cancelled':   cancelledBookings++;  break;
          case 'completed':   completedBookings++;  break;
        }

        // Payment status counts
        switch (paymentStatus) {
          case 'paid':
          case 'completed':  paidBookings++;     break;
          case 'pending':    pendingPayments++;   break;
          case 'failed':     failedPayments++;    break;
        }

        // Unique customers
        if (customerId.isNotEmpty) {
          uniqueCustomers.add(customerId);
        } else if (customerPhone.isNotEmpty) {
          uniqueCustomers.add(customerPhone);
        }

        // Time-based counts
        if (bookingDate != null) {
          final dateOnly = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          if (dateOnly == today) todayBookings++;
          if (bookingDate.year == thisMonth.year && bookingDate.month == thisMonth.month) {
            thisMonthBookings++;
            thisMonthRevenue += orderValue;
          }
          if (bookingDate.isAfter(now) && status == 'confirmed') upcomingBookings++;
        }
      }

      final avgBookingValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      return DashboardStats(
        vendorId: vendorId,
        totalBookings: totalOrders,
        confirmedBookings: confirmedBookings,
        cancelledBookings: cancelledBookings,
        completedBookings: completedBookings,
        totalRevenue: totalRevenue,
        pendingRevenue: totalRevenue - grossSales,
        grossSales: grossSales,
        paidBookings: paidBookings,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        todayBookings: todayBookings,
        thisMonthBookings: thisMonthBookings,
        thisMonthRevenue: thisMonthRevenue,
        upcomingBookings: upcomingBookings,
        avgBookingValue: avgBookingValue,
        totalCustomers: uniqueCustomers.length,
        totalTheaters: totalServiceListings,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error fetching dashboard stats: $e');
      }
      // Return empty stats on error
      return _emptyStats(vendorId, 0);
    }
  }

  DashboardStats _emptyStats(String vendorId, int totalServiceListings) {
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
      avgBookingValue: 0.0,
      totalCustomers: 0,
      totalTheaters: totalServiceListings,
      lastUpdated: DateTime.now(),
    );
  }

  Future<int> getServiceListingsCount(String vendorId) async {
    try {
      final response = await _client
          .from('service_listings')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('is_active', true);
      
      return response.length;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error fetching service listings count: $e');
      }
      return 0;
    }
  }
}