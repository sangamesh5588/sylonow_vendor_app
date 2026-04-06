// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
      id: json['id'] as String,
      serviceListingId: json['service_listing_id'] as String?,
      serviceTitle: json['service_title'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      bookingTime: json['booking_time'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      specialRequirements: json['special_requirements'] as String?,
      venueAddress: json['address'] as String?,
      durationHours: (json['duration_hours'] as num?)?.toInt(),
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      addOnsIds: (json['add_ons_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customisationInput: json['customisation_input'] as String?,
      bannerImage: json['banner_image'] as String?,
      beforeDecorationImage: json['before_decoration_image'] as String?,
      afterDecorationImage: json['after_decoration_image'] as String?,
      addressLatitude: (json['address_latitude'] as num?)?.toDouble(),
      addressLongitude: (json['address_longitude'] as num?)?.toDouble(),
      setupTime: json['setup_time'] as String?,
    );

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_listing_id': instance.serviceListingId,
      'service_title': instance.serviceTitle,
      'booking_date': instance.bookingDate.toIso8601String(),
      'total_amount': instance.totalAmount,
      'status': instance.status,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'customer_email': instance.customerEmail,
      'booking_time': instance.bookingTime,
      'payment_status': instance.paymentStatus,
      'special_requirements': instance.specialRequirements,
      'address': instance.venueAddress,
      'duration_hours': instance.durationHours,
      'advance_amount': instance.advanceAmount,
      'remaining_amount': instance.remainingAmount,
      'created_at': instance.createdAt?.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'add_ons_ids': instance.addOnsIds,
      'customisation_input': instance.customisationInput,
      'banner_image': instance.bannerImage,
      'before_decoration_image': instance.beforeDecorationImage,
      'after_decoration_image': instance.afterDecorationImage,
      'address_latitude': instance.addressLatitude,
      'address_longitude': instance.addressLongitude,
      'setup_time': instance.setupTime,
    };
