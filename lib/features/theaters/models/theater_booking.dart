import 'package:freezed_annotation/freezed_annotation.dart';

part 'theater_booking.freezed.dart';
part 'theater_booking.g.dart';

@freezed
class TheaterBooking with _$TheaterBooking {
  const factory TheaterBooking({
    required String id,
    @JsonKey(name: 'theater_id') required String theaterId,
    @JsonKey(name: 'time_slot_id') String? timeSlotId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'booking_date') required DateTime bookingDate,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    @JsonKey(name: 'payment_id') String? paymentId,
    @JsonKey(name: 'booking_status') @Default('confirmed') String bookingStatus,
    @JsonKey(name: 'guest_count') @Default(1) int guestCount,
    @JsonKey(name: 'special_requests') String? specialRequests,
    @JsonKey(name: 'contact_name') required String contactName,
    @JsonKey(name: 'contact_phone') required String contactPhone,
    @JsonKey(name: 'contact_email') String? contactEmail,
    @JsonKey(name: 'celebration_name') String? celebrationName,
    @JsonKey(name: 'number_of_people') @Default(2) int numberOfPeople,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,

    // Payment breakdown fields
    @JsonKey(name: 'user_advance_payment') @Default(0.0) double userAdvancePayment,
    @JsonKey(name: 'pending_amount') @Default(0.0) double pendingAmount,
    @JsonKey(name: 'admin_payout') @Default(0.0) double adminPayout,

    // Related data (joined from other tables)
    @JsonKey(name: 'theater_name') String? theaterName,
    @JsonKey(name: 'screen_name') String? screenName,
    @JsonKey(name: 'screen_number') int? screenNumber,

    // Add-ons selected for this booking
    @JsonKey(name: 'selected_addons') @Default([]) List<dynamic> selectedAddons,

    // Slot base price from theater_time_slots (fetched via join)
    @JsonKey(name: 'slot_base_price') @Default(0.0) double slotBasePrice,

    // Screen capacity fields from theater_screens (fetched via join)
    @JsonKey(name: 'allowed_capacity') @Default(0) int allowedCapacity,
    @JsonKey(name: 'charges_extra_per_person') @Default(0.0) double chargesExtraPerPerson,
  }) = _TheaterBooking;

  factory TheaterBooking.fromJson(Map<String, dynamic> json) => _$TheaterBookingFromJson(json);
}

enum BookingStatus {
  confirmed,
  cancelled,
  completed,
  noShow,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get value {
    switch (this) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
}