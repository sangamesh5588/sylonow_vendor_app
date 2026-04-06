import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:sylonow_vendor/features/orders/models/order.dart';
import 'package:sylonow_vendor/features/orders/providers/order_provider.dart';
import 'package:sylonow_vendor/features/orders/service/order_service.dart';

import '../../../core/theme/app_theme.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    // Add debug print
    if (kDebugMode) {
      print('🎯 OrdersScreen: Initialized');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🎯 OrdersScreen: Building UI');
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const HeroIcon(
            HeroIcons.arrowLeft,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const HeroIcon(
              HeroIcons.arrowPath,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              if (kDebugMode) {
                print('🎯 OrdersScreen: Refreshing orders');
              }
              ref.invalidate(ordersProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _statusFilters.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statusFilters.map((status) {
          final filterStatus = status == 'All' ? null : status.toLowerCase();
          return _buildOrdersList(filterStatus, status);
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList(String? status, String statusLabel) {
    if (kDebugMode) {
      print('🎯 OrdersScreen: Building orders list for status: $status');
    }

    return Consumer(
      builder: (context, ref, child) {
        final ordersAsync = ref.watch(ordersProvider(status ?? 'All'));

        return ordersAsync.when(
          data: (orders) {
            if (kDebugMode) {
              print('🎯 OrdersScreen: Received ${orders.length ?? 0} orders for $statusLabel');
            }

            if (orders.isEmpty) {
              return _buildEmptyState(statusLabel);
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (kDebugMode) {
                  print('🎯 OrdersScreen: Pull to refresh triggered');
                }
                ref.invalidate(ordersProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length ?? 0,
                itemBuilder: (context, index) {
                  try {
                    final order = orders[index];
                    if (kDebugMode) {
                      print('🎯 OrdersScreen: Building card for order ${order.id ?? 'null'}');
                      print('🎯 OrdersScreen: Order status: ${order.status ?? 'null'}');
                      print('🎯 OrdersScreen: Service title: ${order.serviceTitle ?? 'null'}');
                      print('🎯 OrdersScreen: Total amount: ${order.totalAmount ?? 'null'}');
                      print('🎯 OrdersScreen: Customer name: ${order.customerName ?? 'null'}');
                      print('🎯 OrdersScreen: Customer phone: ${order.customerPhone ?? 'null'}');
                      print('🎯 OrdersScreen: Booking time: ${order.bookingTime ?? 'null'}');
                      print('🎯 OrdersScreen: Created at: ${order.createdAt ?? 'null'}');
                    }
                    return _buildOrderCard(order);
                  } catch (e, stackTrace) {
                    if (kDebugMode) {
                      print('🔴 OrdersScreen: Error building order card at index $index: $e');
                      print('🔴 OrdersScreen: Stack trace: $stackTrace');
                      if (index < (orders.length ?? 0)) {
                        print('🔴 OrdersScreen: Order data: ${orders[index]}');
                      }
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading order #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.toString(),
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            );
          },
          loading: () {
            if (kDebugMode) {
              print('🎯 OrdersScreen: Loading state for $statusLabel');
            }
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          },
          error: (err, stack) {
            if (kDebugMode) {
              print('🔴 OrdersScreen: Error loading orders for $statusLabel: $err');
              print('🔴 OrdersScreen: Stack trace: $stack');
            }
            return _buildErrorState(err.toString());
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    try {
      final statusColor = _getStatusColor(order.status ?? 'pending');
      final statusIcon = _getStatusIcon(order.status ?? 'pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header with status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: HeroIcon(
                    statusIcon,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${(order.id ?? 'N/A').length >= 8 ? (order.id ?? 'N/A').substring(0, 8) : (order.id ?? 'N/A')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (order.createdAt != null)
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(order.createdAt ?? DateTime.now()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatStatus(order.status ?? 'pending'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.serviceTitle ?? 'Unknown Service',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const HeroIcon(
                                HeroIcons.calendar,
                                size: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('E, MMM d')
                                    .format(order.bookingDate ?? DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              if (order.bookingTime != null && (order.bookingTime ?? '').isNotEmpty) ...[
                                const Text(' • ',
                                    style: TextStyle(
                                        color: AppTheme.textSecondaryColor)),
                                Text(
                                  order.bookingTime ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${(order.totalAmount ?? 0.0).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        if ((order.advanceAmount ?? 0.0) > 0)
                          Text(
                            'Advance: ₹${(order.advanceAmount ?? 0.0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer info
                if (order.customerName != null &&
                    (order.customerName ?? '').isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const HeroIcon(
                          HeroIcons.user,
                          color: AppTheme.accentBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                              if (order.customerPhone != null && (order.customerPhone ?? '').isNotEmpty)
                                Text(
                                  order.customerPhone ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.accentBlue,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (order.customerPhone != null && (order.customerPhone ?? '').isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement phone call
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const HeroIcon(
                                HeroIcons.phone,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Add-ons section
                if ((order.addOnsIds ?? []).isNotEmpty) ...[
                  _buildAddOnsSection(order.addOnsIds ?? []),
                  const SizedBox(height: 16),
                ],

                // View Details button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => context.push('/order-detail/${order.id ?? 'unknown'}'),
                    icon: const HeroIcon(
                      HeroIcons.eye,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                _buildActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 OrdersScreen: Error in _buildOrderCard: $e');
        print('🔴 OrdersScreen: Stack trace: $stackTrace');
      }
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red),
          ),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Error loading order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons(Order order) {
    switch ((order.status ?? 'pending').toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showOrderActionDialog(order, 'Accept', 'confirmed'),
                icon: const HeroIcon(
                  HeroIcons.checkCircle,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showOrderActionDialog(order, 'Reject', 'cancelled'),
                icon: const HeroIcon(
                  HeroIcons.xCircle,
                  size: 16,
                  color: AppTheme.errorColor,
                ),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'confirmed':
        return ElevatedButton.icon(
          onPressed: () =>
              _showOrderActionDialog(order, 'Mark Complete', 'completed'),
          icon: const HeroIcon(
            HeroIcons.checkBadge,
            size: 16,
            color: Colors.white,
          ),
          label: const Text('Mark Complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      case 'completed':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                HeroIcons.checkCircle,
                size: 16,
                color: AppTheme.successColor,
              ),
              SizedBox(width: 6),
              Text(
                'Order Completed',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case 'cancelled':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                HeroIcons.xCircle,
                size: 16,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: 6),
              Text(
                'Order Cancelled',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildEmptyState(String statusLabel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            statusLabel == 'All' ? 'No orders yet' : 'No $statusLabel orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel == 'All'
                ? 'Orders from customers will appear here'
                : 'No orders with $statusLabel status found',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (kDebugMode) {
                print('🎯 OrdersScreen: Retry button pressed');
              }
              ref.invalidate(ordersProvider);
            },
            icon: const HeroIcon(
              HeroIcons.arrowPath,
              size: 18,
              color: Colors.white,
            ),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsSection(List<String> addOnsIds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          //image of addon
          // CachedNetworkImage(
          //   imageUrl: addOnsIds.first,
          //   height: 50,
          //   width: 50,
          //   fit: BoxFit.cover,
          // ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  const Text(
                    'Add-ons',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${addOnsIds.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Add-on IDs: ${addOnsIds.join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderActionDialog(Order order, String action, String newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(newStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HeroIcon(
                  _getStatusIcon(newStatus),
                  color: _getStatusColor(newStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$action Order',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to $action this order?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${(order.id ?? 'N/A').length >= 8 ? (order.id ?? 'N/A').substring(0, 8) : (order.id ?? 'N/A')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.serviceTitle ?? 'Unknown Service',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(order.totalAmount ?? 0.0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateOrderStatus(order.id ?? 'unknown', newStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(newStatus),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(action),
            ),
          ],
        );
      },
    );
  }

  void _updateOrderStatus(String orderId, String status) async {
    try {
      if (kDebugMode) {
        print('🎯 OrdersScreen: Updating order $orderId to status $status');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                  'Updating order to ${_formatStatus(status).toLowerCase()}...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await ref.read(orderServiceProvider).updateBookingStatus(
            bookingId: orderId,
            status: status,
          );

      ref.invalidate(ordersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const HeroIcon(
                  HeroIcons.checkCircle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                    'Order ${_formatStatus(status).toLowerCase()} successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 OrdersScreen: Error updating order status: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const HeroIcon(
                  HeroIcons.exclamationTriangle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to update order: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateOrderStatus(orderId, status),
            ),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return AppTheme.accentBlue;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  HeroIcons _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return HeroIcons.clock;
      case 'confirmed':
        return HeroIcons.checkBadge;
      case 'completed':
        return HeroIcons.checkCircle;
      case 'cancelled':
        return HeroIcons.xCircle;
      default:
        return HeroIcons.listBullet;
    }
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }
}
