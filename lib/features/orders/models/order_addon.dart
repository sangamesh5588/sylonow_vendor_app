import 'package:sylonow_vendor/features/service_addon/models/service_addon.dart';

/// Represents a booked addon — combines order_add_ons (booking data)
/// with service_add_ons (catalog data) in one model.
class OrderAddon {
  final String orderAddonId;       // order_add_ons.id
  final String orderId;            // order_add_ons.order_id
  final int bookedQuantity;        // order_add_ons.quantity
  final double priceAtBooking;     // order_add_ons.price_at_booking
  final String? customisationInput; // order_add_ons.customisation_input (per-addon)
  final ServiceAddon addon;        // full service_add_ons record

  const OrderAddon({
    required this.orderAddonId,
    required this.orderId,
    required this.bookedQuantity,
    required this.priceAtBooking,
    required this.addon,
    this.customisationInput,
  });

  factory OrderAddon.fromJson(Map<String, dynamic> json) {
    final addonJson = json['service_add_ons'] as Map<String, dynamic>;
    return OrderAddon(
      orderAddonId: json['id'] as String,
      orderId: json['order_id'] as String,
      bookedQuantity: (json['quantity'] as num?)?.toInt() ?? 1,
      priceAtBooking: (json['price_at_booking'] as num).toDouble(),
      customisationInput: json['customisation_input'] as String?,
      addon: ServiceAddon.fromJson(addonJson),
    );
  }

  /// Total cost for this line item
  double get lineTotal => priceAtBooking * bookedQuantity;
}
