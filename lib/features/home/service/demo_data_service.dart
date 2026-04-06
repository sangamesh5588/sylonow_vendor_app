import 'package:flutter/material.dart';
import 'package:sylonow_vendor/features/dashboard/models/dashboard_data.dart';
import 'package:sylonow_vendor/features/dashboard/models/dashboard_stats.dart';
import 'package:sylonow_vendor/features/dashboard/models/activity_item.dart';
import 'package:sylonow_vendor/features/orders/models/order.dart';

/// Service to provide demo data for guest users
class DemoDataService {
  /// Get demo dashboard data
  static DashboardData getDemoDashboardData(String businessType) {
    return DashboardData(
      stats: getDemoStats(businessType),
      latestPendingBooking: null, // Guests don't see pending bookings
      recentActivities: getDemoRecentActivities(businessType),
    );
  }

  /// Get demo dashboard stats
  static DashboardStats getDemoStats(String businessType) {
    // Different stats based on business type
    if (businessType == 'Private Theater') {
      return DashboardStats(
        vendorId: 'demo-vendor-id',
        totalBookings: 24,
        confirmedBookings: 18,
        cancelledBookings: 2,
        completedBookings: 15,
        totalRevenue: 45000.0,
        pendingRevenue: 12000.0,
        grossSales: 45000.0,
        paidBookings: 15,
        pendingPayments: 6,
        failedPayments: 1,
        todayBookings: 2,
        thisMonthBookings: 8,
        thisMonthRevenue: 18000.0,
        upcomingBookings: 6,
        avgBookingValue: 1875.0,
        totalCustomers: 22,
        totalTheaters: 3,
        lastUpdated: DateTime.now(),
      );
    } else {
      // Event Decorator stats
      return DashboardStats(
        vendorId: 'demo-vendor-id',
        totalBookings: 32,
        confirmedBookings: 25,
        cancelledBookings: 3,
        completedBookings: 20,
        totalRevenue: 62000.0,
        pendingRevenue: 15000.0,
        grossSales: 62000.0,
        paidBookings: 20,
        pendingPayments: 8,
        failedPayments: 2,
        todayBookings: 3,
        thisMonthBookings: 12,
        thisMonthRevenue: 25000.0,
        upcomingBookings: 8,
        avgBookingValue: 1937.5,
        totalCustomers: 28,
        totalTheaters: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get demo orders
  static List<Order> getDemoOrders(String businessType) {
    if (businessType == 'Private Theater') {
      return [
        Order(
          id: 'demo-order-1',
          serviceListingId: 'demo-service-1',
          serviceTitle: 'Premium Private Theater Experience',
          bookingDate: DateTime.now().add(const Duration(days: 3)),
          totalAmount: 2500.0,
          status: 'confirmed',
          customerName: 'Rajesh Kumar',
          customerPhone: '+91 98765 43210',
          customerEmail: 'rajesh.k@example.com',
          bookingTime: '7:00 PM - 10:00 PM',
          paymentStatus: 'paid',
          specialRequirements: 'Anniversary celebration, need romantic setup',
          venueAddress: 'MG Road, Bangalore',
          durationHours: 3,
          advanceAmount: 1000.0,
          remainingAmount: 1500.0,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          confirmedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Order(
          id: 'demo-order-2',
          serviceListingId: 'demo-service-1',
          serviceTitle: 'Deluxe Theater Package',
          bookingDate: DateTime.now().add(const Duration(days: 5)),
          totalAmount: 3200.0,
          status: 'pending',
          customerName: 'Priya Sharma',
          customerPhone: '+91 98765 12345',
          customerEmail: 'priya.s@example.com',
          bookingTime: '5:00 PM - 9:00 PM',
          paymentStatus: 'pending',
          specialRequirements: 'Birthday party with cake arrangement',
          venueAddress: 'Koramangala, Bangalore',
          durationHours: 4,
          advanceAmount: 0.0,
          remainingAmount: 3200.0,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Order(
          id: 'demo-order-3',
          serviceListingId: 'demo-service-2',
          serviceTitle: 'Standard Theater Booking',
          bookingDate: DateTime.now().subtract(const Duration(days: 2)),
          totalAmount: 1800.0,
          status: 'completed',
          customerName: 'Amit Patel',
          customerPhone: '+91 98765 67890',
          customerEmail: 'amit.p@example.com',
          bookingTime: '3:00 PM - 6:00 PM',
          paymentStatus: 'paid',
          venueAddress: 'Indiranagar, Bangalore',
          durationHours: 3,
          advanceAmount: 800.0,
          remainingAmount: 1000.0,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          confirmedAt: DateTime.now().subtract(const Duration(days: 4)),
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    } else {
      // Event Decorator orders
      return [
        Order(
          id: 'demo-order-1',
          serviceListingId: 'demo-service-1',
          serviceTitle: 'Birthday Party Decoration',
          bookingDate: DateTime.now().add(const Duration(days: 4)),
          totalAmount: 3500.0,
          status: 'confirmed',
          customerName: 'Sneha Reddy',
          customerPhone: '+91 98765 11111',
          customerEmail: 'sneha.r@example.com',
          bookingTime: '10:00 AM',
          paymentStatus: 'partial',
          specialRequirements: 'Unicorn theme for 5 year old',
          venueAddress: 'Whitefield, Bangalore',
          durationHours: 4,
          advanceAmount: 1500.0,
          remainingAmount: 2000.0,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          confirmedAt: DateTime.now().subtract(const Duration(days: 2)),
          setupTime: '3 hours',
        ),
        Order(
          id: 'demo-order-2',
          serviceListingId: 'demo-service-2',
          serviceTitle: 'Wedding Anniversary Decoration',
          bookingDate: DateTime.now().add(const Duration(days: 7)),
          totalAmount: 5800.0,
          status: 'pending',
          customerName: 'Vikram Singh',
          customerPhone: '+91 98765 22222',
          customerEmail: 'vikram.s@example.com',
          bookingTime: '6:00 PM',
          paymentStatus: 'pending',
          specialRequirements: 'Silver jubilee celebration, elegant setup',
          venueAddress: 'JP Nagar, Bangalore',
          durationHours: 5,
          advanceAmount: 0.0,
          remainingAmount: 5800.0,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          setupTime: '4 hours',
        ),
        Order(
          id: 'demo-order-3',
          serviceListingId: 'demo-service-3',
          serviceTitle: 'Baby Shower Decoration',
          bookingDate: DateTime.now().subtract(const Duration(days: 1)),
          totalAmount: 2800.0,
          status: 'completed',
          customerName: 'Divya Menon',
          customerPhone: '+91 98765 33333',
          customerEmail: 'divya.m@example.com',
          bookingTime: '11:00 AM',
          paymentStatus: 'paid',
          specialRequirements: 'Pastel colors, balloon arch',
          venueAddress: 'HSR Layout, Bangalore',
          durationHours: 3,
          advanceAmount: 1200.0,
          remainingAmount: 1600.0,
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          confirmedAt: DateTime.now().subtract(const Duration(days: 5)),
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          setupTime: '2 hours',
        ),
      ];
    }
  }

  /// Get demo recent activities
  static List<ActivityItem> getDemoRecentActivities(String businessType) {
    if (businessType == 'Private Theater') {
      return [
        ActivityItem(
          id: 'demo-activity-1',
          type: ActivityType.booking,
          title: 'New Booking Received',
          subtitle: 'Premium Theater - Rajesh Kumar',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          icon: Icons.event_available,
          iconColor: Colors.green,
          status: 'confirmed',
        ),
        ActivityItem(
          id: 'demo-activity-2',
          type: ActivityType.payment,
          title: 'Payment Received',
          subtitle: '₹2,500 for booking #PT1234',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          icon: Icons.payment,
          iconColor: Colors.blue,
          status: 'paid',
        ),
        ActivityItem(
          id: 'demo-activity-3',
          type: ActivityType.booking,
          title: 'Booking Completed',
          subtitle: 'Deluxe Package - Amit Patel',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          icon: Icons.check_circle,
          iconColor: Colors.green,
          status: 'completed',
        ),
      ];
    } else {
      // Event Decorator activities
      return [
        ActivityItem(
          id: 'demo-activity-1',
          type: ActivityType.booking,
          title: 'New Order Received',
          subtitle: 'Birthday Decoration - Sneha Reddy',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          icon: Icons.celebration,
          iconColor: Colors.purple,
          status: 'confirmed',
        ),
        ActivityItem(
          id: 'demo-activity-2',
          type: ActivityType.payment,
          title: 'Advance Payment Received',
          subtitle: '₹1,500 for order #BD5678',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          icon: Icons.account_balance_wallet,
          iconColor: Colors.blue,
          status: 'paid',
        ),
        ActivityItem(
          id: 'demo-activity-3',
          type: ActivityType.booking,
          title: 'Decoration Completed',
          subtitle: 'Baby Shower - Divya Menon',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          icon: Icons.done_all,
          iconColor: Colors.green,
          status: 'completed',
        ),
      ];
    }
  }
}
