// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardStatsImpl _$$DashboardStatsImplFromJson(Map<String, dynamic> json) =>
    _$DashboardStatsImpl(
      vendorId: json['vendor_id'] as String,
      totalBookings: (json['total_bookings'] as num).toInt(),
      confirmedBookings: (json['confirmed_bookings'] as num).toInt(),
      cancelledBookings: (json['cancelled_bookings'] as num).toInt(),
      completedBookings: (json['completed_bookings'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      pendingRevenue: (json['pending_revenue'] as num).toDouble(),
      grossSales: (json['gross_sales'] as num).toDouble(),
      paidBookings: (json['paid_bookings'] as num).toInt(),
      pendingPayments: (json['pending_payments'] as num).toInt(),
      failedPayments: (json['failed_payments'] as num).toInt(),
      todayBookings: (json['today_bookings'] as num).toInt(),
      thisMonthBookings: (json['this_month_bookings'] as num).toInt(),
      thisMonthRevenue: (json['this_month_revenue'] as num).toDouble(),
      upcomingBookings: (json['upcoming_bookings'] as num).toInt(),
      avgBookingValue: (json['avg_booking_value'] as num?)?.toDouble(),
      totalCustomers: (json['total_customers'] as num).toInt(),
      totalTheaters: (json['total_theaters'] as num).toInt(),
      totalScreens: (json['total_screens'] as num).toInt(),
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$$DashboardStatsImplToJson(
        _$DashboardStatsImpl instance) =>
    <String, dynamic>{
      'vendor_id': instance.vendorId,
      'total_bookings': instance.totalBookings,
      'confirmed_bookings': instance.confirmedBookings,
      'cancelled_bookings': instance.cancelledBookings,
      'completed_bookings': instance.completedBookings,
      'total_revenue': instance.totalRevenue,
      'pending_revenue': instance.pendingRevenue,
      'gross_sales': instance.grossSales,
      'paid_bookings': instance.paidBookings,
      'pending_payments': instance.pendingPayments,
      'failed_payments': instance.failedPayments,
      'today_bookings': instance.todayBookings,
      'this_month_bookings': instance.thisMonthBookings,
      'this_month_revenue': instance.thisMonthRevenue,
      'upcoming_bookings': instance.upcomingBookings,
      'avg_booking_value': instance.avgBookingValue,
      'total_customers': instance.totalCustomers,
      'total_theaters': instance.totalTheaters,
      'total_screens': instance.totalScreens,
      'last_updated': instance.lastUpdated?.toIso8601String(),
    };
