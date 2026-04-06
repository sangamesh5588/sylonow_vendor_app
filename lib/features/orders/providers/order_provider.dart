import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylonow_vendor/core/providers/auth_provider.dart';
import 'package:sylonow_vendor/features/orders/models/order.dart';
import 'package:sylonow_vendor/features/orders/models/order_addon.dart';
import 'package:sylonow_vendor/features/orders/service/order_service.dart';
import 'package:sylonow_vendor/features/service_listings/service/service_listing_service.dart';
import 'package:sylonow_vendor/features/service_addon/services/service_addon_service.dart';

final ordersProvider = FutureProvider.family<List<Order>, String>((ref, status) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  try {
    final orderService = ref.watch(orderServiceProvider);
    final filterStatus = status == 'All' ? null : status.toLowerCase();
    final orders = await orderService.getVendorOrders(status: filterStatus);
    return orders;
  } catch (e) {
    rethrow;
  }
});

// Provider for recent unseen orders (for home screen)
final recentUnseenOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  try {
    final orderService = ref.watch(orderServiceProvider);
    final orders = await orderService.getRecentUnseenOrders(limit: 10);
    return orders;
  } catch (e) {
    rethrow;
  }
});

// Fetches booked add-ons for a specific order (JOIN: order_add_ons + service_add_ons)
final orderAddOnsProvider =
    FutureProvider.family<List<OrderAddon>, String>((ref, orderId) async {
  final serviceAddonService = ServiceAddonService();
  return serviceAddonService.getAddonsByOrderId(orderId);
});

// Order Values Calculation Provider
final orderValuesProvider =
    FutureProvider.family<Map<String, double>, Order>((ref, order) async {
  final serviceListingService = ref.read(serviceListingServiceProvider);
  final serviceAddonService = ServiceAddonService();

  try {
    // Get service discounted price from service_listings table using offer_price
    double serviceDiscountedPrice = 0.0;

    if (order.serviceListingId != null && order.serviceListingId!.isNotEmpty) {
      final serviceListing = await serviceListingService
          .getServiceListingById(order.serviceListingId!);
      serviceDiscountedPrice = serviceListing?.offerPrice ?? order.totalAmount;
    } else {
      serviceDiscountedPrice = order.totalAmount;
    }

    // Get booked add-ons using price locked at booking time × booked quantity
    double addOnsDiscountedPrice = 0.0;
    final orderAddOns = await serviceAddonService.getAddonsByOrderId(order.id);

    for (final orderAddon in orderAddOns) {
      addOnsDiscountedPrice += orderAddon.lineTotal;
    }

    // Total Order Value = Service Price + AddOns Price
    double totalOrderValue = serviceDiscountedPrice + addOnsDiscountedPrice;

    // Platform fee = 5% of total + 18% GST on that 5%
    double platformFeeBase = totalOrderValue * 0.05;
    double platformFeeGST = platformFeeBase * 0.18;
    double totalPlatformFee = platformFeeBase + platformFeeGST;

    // Total Revenue = Total Order Value - Platform Fee
    // This is the total amount the vendor earns (Sylonow Payout + Amount to Collect)
    double totalRevenue = totalOrderValue - totalPlatformFee;

    // Amount to collect from customer at venue = 40% of total order value
    double amountToCollect = totalOrderValue * 0.40;

    // Sylonow Payout = Total Revenue - Amount to Collect
    double sylonowPayout = totalRevenue - amountToCollect;

    return {
      'totalOrderValue': totalOrderValue,
      'revenue': totalRevenue,
      'sylonowPayout': sylonowPayout,
      'amountToCollect': amountToCollect,
      'serviceDiscountedPrice': serviceDiscountedPrice,
      'addOnsDiscountedPrice': addOnsDiscountedPrice,
      'platformFee': totalPlatformFee,
    };
  } catch (e) {
    // Fallback calculation using order.totalAmount
    double totalOrderValue = order.totalAmount;
    double platformFeeBase = totalOrderValue * 0.05;
    double platformFeeGST = platformFeeBase * 0.18;
    double totalPlatformFee = platformFeeBase + platformFeeGST;
    double totalRevenue = totalOrderValue - totalPlatformFee;
    double amountToCollect = totalOrderValue * 0.40;
    double sylonowPayout = totalRevenue - amountToCollect;

    return {
      'totalOrderValue': totalOrderValue,
      'revenue': totalRevenue,
      'sylonowPayout': sylonowPayout,
      'amountToCollect': amountToCollect,
      'serviceDiscountedPrice': totalOrderValue,
      'addOnsDiscountedPrice': 0.0,
      'platformFee': totalPlatformFee,
    };
  }
});
