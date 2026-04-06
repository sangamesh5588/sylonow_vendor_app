import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_addon.freezed.dart';

@freezed
class ServiceAddon with _$ServiceAddon {
  const factory ServiceAddon({
    required String id,
    required String vendorId,
    required String name,
    required double originalPrice,
    double? discountPrice,
    String? description,
    @Default([]) List<String> images,
    @Default('add_on') String type,
    @Default('piece') String unit,
    @Default(1.0) double quantity,
    @Default(0) int stock,
    @Default(true) bool isAvailable,
    @Default(0) int sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isCustomizable,
    String? customizationInputType,
  }) = _ServiceAddon;

  factory ServiceAddon.fromJson(Map<String, dynamic> json) {
    final imagesFromArray = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    // Backward compatibility: some rows store image as single columns
    // instead of the images[] array.
    final legacyImageCandidates = <String?>[
      json['place_image_url'] as String?,
      json['banner_image'] as String?,
      json['image'] as String?,
      json['image_url'] as String?,
    ];
    final legacyImages = legacyImageCandidates
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();

    final resolvedImages =
        imagesFromArray.isNotEmpty ? imagesFromArray : legacyImages;

    return ServiceAddon(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      name: json['name'] as String,
      originalPrice: (json['original_price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      images: resolvedImages,
      type: json['type'] as String? ?? 'add_on',
      unit: json['unit'] as String? ?? 'piece',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      stock: json['stock'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isCustomizable: json['is_customizable'] as bool? ?? false,
      customizationInputType: (json['customization_input_type'] ??
              json['customisation_input_type']) as String?,
    );
  }

  const ServiceAddon._();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'original_price': originalPrice,
      'discount_price': discountPrice,
      'description': description,
      'images': images,
      'type': type,
      'unit': unit,
      'quantity': quantity,
      'stock': stock,
      'is_available': isAvailable,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_customizable': isCustomizable,
      'customization_input_type': customizationInputType,
    };
  }

  /// Get the effective price (discount price if available, otherwise original price)
  double get effectivePrice => discountPrice ?? originalPrice;

  /// Get the discount percentage if discount is available
  double? get discountPercentage {
    if (discountPrice == null || discountPrice! >= originalPrice) {
      return null;
    }
    return ((originalPrice - discountPrice!) / originalPrice) * 100;
  }

  /// Check if the addon has a discount
  bool get hasDiscount => discountPrice != null && discountPrice! < originalPrice;

  /// Format the effective price as currency
  String get formattedPrice => '₹${effectivePrice.toStringAsFixed(2)}';

  /// Format the original price as currency
  String get formattedOriginalPrice => '₹${originalPrice.toStringAsFixed(2)}';

  /// Check if the addon is in stock
  bool get inStock => stock > 0;

  /// Get the first image URL or null if no images
  String? get primaryImage => images.isNotEmpty ? images.first : null;
}
