// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) {
  return _DashboardStats.fromJson(json);
}

/// @nodoc
mixin _$DashboardStats {
  @JsonKey(name: 'vendor_id')
  String get vendorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_bookings')
  int get totalBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'confirmed_bookings')
  int get confirmedBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'cancelled_bookings')
  int get cancelledBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_bookings')
  int get completedBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_revenue')
  double get totalRevenue => throw _privateConstructorUsedError;
  @JsonKey(name: 'pending_revenue')
  double get pendingRevenue => throw _privateConstructorUsedError;
  @JsonKey(name: 'gross_sales')
  double get grossSales => throw _privateConstructorUsedError;
  @JsonKey(name: 'paid_bookings')
  int get paidBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'pending_payments')
  int get pendingPayments => throw _privateConstructorUsedError;
  @JsonKey(name: 'failed_payments')
  int get failedPayments => throw _privateConstructorUsedError;
  @JsonKey(name: 'today_bookings')
  int get todayBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'this_month_bookings')
  int get thisMonthBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'this_month_revenue')
  double get thisMonthRevenue => throw _privateConstructorUsedError;
  @JsonKey(name: 'upcoming_bookings')
  int get upcomingBookings => throw _privateConstructorUsedError;
  @JsonKey(name: 'avg_booking_value')
  double? get avgBookingValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_customers')
  int get totalCustomers => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_theaters')
  int get totalTheaters => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_screens')
  int get totalScreens => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated')
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DashboardStatsCopyWith<DashboardStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardStatsCopyWith<$Res> {
  factory $DashboardStatsCopyWith(
          DashboardStats value, $Res Function(DashboardStats) then) =
      _$DashboardStatsCopyWithImpl<$Res, DashboardStats>;
  @useResult
  $Res call(
      {@JsonKey(name: 'vendor_id') String vendorId,
      @JsonKey(name: 'total_bookings') int totalBookings,
      @JsonKey(name: 'confirmed_bookings') int confirmedBookings,
      @JsonKey(name: 'cancelled_bookings') int cancelledBookings,
      @JsonKey(name: 'completed_bookings') int completedBookings,
      @JsonKey(name: 'total_revenue') double totalRevenue,
      @JsonKey(name: 'pending_revenue') double pendingRevenue,
      @JsonKey(name: 'gross_sales') double grossSales,
      @JsonKey(name: 'paid_bookings') int paidBookings,
      @JsonKey(name: 'pending_payments') int pendingPayments,
      @JsonKey(name: 'failed_payments') int failedPayments,
      @JsonKey(name: 'today_bookings') int todayBookings,
      @JsonKey(name: 'this_month_bookings') int thisMonthBookings,
      @JsonKey(name: 'this_month_revenue') double thisMonthRevenue,
      @JsonKey(name: 'upcoming_bookings') int upcomingBookings,
      @JsonKey(name: 'avg_booking_value') double? avgBookingValue,
      @JsonKey(name: 'total_customers') int totalCustomers,
      @JsonKey(name: 'total_theaters') int totalTheaters,
      @JsonKey(name: 'total_screens') int totalScreens,
      @JsonKey(name: 'last_updated') DateTime? lastUpdated});
}

/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res, $Val extends DashboardStats>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vendorId = null,
    Object? totalBookings = null,
    Object? confirmedBookings = null,
    Object? cancelledBookings = null,
    Object? completedBookings = null,
    Object? totalRevenue = null,
    Object? pendingRevenue = null,
    Object? grossSales = null,
    Object? paidBookings = null,
    Object? pendingPayments = null,
    Object? failedPayments = null,
    Object? todayBookings = null,
    Object? thisMonthBookings = null,
    Object? thisMonthRevenue = null,
    Object? upcomingBookings = null,
    Object? avgBookingValue = freezed,
    Object? totalCustomers = null,
    Object? totalTheaters = null,
    Object? totalScreens = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      totalBookings: null == totalBookings
          ? _value.totalBookings
          : totalBookings // ignore: cast_nullable_to_non_nullable
              as int,
      confirmedBookings: null == confirmedBookings
          ? _value.confirmedBookings
          : confirmedBookings // ignore: cast_nullable_to_non_nullable
              as int,
      cancelledBookings: null == cancelledBookings
          ? _value.cancelledBookings
          : cancelledBookings // ignore: cast_nullable_to_non_nullable
              as int,
      completedBookings: null == completedBookings
          ? _value.completedBookings
          : completedBookings // ignore: cast_nullable_to_non_nullable
              as int,
      totalRevenue: null == totalRevenue
          ? _value.totalRevenue
          : totalRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      pendingRevenue: null == pendingRevenue
          ? _value.pendingRevenue
          : pendingRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      grossSales: null == grossSales
          ? _value.grossSales
          : grossSales // ignore: cast_nullable_to_non_nullable
              as double,
      paidBookings: null == paidBookings
          ? _value.paidBookings
          : paidBookings // ignore: cast_nullable_to_non_nullable
              as int,
      pendingPayments: null == pendingPayments
          ? _value.pendingPayments
          : pendingPayments // ignore: cast_nullable_to_non_nullable
              as int,
      failedPayments: null == failedPayments
          ? _value.failedPayments
          : failedPayments // ignore: cast_nullable_to_non_nullable
              as int,
      todayBookings: null == todayBookings
          ? _value.todayBookings
          : todayBookings // ignore: cast_nullable_to_non_nullable
              as int,
      thisMonthBookings: null == thisMonthBookings
          ? _value.thisMonthBookings
          : thisMonthBookings // ignore: cast_nullable_to_non_nullable
              as int,
      thisMonthRevenue: null == thisMonthRevenue
          ? _value.thisMonthRevenue
          : thisMonthRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      upcomingBookings: null == upcomingBookings
          ? _value.upcomingBookings
          : upcomingBookings // ignore: cast_nullable_to_non_nullable
              as int,
      avgBookingValue: freezed == avgBookingValue
          ? _value.avgBookingValue
          : avgBookingValue // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCustomers: null == totalCustomers
          ? _value.totalCustomers
          : totalCustomers // ignore: cast_nullable_to_non_nullable
              as int,
      totalTheaters: null == totalTheaters
          ? _value.totalTheaters
          : totalTheaters // ignore: cast_nullable_to_non_nullable
              as int,
      totalScreens: null == totalScreens
          ? _value.totalScreens
          : totalScreens // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DashboardStatsImplCopyWith<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  factory _$$DashboardStatsImplCopyWith(_$DashboardStatsImpl value,
          $Res Function(_$DashboardStatsImpl) then) =
      __$$DashboardStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'vendor_id') String vendorId,
      @JsonKey(name: 'total_bookings') int totalBookings,
      @JsonKey(name: 'confirmed_bookings') int confirmedBookings,
      @JsonKey(name: 'cancelled_bookings') int cancelledBookings,
      @JsonKey(name: 'completed_bookings') int completedBookings,
      @JsonKey(name: 'total_revenue') double totalRevenue,
      @JsonKey(name: 'pending_revenue') double pendingRevenue,
      @JsonKey(name: 'gross_sales') double grossSales,
      @JsonKey(name: 'paid_bookings') int paidBookings,
      @JsonKey(name: 'pending_payments') int pendingPayments,
      @JsonKey(name: 'failed_payments') int failedPayments,
      @JsonKey(name: 'today_bookings') int todayBookings,
      @JsonKey(name: 'this_month_bookings') int thisMonthBookings,
      @JsonKey(name: 'this_month_revenue') double thisMonthRevenue,
      @JsonKey(name: 'upcoming_bookings') int upcomingBookings,
      @JsonKey(name: 'avg_booking_value') double? avgBookingValue,
      @JsonKey(name: 'total_customers') int totalCustomers,
      @JsonKey(name: 'total_theaters') int totalTheaters,
      @JsonKey(name: 'total_screens') int totalScreens,
      @JsonKey(name: 'last_updated') DateTime? lastUpdated});
}

/// @nodoc
class __$$DashboardStatsImplCopyWithImpl<$Res>
    extends _$DashboardStatsCopyWithImpl<$Res, _$DashboardStatsImpl>
    implements _$$DashboardStatsImplCopyWith<$Res> {
  __$$DashboardStatsImplCopyWithImpl(
      _$DashboardStatsImpl _value, $Res Function(_$DashboardStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vendorId = null,
    Object? totalBookings = null,
    Object? confirmedBookings = null,
    Object? cancelledBookings = null,
    Object? completedBookings = null,
    Object? totalRevenue = null,
    Object? pendingRevenue = null,
    Object? grossSales = null,
    Object? paidBookings = null,
    Object? pendingPayments = null,
    Object? failedPayments = null,
    Object? todayBookings = null,
    Object? thisMonthBookings = null,
    Object? thisMonthRevenue = null,
    Object? upcomingBookings = null,
    Object? avgBookingValue = freezed,
    Object? totalCustomers = null,
    Object? totalTheaters = null,
    Object? totalScreens = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$DashboardStatsImpl(
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      totalBookings: null == totalBookings
          ? _value.totalBookings
          : totalBookings // ignore: cast_nullable_to_non_nullable
              as int,
      confirmedBookings: null == confirmedBookings
          ? _value.confirmedBookings
          : confirmedBookings // ignore: cast_nullable_to_non_nullable
              as int,
      cancelledBookings: null == cancelledBookings
          ? _value.cancelledBookings
          : cancelledBookings // ignore: cast_nullable_to_non_nullable
              as int,
      completedBookings: null == completedBookings
          ? _value.completedBookings
          : completedBookings // ignore: cast_nullable_to_non_nullable
              as int,
      totalRevenue: null == totalRevenue
          ? _value.totalRevenue
          : totalRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      pendingRevenue: null == pendingRevenue
          ? _value.pendingRevenue
          : pendingRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      grossSales: null == grossSales
          ? _value.grossSales
          : grossSales // ignore: cast_nullable_to_non_nullable
              as double,
      paidBookings: null == paidBookings
          ? _value.paidBookings
          : paidBookings // ignore: cast_nullable_to_non_nullable
              as int,
      pendingPayments: null == pendingPayments
          ? _value.pendingPayments
          : pendingPayments // ignore: cast_nullable_to_non_nullable
              as int,
      failedPayments: null == failedPayments
          ? _value.failedPayments
          : failedPayments // ignore: cast_nullable_to_non_nullable
              as int,
      todayBookings: null == todayBookings
          ? _value.todayBookings
          : todayBookings // ignore: cast_nullable_to_non_nullable
              as int,
      thisMonthBookings: null == thisMonthBookings
          ? _value.thisMonthBookings
          : thisMonthBookings // ignore: cast_nullable_to_non_nullable
              as int,
      thisMonthRevenue: null == thisMonthRevenue
          ? _value.thisMonthRevenue
          : thisMonthRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      upcomingBookings: null == upcomingBookings
          ? _value.upcomingBookings
          : upcomingBookings // ignore: cast_nullable_to_non_nullable
              as int,
      avgBookingValue: freezed == avgBookingValue
          ? _value.avgBookingValue
          : avgBookingValue // ignore: cast_nullable_to_non_nullable
              as double?,
      totalCustomers: null == totalCustomers
          ? _value.totalCustomers
          : totalCustomers // ignore: cast_nullable_to_non_nullable
              as int,
      totalTheaters: null == totalTheaters
          ? _value.totalTheaters
          : totalTheaters // ignore: cast_nullable_to_non_nullable
              as int,
      totalScreens: null == totalScreens
          ? _value.totalScreens
          : totalScreens // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardStatsImpl implements _DashboardStats {
  const _$DashboardStatsImpl(
      {@JsonKey(name: 'vendor_id') required this.vendorId,
      @JsonKey(name: 'total_bookings') required this.totalBookings,
      @JsonKey(name: 'confirmed_bookings') required this.confirmedBookings,
      @JsonKey(name: 'cancelled_bookings') required this.cancelledBookings,
      @JsonKey(name: 'completed_bookings') required this.completedBookings,
      @JsonKey(name: 'total_revenue') required this.totalRevenue,
      @JsonKey(name: 'pending_revenue') required this.pendingRevenue,
      @JsonKey(name: 'gross_sales') required this.grossSales,
      @JsonKey(name: 'paid_bookings') required this.paidBookings,
      @JsonKey(name: 'pending_payments') required this.pendingPayments,
      @JsonKey(name: 'failed_payments') required this.failedPayments,
      @JsonKey(name: 'today_bookings') required this.todayBookings,
      @JsonKey(name: 'this_month_bookings') required this.thisMonthBookings,
      @JsonKey(name: 'this_month_revenue') required this.thisMonthRevenue,
      @JsonKey(name: 'upcoming_bookings') required this.upcomingBookings,
      @JsonKey(name: 'avg_booking_value') this.avgBookingValue,
      @JsonKey(name: 'total_customers') required this.totalCustomers,
      @JsonKey(name: 'total_theaters') required this.totalTheaters,
      @JsonKey(name: 'total_screens') required this.totalScreens,
      @JsonKey(name: 'last_updated') this.lastUpdated});

  factory _$DashboardStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardStatsImplFromJson(json);

  @override
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  @override
  @JsonKey(name: 'total_bookings')
  final int totalBookings;
  @override
  @JsonKey(name: 'confirmed_bookings')
  final int confirmedBookings;
  @override
  @JsonKey(name: 'cancelled_bookings')
  final int cancelledBookings;
  @override
  @JsonKey(name: 'completed_bookings')
  final int completedBookings;
  @override
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @override
  @JsonKey(name: 'pending_revenue')
  final double pendingRevenue;
  @override
  @JsonKey(name: 'gross_sales')
  final double grossSales;
  @override
  @JsonKey(name: 'paid_bookings')
  final int paidBookings;
  @override
  @JsonKey(name: 'pending_payments')
  final int pendingPayments;
  @override
  @JsonKey(name: 'failed_payments')
  final int failedPayments;
  @override
  @JsonKey(name: 'today_bookings')
  final int todayBookings;
  @override
  @JsonKey(name: 'this_month_bookings')
  final int thisMonthBookings;
  @override
  @JsonKey(name: 'this_month_revenue')
  final double thisMonthRevenue;
  @override
  @JsonKey(name: 'upcoming_bookings')
  final int upcomingBookings;
  @override
  @JsonKey(name: 'avg_booking_value')
  final double? avgBookingValue;
  @override
  @JsonKey(name: 'total_customers')
  final int totalCustomers;
  @override
  @JsonKey(name: 'total_theaters')
  final int totalTheaters;
  @override
  @JsonKey(name: 'total_screens')
  final int totalScreens;
  @override
  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'DashboardStats(vendorId: $vendorId, totalBookings: $totalBookings, confirmedBookings: $confirmedBookings, cancelledBookings: $cancelledBookings, completedBookings: $completedBookings, totalRevenue: $totalRevenue, pendingRevenue: $pendingRevenue, grossSales: $grossSales, paidBookings: $paidBookings, pendingPayments: $pendingPayments, failedPayments: $failedPayments, todayBookings: $todayBookings, thisMonthBookings: $thisMonthBookings, thisMonthRevenue: $thisMonthRevenue, upcomingBookings: $upcomingBookings, avgBookingValue: $avgBookingValue, totalCustomers: $totalCustomers, totalTheaters: $totalTheaters, totalScreens: $totalScreens, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardStatsImpl &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.totalBookings, totalBookings) ||
                other.totalBookings == totalBookings) &&
            (identical(other.confirmedBookings, confirmedBookings) ||
                other.confirmedBookings == confirmedBookings) &&
            (identical(other.cancelledBookings, cancelledBookings) ||
                other.cancelledBookings == cancelledBookings) &&
            (identical(other.completedBookings, completedBookings) ||
                other.completedBookings == completedBookings) &&
            (identical(other.totalRevenue, totalRevenue) ||
                other.totalRevenue == totalRevenue) &&
            (identical(other.pendingRevenue, pendingRevenue) ||
                other.pendingRevenue == pendingRevenue) &&
            (identical(other.grossSales, grossSales) ||
                other.grossSales == grossSales) &&
            (identical(other.paidBookings, paidBookings) ||
                other.paidBookings == paidBookings) &&
            (identical(other.pendingPayments, pendingPayments) ||
                other.pendingPayments == pendingPayments) &&
            (identical(other.failedPayments, failedPayments) ||
                other.failedPayments == failedPayments) &&
            (identical(other.todayBookings, todayBookings) ||
                other.todayBookings == todayBookings) &&
            (identical(other.thisMonthBookings, thisMonthBookings) ||
                other.thisMonthBookings == thisMonthBookings) &&
            (identical(other.thisMonthRevenue, thisMonthRevenue) ||
                other.thisMonthRevenue == thisMonthRevenue) &&
            (identical(other.upcomingBookings, upcomingBookings) ||
                other.upcomingBookings == upcomingBookings) &&
            (identical(other.avgBookingValue, avgBookingValue) ||
                other.avgBookingValue == avgBookingValue) &&
            (identical(other.totalCustomers, totalCustomers) ||
                other.totalCustomers == totalCustomers) &&
            (identical(other.totalTheaters, totalTheaters) ||
                other.totalTheaters == totalTheaters) &&
            (identical(other.totalScreens, totalScreens) ||
                other.totalScreens == totalScreens) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        vendorId,
        totalBookings,
        confirmedBookings,
        cancelledBookings,
        completedBookings,
        totalRevenue,
        pendingRevenue,
        grossSales,
        paidBookings,
        pendingPayments,
        failedPayments,
        todayBookings,
        thisMonthBookings,
        thisMonthRevenue,
        upcomingBookings,
        avgBookingValue,
        totalCustomers,
        totalTheaters,
        totalScreens,
        lastUpdated
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardStatsImplCopyWith<_$DashboardStatsImpl> get copyWith =>
      __$$DashboardStatsImplCopyWithImpl<_$DashboardStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardStatsImplToJson(
      this,
    );
  }
}

abstract class _DashboardStats implements DashboardStats {
  const factory _DashboardStats(
      {@JsonKey(name: 'vendor_id') required final String vendorId,
      @JsonKey(name: 'total_bookings') required final int totalBookings,
      @JsonKey(name: 'confirmed_bookings') required final int confirmedBookings,
      @JsonKey(name: 'cancelled_bookings') required final int cancelledBookings,
      @JsonKey(name: 'completed_bookings') required final int completedBookings,
      @JsonKey(name: 'total_revenue') required final double totalRevenue,
      @JsonKey(name: 'pending_revenue') required final double pendingRevenue,
      @JsonKey(name: 'gross_sales') required final double grossSales,
      @JsonKey(name: 'paid_bookings') required final int paidBookings,
      @JsonKey(name: 'pending_payments') required final int pendingPayments,
      @JsonKey(name: 'failed_payments') required final int failedPayments,
      @JsonKey(name: 'today_bookings') required final int todayBookings,
      @JsonKey(name: 'this_month_bookings')
      required final int thisMonthBookings,
      @JsonKey(name: 'this_month_revenue')
      required final double thisMonthRevenue,
      @JsonKey(name: 'upcoming_bookings') required final int upcomingBookings,
      @JsonKey(name: 'avg_booking_value') final double? avgBookingValue,
      @JsonKey(name: 'total_customers') required final int totalCustomers,
      @JsonKey(name: 'total_theaters') required final int totalTheaters,
      @JsonKey(name: 'total_screens') required final int totalScreens,
      @JsonKey(name: 'last_updated')
      final DateTime? lastUpdated}) = _$DashboardStatsImpl;

  factory _DashboardStats.fromJson(Map<String, dynamic> json) =
      _$DashboardStatsImpl.fromJson;

  @override
  @JsonKey(name: 'vendor_id')
  String get vendorId;
  @override
  @JsonKey(name: 'total_bookings')
  int get totalBookings;
  @override
  @JsonKey(name: 'confirmed_bookings')
  int get confirmedBookings;
  @override
  @JsonKey(name: 'cancelled_bookings')
  int get cancelledBookings;
  @override
  @JsonKey(name: 'completed_bookings')
  int get completedBookings;
  @override
  @JsonKey(name: 'total_revenue')
  double get totalRevenue;
  @override
  @JsonKey(name: 'pending_revenue')
  double get pendingRevenue;
  @override
  @JsonKey(name: 'gross_sales')
  double get grossSales;
  @override
  @JsonKey(name: 'paid_bookings')
  int get paidBookings;
  @override
  @JsonKey(name: 'pending_payments')
  int get pendingPayments;
  @override
  @JsonKey(name: 'failed_payments')
  int get failedPayments;
  @override
  @JsonKey(name: 'today_bookings')
  int get todayBookings;
  @override
  @JsonKey(name: 'this_month_bookings')
  int get thisMonthBookings;
  @override
  @JsonKey(name: 'this_month_revenue')
  double get thisMonthRevenue;
  @override
  @JsonKey(name: 'upcoming_bookings')
  int get upcomingBookings;
  @override
  @JsonKey(name: 'avg_booking_value')
  double? get avgBookingValue;
  @override
  @JsonKey(name: 'total_customers')
  int get totalCustomers;
  @override
  @JsonKey(name: 'total_theaters')
  int get totalTheaters;
  @override
  @JsonKey(name: 'total_screens')
  int get totalScreens;
  @override
  @JsonKey(name: 'last_updated')
  DateTime? get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$DashboardStatsImplCopyWith<_$DashboardStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
