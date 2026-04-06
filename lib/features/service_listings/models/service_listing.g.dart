// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_listing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceListingImpl _$$ServiceListingImplFromJson(Map<String, dynamic> json) =>
    _$ServiceListingImpl(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      vendorId: json['vendor_id'] as String,
      title: json['title'] as String?,
      category: json['category'] as String?,
      themeTags: (json['theme_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      serviceEnvironment: (json['service_environment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      coverPhoto: json['cover_photo'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      videoUrl: json['video_url'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      offerPrice: (json['offer_price'] as num).toDouble(),
      promotionalTag: json['promotional_tag'] as String?,
      description: json['description'] as String?,
      inclusions: (json['inclusions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      exclusions: (json['exclusions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customAmenities: (json['custom_amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      providesBanner: json['provides_banner'] as bool? ?? false,
      customizationAvailable: json['customization_available'] as bool? ?? false,
      customizationNote: json['customization_note'] as String?,
      setupTime: json['setup_time'] as String,
      bookingNotice: json['booking_notice'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      pincodes: (json['pincodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      venueTypes: (json['venue_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      serviceAllOverBangalore:
          json['service_all_over_bangalore'] as bool? ?? false,
      freeServiceKm: (json['free_service_km'] as num?)?.toDouble(),
      extraChargesPerKm: (json['extra_charges_per_km'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      activationRequested: json['activation_requested'] as bool? ?? false,
      activationRequestedAt: json['activation_requested_at'] == null
          ? null
          : DateTime.parse(json['activation_requested_at'] as String),
      deactivationRequested: json['deactivation_requested'] as bool? ?? false,
      deactivationRequestedAt: json['deactivation_requested_at'] == null
          ? null
          : DateTime.parse(json['deactivation_requested_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ServiceListingImplToJson(
        _$ServiceListingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listing_id': instance.listingId,
      'vendor_id': instance.vendorId,
      'title': instance.title,
      'category': instance.category,
      'theme_tags': instance.themeTags,
      'service_environment': instance.serviceEnvironment,
      'cover_photo': instance.coverPhoto,
      'photos': instance.photos,
      'video_url': instance.videoUrl,
      'original_price': instance.originalPrice,
      'offer_price': instance.offerPrice,
      'promotional_tag': instance.promotionalTag,
      'description': instance.description,
      'inclusions': instance.inclusions,
      'exclusions': instance.exclusions,
      'custom_amenities': instance.customAmenities,
      'provides_banner': instance.providesBanner,
      'customization_available': instance.customizationAvailable,
      'customization_note': instance.customizationNote,
      'setup_time': instance.setupTime,
      'booking_notice': instance.bookingNotice,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'pincodes': instance.pincodes,
      'venue_types': instance.venueTypes,
      'service_all_over_bangalore': instance.serviceAllOverBangalore,
      'free_service_km': instance.freeServiceKm,
      'extra_charges_per_km': instance.extraChargesPerKm,
      'is_active': instance.isActive,
      'is_featured': instance.isFeatured,
      'activation_requested': instance.activationRequested,
      'activation_requested_at':
          instance.activationRequestedAt?.toIso8601String(),
      'deactivation_requested': instance.deactivationRequested,
      'deactivation_requested_at':
          instance.deactivationRequestedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
