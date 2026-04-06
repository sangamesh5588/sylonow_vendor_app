import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    @JsonKey(name: 'vendor_id') required String vendorId,
    @JsonKey(name: 'total_bookings') required int totalBookings,
    @JsonKey(name: 'confirmed_bookings') required int confirmedBookings,
    @JsonKey(name: 'cancelled_bookings') required int cancelledBookings,
    @JsonKey(name: 'completed_bookings') required int completedBookings,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'pending_revenue') required double pendingRevenue,
    @JsonKey(name: 'gross_sales') required double grossSales,
    @JsonKey(name: 'paid_bookings') required int paidBookings,
    @JsonKey(name: 'pending_payments') required int pendingPayments,
    @JsonKey(name: 'failed_payments') required int failedPayments,
    @JsonKey(name: 'today_bookings') required int todayBookings,
    @JsonKey(name: 'this_month_bookings') required int thisMonthBookings,
    @JsonKey(name: 'this_month_revenue') required double thisMonthRevenue,
    @JsonKey(name: 'upcoming_bookings') required int upcomingBookings,
    @JsonKey(name: 'avg_booking_value') double? avgBookingValue,
    @JsonKey(name: 'total_customers') required int totalCustomers,
    @JsonKey(name: 'total_theaters') required int totalTheaters,
    @JsonKey(name: 'last_updated') DateTime? lastUpdated,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);
} 