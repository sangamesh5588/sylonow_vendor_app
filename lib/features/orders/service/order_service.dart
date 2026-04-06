import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylonow_vendor/core/config/supabase_config.dart';
import 'package:sylonow_vendor/features/orders/models/order.dart';

final orderServiceProvider = Provider((ref) => OrderService());

class OrderService {
  Future<List<Order>> getVendorOrders({
    String? status,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 OrderService: Calling get_vendor_orders_from_orders_table RPC with status: $status');
      }

      final response = await SupabaseConfig.client.rpc(
        'get_vendor_orders_from_orders_table',
        params: {
          'p_status': status,
        },
      );

      if (kDebugMode) {
        print('🟢 OrderService: RPC response received');
        print('🔵 OrderService: Response type: ${response.runtimeType}');
        print('🔵 OrderService: Response data: $response');
      }

      if (response == null) {
        if (kDebugMode) {
          print('🟡 OrderService: Empty response from RPC');
        }
        return [];
      }

      final List<Order> orders = (response as List)
          .map((data) {
            try {
              if (kDebugMode) {
                print('🔵 OrderService: Processing order data: $data');
              }
              // Extract the nested order_data
              final orderData = data['order_data'] as Map<String, dynamic>;
              if (kDebugMode) {
                print('🔵 OrderService: Extracted order data: $orderData');
                print('🔵 OrderService: Order data keys: ${orderData.keys.toList()}');
                print('🔵 OrderService: ID field: ${orderData['id']}');
                print('🔵 OrderService: Service title field: ${orderData['service_title']}');
              }

              // Validate required fields before creating Order
              if (orderData['id'] == null || orderData['id'].toString().isEmpty) {
                if (kDebugMode) {
                  print('🔴 OrderService: Missing or empty ID field');
                }
                throw Exception('Order ID is required but was null or empty');
              }

              if (orderData['service_title'] == null || orderData['service_title'].toString().isEmpty) {
                if (kDebugMode) {
                  print('🔴 OrderService: Missing or empty service_title field');
                }
                throw Exception('Service title is required but was null or empty');
              }

              if (orderData['booking_date'] == null) {
                if (kDebugMode) {
                  print('🔴 OrderService: Missing booking_date field');
                }
                throw Exception('Booking date is required but was null');
              }

              if (orderData['total_amount'] == null) {
                if (kDebugMode) {
                  print('🔴 OrderService: Missing total_amount field');
                }
                throw Exception('Total amount is required but was null');
              }

              return Order.fromJson(orderData);
            } catch (e) {
              if (kDebugMode) {
                print('🔴 OrderService: Error parsing individual order: $e');
                print('🔴 OrderService: Problematic data: $data');
              }
              rethrow;
            }
          })
          .toList();

      if (kDebugMode) {
        print('🟢 OrderService: Successfully parsed ${orders.length} orders');
      }
      return orders;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrderService: Error in getVendorOrders: $e');
        print('🔴 OrderService: Stack trace: $stackTrace');
      }

      if (e.toString().contains('not found for authenticated user')) {
        throw Exception('No vendor profile found. Please complete vendor onboarding first.');
      }
      
      throw Exception('Failed to fetch orders: ${e.toString()}');
    }
  }

  Future<int> getOrdersCount({String? status}) async {
    try {
      final orders = await getVendorOrders(status: status);
      return orders.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getOrdersStatistics() async {
    try {
      final allOrders = await getVendorOrders();
      
      return {
        'total': allOrders.length,
        'pending': allOrders.where((o) => o.status.toLowerCase() == 'pending').length,
        'confirmed': allOrders.where((o) => o.status.toLowerCase() == 'confirmed').length,
        'completed': allOrders.where((o) => o.status.toLowerCase() == 'completed').length,
        'cancelled': allOrders.where((o) => o.status.toLowerCase() == 'cancelled').length,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 OrderService: Updating order $bookingId to status: $status');
      }

      await SupabaseConfig.client.rpc(
        'update_order_status',
        params: {
          'p_order_id': bookingId,
          'p_new_status': status,
        },
      );
      
      if (kDebugMode) {
        print('🟢 OrderService: Successfully updated order status');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrderService: Error updating order status: $e');
        print('🔴 OrderService: Stack trace: $stackTrace');
      }

      // Provide more user-friendly error messages
      if (e.toString().contains('Permission denied')) {
        throw Exception('You do not have permission to update this order.');
      } else if (e.toString().contains('Invalid status')) {
        throw Exception('Invalid status transition. Please check the order status.');
      } else if (e.toString().contains('not found')) {
        throw Exception('Order not found or already updated.');
      }
      
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  Future<List<Order>> getRecentUnseenOrders({int limit = 10}) async {
    try {
      if (kDebugMode) {
        print('🔵 OrderService: Getting recent unseen orders with limit: $limit');
      }

      // Get recent pending orders from the last 24 hours
      final response = await SupabaseConfig.client.rpc(
        'get_recent_unseen_orders',
        params: {
          'p_limit': limit,
        },
      );

      if (kDebugMode) {
        print('🟢 OrderService: Recent orders RPC response received');
      }

      if (response == null) {
        if (kDebugMode) {
          print('🟡 OrderService: Empty response from recent orders RPC');
        }
        return [];
      }

      final List<Order> orders = (response as List)
          .map((data) {
            try {
              // Extract the nested order_data
              final orderData = data['order_data'] as Map<String, dynamic>;
              return Order.fromJson(orderData);
            } catch (e) {
              if (kDebugMode) {
                print('🔴 OrderService: Error parsing recent order: $e');
              }
              return null;
            }
          })
          .where((order) => order != null)
          .cast<Order>()
          .toList();

      if (kDebugMode) {
        print('🟢 OrderService: Successfully parsed ${orders.length} recent orders');
      }
      return orders;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrderService: Error in getRecentUnseenOrders: $e');
        print('🔴 OrderService: Stack trace: $stackTrace');
      }

      // If the RPC doesn't exist, fallback to regular pending orders
      if (e.toString().contains('not found') || e.toString().contains('does not exist')) {
        if (kDebugMode) {
          print('🟡 OrderService: RPC not found, falling back to pending orders');
        }
        final orders = await getVendorOrders(status: 'pending');
        return orders.take(limit).toList();
      }
      
      throw Exception('Failed to fetch recent orders: ${e.toString()}');
    }
  }

  // Simple status update method for workflow
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 OrderService: Updating order $orderId to status: $status');
      }

      await SupabaseConfig.client.rpc(
        'update_order_status',
        params: {
          'p_order_id': orderId,
          'p_new_status': status,
        },
      );
      
      if (kDebugMode) {
        print('🟢 OrderService: Successfully updated order status to $status');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrderService: Error updating order status: $e');
        print('🔴 OrderService: Stack trace: $stackTrace');
      }

      // Provide more user-friendly error messages
      if (e.toString().contains('Permission denied')) {
        throw Exception('You do not have permission to update this order.');
      } else if (e.toString().contains('Invalid status')) {
        throw Exception('Invalid status transition. Please check the order status.');
      } else if (e.toString().contains('not found')) {
        throw Exception('Order not found or already updated.');
      }

      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  // Update decoration images for an order
  Future<void> updateDecorationImage({
    required String orderId,
    required String imageType, // 'before' or 'after'
    required String imageUrl,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 OrderService: Updating $imageType decoration image for order $orderId');
      }

      final columnName = imageType == 'before' 
          ? 'before_decoration_image' 
          : 'after_decoration_image';
      
      await SupabaseConfig.client
          .from('orders')
          .update({columnName: imageUrl})
          .eq('id', orderId);

      if (kDebugMode) {
        print('🟢 OrderService: Successfully updated $imageType decoration image');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrderService: Error updating decoration image: $e');
        print('🔴 OrderService: Stack trace: $stackTrace');
      }

      if (e.toString().contains('Permission denied')) {
        throw Exception('You do not have permission to update this order.');
      } else if (e.toString().contains('not found')) {
        throw Exception('Order not found.');
      }
      
      throw Exception('Failed to update decoration image: ${e.toString()}');
    }
  }

  // Upload decoration image to storage and update order
  Future<String> uploadDecorationImage({
    required String orderId,
    required String imageType, // 'before' or 'after'
    required String imagePath,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 OrderService: Uploading $imageType decoration image for order $orderId');
      }

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final extension = imagePath.split('.').last.toLowerCase();
      final fileName = '${orderId}_${imageType}_decoration_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = '${user.id}/$fileName';
      
      // Upload to decoration-images bucket
      await SupabaseConfig.client.storage
          .from('decoration-images')
          .upload(filePath, File(imagePath));
      
      // Get public URL
      final imageUrl = SupabaseConfig.client.storage
          .from('decoration-images')
          .getPublicUrl(filePath);
      
      // Update order with image URL
      await updateDecorationImage(
        orderId: orderId,
        imageType: imageType,
        imageUrl: imageUrl,
      );
      
      if (kDebugMode) {
        print('🟢 OrderService: Successfully uploaded and updated $imageType decoration image');
      }
      return imageUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrderService: Error uploading decoration image: $e');
        print('🔴 OrderService: Stack trace: $stackTrace');
      }
      throw Exception('Failed to upload decoration image: ${e.toString()}');
    }
  }

  // Clear decoration image (set to null) so vendor can re-upload
  Future<void> clearDecorationImage({
    required String orderId,
    required String imageType, // 'before' or 'after'
  }) async {
    final columnName = imageType == 'before'
        ? 'before_decoration_image'
        : 'after_decoration_image';
    await SupabaseConfig.client
        .from('orders')
        .update({columnName: null}).eq('id', orderId);
  }
} 