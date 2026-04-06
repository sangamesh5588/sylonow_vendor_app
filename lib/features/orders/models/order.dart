import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'service_listing_id') String? serviceListingId,
    @JsonKey(name: 'service_title') required String serviceTitle,
    @JsonKey(name: 'booking_date') required DateTime bookingDate,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @Default('pending') String status,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'booking_time') String? bookingTime,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    @JsonKey(name: 'special_requirements') String? specialRequirements,
    @JsonKey(name: 'address') String? venueAddress,
    @JsonKey(name: 'duration_hours') int? durationHours,
    @JsonKey(name: 'advance_amount') @Default(0.0) double advanceAmount,
    @JsonKey(name: 'remaining_amount') @Default(0.0) double remainingAmount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'confirmed_at') DateTime? confirmedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'add_ons_ids') @Default([]) List<String> addOnsIds,
    @JsonKey(name: 'customisation_input') String? customisationInput,
    @JsonKey(name: 'banner_image') String? bannerImage,
    // Decoration images
    @JsonKey(name: 'before_decoration_image') String? beforeDecorationImage,
    @JsonKey(name: 'after_decoration_image') String? afterDecorationImage,
    // Address coordinates
    @JsonKey(name: 'address_latitude') double? addressLatitude,
    @JsonKey(name: 'address_longitude') double? addressLongitude,
    // Setup time from service listing (e.g., "2 hrs", "3 hours")
    @JsonKey(name: 'setup_time') String? setupTime,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
