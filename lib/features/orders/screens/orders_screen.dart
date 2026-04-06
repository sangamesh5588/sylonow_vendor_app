import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:sylonow_vendor/core/theme/app_theme.dart';
import 'package:sylonow_vendor/core/utils/phone_utils.dart';
import 'package:sylonow_vendor/features/orders/models/order.dart';
import 'package:sylonow_vendor/features/orders/providers/order_provider.dart';
import 'package:sylonow_vendor/features/orders/service/order_service.dart';
import 'package:sylonow_vendor/features/service_listings/service/service_listing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/guest_auth_provider.dart';
import '../../home/service/demo_data_service.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please login to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/welcome');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    return Consumer(
      builder: (context, ref, child) {
        // Check if user is authenticated first - this takes precedence over guest status
        final currentUser = ref.watch(currentUserProvider);
        final isAuthenticated = currentUser != null;

        // Check if user is a guest (only matters if NOT authenticated)
        final isGuestAsync = ref.watch(isGuestUserProvider);
        final isGuest = !isAuthenticated && (isGuestAsync.valueOrNull ?? false);
        final guestBusinessType =
            ref.watch(guestBusinessTypeProvider).valueOrNull;

        // For guest users, show demo orders
        if (isGuest) {
          final allDemoOrders = DemoDataService.getDemoOrders(
              guestBusinessType ?? 'Private Theater');

          // Filter demo orders by status
          final filteredOrders = status == null || status == 'All'
              ? allDemoOrders
              : allDemoOrders
                  .where((order) =>
                      order.status.toLowerCase() == status.toLowerCase())
                  .toList();

          if (filteredOrders.isEmpty) {
            return _buildEmptyState(statusLabel);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // For guests, just show a message (no actual refresh)
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                try {
                  final order = filteredOrders[index];
                  return _buildOrderCard(order);
                } catch (e) {
                  return _buildErrorCard('Error loading order: $e', index);
                }
              },
            ),
          );
        }

        // For authenticated users, fetch from provider
        final ordersAsync = ref.watch(ordersProvider(status ?? 'All'));

        return ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return _buildEmptyState(statusLabel);
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ordersProvider);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  try {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  } catch (e) {
                    return _buildErrorCard('Error loading order: $e', index);
                  }
                },
              ),
            );
          },
          loading: () => _buildLoadingState(statusLabel),
          error: (err, stack) => _buildErrorState(err.toString()),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    // Safe getters with fallbacks
    final id = order.id ?? 'unknown';
    final status = order.status ?? 'pending';
    final serviceTitle = order.serviceTitle ?? 'Unknown Service';
    final totalAmount = order.totalAmount ?? 0.0;
    final customerName =
        order.customerName?.isNotEmpty == true ? order.customerName! : null;
    final customerPhone =
        order.customerPhone?.isNotEmpty == true ? order.customerPhone! : null;
    final bookingTime =
        order.bookingTime?.isNotEmpty == true ? order.bookingTime! : null;
    final bookingDate = order.bookingDate ?? DateTime.now();
    final setupTime = order.setupTime;

    // Get display phone (masked or full based on time window)
    final canShowFullContact = PhoneUtils.shouldShowFullContact(
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      setupTime: setupTime,
      orderStatus: status,
    );

    // Check if event time has passed for complete hiding
    final now = DateTime.now();
    final eventCompleted = _isEventCompleted(order, now);

    final displayPhone = customerPhone != null
        ? (canShowFullContact
            ? customerPhone
            : (eventCompleted
                ? null
                : PhoneUtils.maskPhoneNumber(customerPhone)))
        : null;
    final createdAt = order.createdAt;
    final advanceAmount = order.advanceAmount ?? 0.0;
    final addOnsIds = order.addOnsIds ?? [];

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order #${id.length >= 8 ? id.substring(0, 8) : id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
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
                    _formatStatus(status),
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

          // Service Image Section
          if (order.serviceListingId != null &&
              order.serviceListingId!.isNotEmpty)
            FutureBuilder(
              future: ref
                  .read(serviceListingServiceProvider)
                  .getServiceListingById(order.serviceListingId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 120,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final serviceListing = snapshot.data!;
                  final displayImage = serviceListing.coverPhoto ??
                      (serviceListing.photos.isNotEmpty
                          ? serviceListing.photos.first
                          : null);

                  if (displayImage != null) {
                    return Container(
                      height: 120,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: displayImage,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.backgroundColor,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.backgroundColor,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 32,
                                  color: AppTheme.textDisabledColor,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textDisabledColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }

                return const SizedBox.shrink();
              },
            )
          else
            const SizedBox.shrink(),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Service title and amount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            serviceTitle,
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
                                DateFormat('E, MMM d').format(bookingDate),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              if (bookingTime != null) ...[
                                const Text(' • ',
                                    style: TextStyle(
                                        color: AppTheme.textSecondaryColor)),
                                Text(
                                  _convertTo12HourFormat(bookingTime),
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
                    const SizedBox(width: 16),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Order Value',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Consumer(
                          builder: (context, ref, child) {
                            final orderValuesAsync =
                                ref.watch(orderValuesProvider(order));
                            return orderValuesAsync.when(
                              data: (orderValues) => Text(
                                '₹${orderValues['totalOrderValue']!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              loading: () => const SizedBox(
                                width: 60,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor),
                                ),
                              ),
                              error: (error, stack) => Text(
                                '₹${totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer info
                if (customerName != null) ...[
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                              if (displayPhone != null)
                                Text(
                                  displayPhone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.accentBlue,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (customerPhone != null && canShowFullContact)
                          GestureDetector(
                            onTap: () async {
                              final uri =
                                  Uri(scheme: 'tel', path: customerPhone);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
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
                if (addOnsIds.isNotEmpty) ...[
                  Container(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
                  ),
                  const SizedBox(height: 16),
                ],

                // View Details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final isGuest =
                          ref.read(isGuestUserProvider).valueOrNull ?? false;
                      if (isGuest) {
                        _showLoginDialog();
                      } else {
                        context.push('/order-detail/$id');
                      }
                    },
                    icon: const HeroIcon(
                      HeroIcons.eye,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
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
  }

  Widget _buildActionButtons(Order order) {
    final status = order.status ?? 'pending';
    final id = order.id ?? 'unknown';

    final isGuest = ref.read(isGuestUserProvider).valueOrNull ?? false;

    switch (status.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isGuest
                    ? () => _showLoginDialog()
                    : () =>
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
                onPressed: isGuest
                    ? () => _showLoginDialog()
                    : () =>
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

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorCard(String message, int index) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Error loading order #${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildLoadingState(String statusLabel) {
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

  void _showOrderActionDialog(Order order, String action, String newStatus) {
    final id = order.id ?? 'unknown';
    final serviceTitle = order.serviceTitle ?? 'Unknown Service';
    final totalAmount = order.totalAmount ?? 0.0;
    final customerName =
        order.customerName?.isNotEmpty == true ? order.customerName! : null;
    final bookingDate = order.bookingDate;
    final bookingTime =
        order.bookingTime?.isNotEmpty == true ? order.bookingTime! : null;
    final isAccept = newStatus == 'confirmed';
    final statusColor = _getStatusColor(newStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header with icon
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HeroIcon(
                          isAccept ? HeroIcons.checkCircle : HeroIcons.xCircle,
                          color: statusColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$action Order?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAccept
                            ? 'This order will be confirmed and the customer will be notified.'
                            : 'This order will be cancelled and the customer will be notified.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Order details card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      // Order ID
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.hashtag,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order #${id.length >= 8 ? id.substring(0, 8) : id}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Service title
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.sparkles,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              serviceTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Customer name
                      if (customerName != null) ...[
                        Row(
                          children: [
                            const HeroIcon(
                              HeroIcons.user,
                              size: 16,
                              color: AppTheme.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Booking date & time
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.calendar,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('E, MMM d, yyyy').format(bookingDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if (bookingTime != null) ...[
                            const Text(
                              '  |  ',
                              style:
                                  TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                            Text(
                              _convertTo12HourFormat(bookingTime),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const Divider(height: 20),

                      // Total amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Order Value',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final orderValuesAsync =
                                  ref.watch(orderValuesProvider(order));
                              return orderValuesAsync.when(
                                data: (orderValues) => Text(
                                  '₹${orderValues['totalOrderValue']!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                loading: () => const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryColor),
                                  ),
                                ),
                                error: (error, stack) => Text(
                                  '₹${totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondaryColor,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _updateOrderStatus(id, newStatus);
                          },
                          icon: HeroIcon(
                            isAccept
                                ? HeroIcons.checkCircle
                                : HeroIcons.xCircle,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            isAccept ? 'Accept Order' : 'Reject Order',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateOrderStatus(String orderId, String status) async {
    try {
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

  bool _isEventCompleted(Order order, DateTime now) {
    // Check if booking date and time have passed
    if (order.bookingTime != null && order.bookingTime!.isNotEmpty) {
      // Parse booking time and combine with booking date
      try {
        final timeParts = order.bookingTime!.split(':');
        if (timeParts.length >= 2) {
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);
          final eventDateTime = DateTime(
            order.bookingDate.year,
            order.bookingDate.month,
            order.bookingDate.day,
            hours,
            minutes,
          );
          return now.isAfter(eventDateTime);
        }
      } catch (e) {
        // If parsing fails, fall back to just date comparison
      }
    }

    // Fallback: just check if booking date has passed
    return now.isAfter(order.bookingDate);
  }

  String _convertTo12HourFormat(String timeString) {
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hours = int.parse(timeParts[0]);
        final minutes = int.parse(timeParts[1]);

        final period = hours >= 12 ? 'PM' : 'AM';
        final displayHours =
            hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);

        return '${displayHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // If parsing fails, return original string
    }
    return timeString;
  }
}
