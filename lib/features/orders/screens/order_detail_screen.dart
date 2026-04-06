import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/order_addon.dart';
import '../../service_listings/service/service_listing_service.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../service/order_service.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider('All'));

    return allOrders.when(
      data: (orders) {
        final order = orders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => throw Exception('Order not found'),
        );

        return _buildOrderDetailContent(context, order);
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar('Order Details'),
        body: _buildErrorState(error.toString()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.textPrimaryColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      leading: IconButton(
        icon: const HeroIcon(HeroIcons.arrowLeft,
            color: AppTheme.textPrimaryColor),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const HeroIcon(HeroIcons.arrowPath,
              color: AppTheme.textPrimaryColor),
          onPressed: () {
            ref.invalidate(ordersProvider('All'));
          },
        ),
      ],
    );
  }

  Widget _buildOrderDetailContent(BuildContext context, Order order) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar('Order Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(order),
            const SizedBox(height: 16),
            _buildBannerSection(order),
            const SizedBox(height: 16),
            _buildAddOns(order),
            const SizedBox(height: 16),
            _buildOrderInfo(order),
            const SizedBox(height: 16),
            _buildEventInfo(order),
            const SizedBox(height: 16),
            _buildServiceInfo(order),
            const SizedBox(height: 16),
            _buildLocationInfo(order),
            const SizedBox(height: 16),
            _buildContactInfo(order),
            if (order.specialRequirements != null &&
                order.specialRequirements!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSpecialNotes(order),
            ],
            const SizedBox(height: 24),
            _buildActionSection(order),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image — full-cover, no side padding
          if (order.serviceListingId != null &&
              order.serviceListingId!.isNotEmpty)
            FutureBuilder(
              future: ref
                  .read(serviceListingServiceProvider)
                  .getServiceListingById(order.serviceListingId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 180,
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
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final serviceListing = snapshot.data!;
                  final displayImage = serviceListing.coverPhoto ??
                      (serviceListing.photos.isNotEmpty
                          ? serviceListing.photos.first
                          : null);

                  if (displayImage != null) {
                    return CachedNetworkImage(
                      imageUrl: displayImage,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
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
                        height: 180,
                        color: AppTheme.backgroundColor,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 36, color: AppTheme.textDisabledColor),
                            SizedBox(height: 6),
                            Text('Image not available',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textDisabledColor)),
                          ],
                        ),
                      ),
                    );
                  }
                }

                return Container(
                  height: 180,
                  color: AppTheme.backgroundColor,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          size: 36, color: AppTheme.textDisabledColor),
                      SizedBox(height: 6),
                      Text('No image available',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDisabledColor)),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              height: 180,
              color: AppTheme.backgroundColor,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_center_outlined,
                      size: 36, color: AppTheme.textDisabledColor),
                  SizedBox(height: 6),
                  Text('Service details not available',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textDisabledColor)),
                ],
              ),
            ),

          // Order ID + status + service title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.serviceTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection(Order order) {
    final bannerText = order.customisationInput;
    final hasBannerText = bannerText != null && bannerText.trim().isNotEmpty;
    final hasBannerImage =
        order.bannerImage != null && order.bannerImage!.isNotEmpty;

    if (!hasBannerImage && !hasBannerText) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image — full-cover
          if (hasBannerImage)
            CachedNetworkImage(
              imageUrl: order.bannerImage!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: AppTheme.backgroundColor,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),

          // Banner text
          if (hasBannerText)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, hasBannerImage ? 12 : 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Banner Text',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.text_fields_rounded,
                            size: 15, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bannerText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Label at the bottom when only image (no text)
          if (hasBannerImage && !hasBannerText)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                'Banner Image',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(Order order) {
    final orderValuesAsync = ref.watch(orderValuesProvider(order));

    return orderValuesAsync.when(
      data: (orderValues) {
        final servicePrice = orderValues['serviceDiscountedPrice']!;
        final addOnsPrice = orderValues['addOnsDiscountedPrice']!;
        final totalOrderValue = orderValues['totalOrderValue']!;
        final amountToCollect = order.remainingAmount;
        final sylonowPayout = orderValues['sylonowPayout']!;
        final totalRevenue = orderValues['revenue']!;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppTheme.cardShadow],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Order Value Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Itemised price section ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Service price row
                    _buildBreakdownRow(
                      label: 'Service',
                      value: '₹${servicePrice.toStringAsFixed(0)}',
                    ),
                    // Add-ons row (only when add-ons exist)
                    if (addOnsPrice > 0) ...[
                      const SizedBox(height: 10),
                      _buildBreakdownRow(
                        label: 'Add-ons',
                        value: '+ ₹${addOnsPrice.toStringAsFixed(0)}',
                        valueColor: AppTheme.accentPink,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 12),
                    // Total order value
                    _buildBreakdownRow(
                      label: 'Total Order Value',
                      value: '₹${totalOrderValue.toStringAsFixed(0)}',
                      isBold: true,
                      valueColor: AppTheme.textPrimaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Payment split section ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Amount to collect (direct from orders.remaining_amount)
                    _buildBreakdownRow(
                      label: 'Collect at Venue',
                      value: '₹${amountToCollect.toStringAsFixed(0)}',
                      valueColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 10),
                    // Sylonow payout
                    _buildBreakdownRow(
                      label: 'Sylonow Payout',
                      value: '₹${sylonowPayout.toStringAsFixed(0)}',
                      valueColor: AppTheme.successColor,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 12),
                    // Total revenue
                    _buildBreakdownRow(
                      label: 'Total Revenue',
                      value: '₹${totalRevenue.toStringAsFixed(0)}',
                      isBold: true,
                      valueColor: AppTheme.successColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error calculating order values',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fallback: ₹${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo(Order order) {
    // Calculate setup timeline
    final setupHours = _parseSetupTime(order.setupTime ?? '1 hr');
    DateTime bookingDateTime = order.bookingDate;

    // Parse booking time if available
    if (order.bookingTime != null && order.bookingTime!.isNotEmpty) {
      try {
        final timeParts = order.bookingTime!.split(':');
        if (timeParts.length >= 2) {
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);
          bookingDateTime = DateTime(
            order.bookingDate.year,
            order.bookingDate.month,
            order.bookingDate.day,
            hours,
            minutes,
          );
        }
      } catch (e) {
        // Use date only if parsing fails
      }
    }

    // Calculate setup times
    final setupStartTime =
        bookingDateTime.subtract(Duration(hours: setupHours));
    final setupEndTime = bookingDateTime;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_outlined,
                  color: AppTheme.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Event Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFlatInfoRow(
              'Date', DateFormat('dd MMM, yyyy').format(order.bookingDate)),
          if (order.bookingTime != null) ...[
            const SizedBox(height: 12),
            _buildFlatInfoRow('Time', _formatTime12Hour(order.bookingTime!)),
          ],
          if (order.durationHours != null) ...[
            const SizedBox(height: 12),
            _buildFlatInfoRow('Duration', '${order.durationHours} hours'),
          ],
          const SizedBox(height: 16),
          // Setup Timeline Section
          if (order.serviceListingId != null &&
              order.serviceListingId!.isNotEmpty)
            FutureBuilder(
              future: ref
                  .read(serviceListingServiceProvider)
                  .getServiceListingById(order.serviceListingId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.2),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final serviceListing = snapshot.data!;
                  final setupTime = serviceListing.setupTime ?? '1 hr';
                  final setupHours = _parseSetupTime(setupTime);

                  // Calculate setup times
                  DateTime bookingDateTime = order.bookingDate;
                  if (order.bookingTime != null &&
                      order.bookingTime!.isNotEmpty) {
                    try {
                      final timeParts = order.bookingTime!.split(':');
                      if (timeParts.length >= 2) {
                        final hours = int.parse(timeParts[0]);
                        final minutes = int.parse(timeParts[1]);
                        bookingDateTime = DateTime(
                          order.bookingDate.year,
                          order.bookingDate.month,
                          order.bookingDate.day,
                          hours,
                          minutes,
                        );
                      }
                    } catch (e) {
                      // Use date only if parsing fails
                    }
                  }

                  final setupStartTime =
                      bookingDateTime.subtract(Duration(hours: setupHours));
                  final arrivalTime =
                      setupStartTime.subtract(const Duration(minutes: 30));
                  final setupEndTime = bookingDateTime;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.backgroundColor.withOpacity(0.3),
                          AppTheme.surfaceColor.withOpacity(0.5),
                          AppTheme.backgroundColor.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.dividerColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: AppTheme.backgroundColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Setup Timeline',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Vertical timeline with clear step explanations
                        Column(
                          children: [
                            _buildSetupTimelineStep(
                              stepNumber: 1,
                              color: AppTheme.primaryColor,
                              timeText: DateFormat('h:mm a').format(arrivalTime),
                              title: 'Arrive at location',
                              subtitle:
                                  'Team reaches venue and checks event requirements before setup.',
                              isLast: false,
                            ),
                            _buildSetupTimelineStep(
                              stepNumber: 2,
                              color: AppTheme.warningColor,
                              timeText:
                                  DateFormat('h:mm a').format(setupStartTime),
                              title: 'Setup starts',
                              subtitle:
                                  'Equipment arrangement and decoration starts as planned.',
                              isLast: false,
                            ),
                            _buildSetupTimelineStep(
                              stepNumber: 3,
                              color: AppTheme.successColor,
                              timeText: DateFormat('h:mm a').format(setupEndTime),
                              title: 'Setup completes',
                              subtitle:
                                  'Final checks complete and event is ready to begin.',
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.2),
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppTheme.successColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Important:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Please arrive before Step 1 time to ensure smooth setup. Order must be completed by Step 3 time.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimaryColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Fallback if service listing not found
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningColor.withOpacity(0.2),
                    ),
                  ),
                  child: const Text(
                    'Setup timeline not available',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'Setup timeline not available',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo(Order order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.room_service_outlined,
                  color: AppTheme.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            order.serviceTitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (order.serviceListingId != null &&
              order.serviceListingId!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/service-listing/${order.serviceListingId}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('View Details',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(Order order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: () => _openInGoogleMaps(order),
                  icon: const Icon(Icons.map,
                      size: 16, color: AppTheme.successColor),
                  label: const Text('Open Maps',
                      style: TextStyle(color: AppTheme.successColor)),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (order.venueAddress != null && order.venueAddress!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.venueAddress!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => context.push('/support'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.errorColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address not available. Tap to contact support team.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.errorColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Order order) {
    final shouldShowPhone = _shouldShowCustomerInfo(order);
    final hasName = order.customerName?.isNotEmpty == true;
    final hasPhone = order.customerPhone?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer name row — always visible
          if (hasName) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 16, color: AppTheme.accentBlue),
                  const SizedBox(width: 10),
                  Text(
                    order.customerName!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Phone row — shown, masked, or locked based on reveal logic
          if (hasPhone)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: shouldShowPhone
                    ? AppTheme.successColor.withOpacity(0.05)
                    : AppTheme.warningColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: shouldShowPhone
                      ? AppTheme.successColor.withOpacity(0.2)
                      : AppTheme.warningColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    shouldShowPhone
                        ? Icons.phone_outlined
                        : Icons.lock_outline,
                    color: shouldShowPhone
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: shouldShowPhone
                        ? Text(
                            order.customerPhone!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          )
                        : Text(
                            _getContactRevealMessage(order),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                  ),
                  if (shouldShowPhone)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri(
                            scheme: 'tel', path: order.customerPhone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.call_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            )
          else if (!hasName)
            // Fallback: no name, no phone
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: AppTheme.warningColor, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getContactRevealMessage(order),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialNotes(Order order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Special Requirements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              order.specialRequirements!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOns(Order order) {
    final addOnsAsync = ref.watch(orderAddOnsProvider(order.id));

    return addOnsAsync.when(
      data: (orderAddOns) {
        if (orderAddOns.isEmpty) return const SizedBox.shrink();

        final double totalAddonsPrice =
            orderAddOns.fold(0, (sum, oa) => sum + oa.lineTotal);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppTheme.cardShadow],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_outlined,
                      color: AppTheme.accentTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add-ons (${orderAddOns.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${totalAddonsPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppTheme.dividerColor),
              const SizedBox(height: 4),

              // Addon items list
              ...orderAddOns
                  .asMap()
                  .entries
                  .map((entry) => _buildFlatAddonItem(
                      entry.value, entry.key == orderAddOns.length - 1))
                  .toList(),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildFlatAddonItem(OrderAddon orderAddon, bool isLast) {
    final addon = orderAddon.addon;
    final customText = orderAddon.customisationInput;
    final inputType = addon.customizationInputType; // "text" | "number" | null

    final bool hasCustomText =
        customText != null && customText.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: addon.primaryImage != null
                          ? CachedNetworkImage(
                              imageUrl: addon.primaryImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _addonImagePlaceholder(),
                              errorWidget: (_, __, ___) =>
                                  _addonImagePlaceholder(),
                            )
                          : _addonImagePlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (orderAddon.bookedQuantity > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${orderAddon.priceAtBooking.toStringAsFixed(0)} × ${orderAddon.bookedQuantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '₹${orderAddon.lineTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Customisation bubble — shown only when per-addon input is filled
              if (hasCustomText) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        inputType == 'number'
                            ? Icons.numbers_rounded
                            : Icons.text_fields_rounded,
                        size: 15,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inputType == 'number'
                                  ? 'Customisation (number)'
                                  : 'Customisation',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (inputType != 'number')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.dividerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${customText.length} ch',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 0.5, color: AppTheme.dividerColor),
      ],
    );
  }

  Widget _addonImagePlaceholder() {
    return Container(
      color: AppTheme.backgroundColor,
      child: const Center(
        child: Icon(Icons.auto_awesome_outlined,
            size: 24, color: AppTheme.textDisabledColor),
      ),
    );
  }

  Widget _buildActionSection(Order order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: _buildActionButtons(order),
    );
  }

  Widget _buildActionButtons(Order order) {
    final status = order.status.toLowerCase();

    return Column(
      children: [
        // "On The Way" button - shown for confirmed orders
        if (status == 'confirmed') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isUpdatingStatus ? null : () => _markAsOnTheWay(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isUpdatingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Mark As On The Way',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // "Scan QR Code" button - shown for orders marked as on the way
        if (status == 'on_the_way') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _scanQRCode(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // "Start Setup" button - shown after QR verification
        if (status == 'qr_verified') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdatingStatus ? null : () => _startSetup(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isUpdatingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Start Setup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Proceed to complete - shown after setup started
        if (status == 'started') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(
                  '/order-completion/${order.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Proceed to Complete Order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ),
        ],

        // Completed state
        if (status == 'completed') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Completed Successfully',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error loading order details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  bool _shouldShowCustomerInfo(Order order) {
    final now = DateTime.now();

    // Hide customer number if order is completed or cancelled
    if (order.status.toLowerCase() == 'completed' ||
        order.status.toLowerCase() == 'cancelled') {
      return false;
    }

    // Hide customer number if event time has passed
    if (_isEventCompleted(order, now)) {
      return false;
    }

    // Hide customer number if setup time has expired (setup completed + 2 hours)
    if (_isSetupTimeExpired(order, now)) {
      return false;
    }

    // Parse setup time to get hours (e.g., "2 hrs" -> 2, "3 hours" -> 3)
    int setupHours = _parseSetupTime(order.setupTime ?? '1 hr');

    // Reveal customer number 2 hours before setup time begins
    // Reveal time = booking date - setup hours - 2 hours
    final revealTime =
        order.bookingDate.subtract(Duration(hours: setupHours + 2));

    return now.isAfter(revealTime);
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

  bool _isSetupTimeExpired(Order order, DateTime now) {
    // Check if setup time has completed and 2 hours have passed
    final setupHours = _parseSetupTime(order.setupTime ?? '1 hr');
    final setupEndTime = order.bookingDate.add(Duration(hours: setupHours));
    final hideTime = setupEndTime.add(const Duration(hours: 2));

    return now.isAfter(hideTime);
  }

  int _parseSetupTime(String setupTime) {
    // Handle various formats like "2 hrs", "3 hours", "1 hr", etc.
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(setupTime.toLowerCase());

    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }

    // Default to 1 hour if parsing fails
    return 1;
  }

  String _formatTime12Hour(String rawTime) {
    final value = rawTime.trim();
    if (value.isEmpty) return rawTime;

    final directDateTime = DateTime.tryParse(value);
    if (directDateTime != null) {
      return DateFormat('h:mm a').format(directDateTime).toLowerCase();
    }

    final patterns = ['HH:mm:ss', 'HH:mm', 'H:mm', 'h:mm a', 'h:mm:ss a'];
    for (final pattern in patterns) {
      try {
        final parsed = DateFormat(pattern).parseStrict(value);
        return DateFormat('h:mm a').format(parsed).toLowerCase();
      } catch (_) {
        // Try next format
      }
    }

    return rawTime;
  }

  Widget _buildSetupTimelineStep({
    required int stepNumber,
    required Color color,
    required String timeText,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 2,
                  height: 42,
                  color: AppTheme.dividerColor.withOpacity(0.55),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step $stepNumber: $title',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getContactRevealMessage(Order order) {
    final setupHours = _parseSetupTime(order.setupTime ?? '1 hr');
    final revealHours = setupHours + 2;

    return 'Contact will be revealed $revealHours hours before setup begins';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return Colors.green;
      case 'on_the_way':
        return AppTheme.accentPurple;
      case 'qr_verified':
        return AppTheme.accentTeal;
      case 'started':
        return AppTheme.warningColor;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textDisabledColor;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'on_the_way':
        return 'On The Way';
      case 'qr_verified':
        return 'QR Verified';
      case 'started':
        return 'Setup Started';
      default:
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  Widget _buildFlatInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _openInGoogleMaps(Order order) async {
    try {
      bool urlLaunched = false;

      if (order.addressLatitude != null && order.addressLongitude != null) {
        final lat = order.addressLatitude!;
        final lng = order.addressLongitude!;

        // Try multiple URL schemes for better compatibility
        final urls = [
          'https://maps.google.com/?q=$lat,$lng&navigate=yes',
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          'geo:$lat,$lng?q=$lat,$lng(Order Location)',
          'https://maps.google.com/?q=$lat,$lng',
        ];

        for (final urlString in urls) {
          try {
            final uri = Uri.parse(urlString);
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
              webOnlyWindowName: '_blank',
            );
            _showSnackBar('Opening Maps...');
            urlLaunched = true;
            break;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to launch $urlString: $e');
            }
            continue;
          }
        }
      } else if (order.venueAddress != null && order.venueAddress!.isNotEmpty) {
        final encodedAddress = Uri.encodeComponent(order.venueAddress!);

        // Try different URL schemes with address
        final urls = [
          'https://maps.google.com/?q=$encodedAddress&navigate=yes',
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress',
          'https://maps.google.com/?q=$encodedAddress',
        ];

        for (final urlString in urls) {
          try {
            final uri = Uri.parse(urlString);
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
              webOnlyWindowName: '_blank',
            );
            _showSnackBar('Opening Maps...');
            urlLaunched = true;
            break;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to launch $urlString: $e');
            }
            continue;
          }
        }
      } else {
        _showSnackBar('Location not available', isError: true);
        return;
      }

      if (!urlLaunched) {
        _showSnackBar(
            'Unable to open maps. Please check your internet connection or install a maps app.',
            isError: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _openInGoogleMaps: $e');
      }
      _showSnackBar('Error opening maps. Please try again.', isError: true);
    }
  }

  Future<void> _markAsOnTheWay(Order order) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
            orderId: order.id,
            status: 'on_the_way',
          );
      ref.invalidate(ordersProvider);
      _showSnackBar('Status updated to "On The Way"');
    } catch (e) {
      _showSnackBar('Failed to update status: $e', isError: true);
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Future<void> _scanQRCode(Order order) async {
    // Navigate to QR scanner screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderQRScannerScreen(orderId: order.id),
      ),
    );

    if (result == true) {
      // QR verified successfully
      setState(() {
        _isUpdatingStatus = true;
      });

      try {
        await ref.read(orderServiceProvider).updateOrderStatus(
              orderId: order.id,
              status: 'qr_verified',
            );
        ref.invalidate(ordersProvider);
        _showSnackBar('QR Code verified successfully!');
      } catch (e) {
        _showSnackBar('Failed to verify QR code: $e', isError: true);
      } finally {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _startSetup(Order order) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
            orderId: order.id,
            status: 'started',
          );
      ref.invalidate(ordersProvider);
      _showSnackBar('Setup started! Please upload before and after photos.');
    } catch (e) {
      _showSnackBar('Failed to start setup: $e', isError: true);
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          backgroundColor:
              isError ? AppTheme.errorColor : AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// Order QR Scanner Screen
class OrderQRScannerScreen extends StatefulWidget {
  final String orderId;

  const OrderQRScannerScreen({super.key, required this.orderId});

  @override
  State<OrderQRScannerScreen> createState() => _OrderQRScannerScreenState();
}

class _OrderQRScannerScreenState extends State<OrderQRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ListenableBuilder(
              listenable: controller,
              builder: (context, child) {
                return Icon(
                  controller.value.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ListenableBuilder(
              listenable: controller,
              builder: (context, child) {
                return Icon(
                  controller.value.cameraDirection == CameraFacing.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                );
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scan customer QR code to verify pickup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    if (!isScanned && barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          isScanned = true;
        });

        // Verify QR code matches order
        if (barcode.rawValue == widget.orderId ||
            barcode.rawValue!.contains(widget.orderId)) {
          // QR verified successfully
          Navigator.pop(context, true);
        } else {
          // Invalid QR code
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid QR code for this order'),
              backgroundColor: Colors.red,
            ),
          );

          // Reset for another scan
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                isScanned = false;
              });
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
