import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../service/order_service.dart';

class OrderCompletionScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderCompletionScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderCompletionScreen> createState() =>
      _OrderCompletionScreenState();
}

class _OrderCompletionScreenState extends ConsumerState<OrderCompletionScreen> {
  bool _isUploadingImage = false;
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider('All'));

    return allOrders.when(
      data: (orders) {
        final order = orders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => throw Exception('Order not found'),
        );
        return _buildContent(order);
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Complete Order'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(Order order) {
    final orderValuesAsync = ref.watch(orderValuesProvider(order));
    final bool beforeUploaded = order.beforeDecorationImage != null;
    final bool afterUploaded = order.afterDecorationImage != null;
    final bool photosUploaded = beforeUploaded && afterUploaded;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Complete Order',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppTheme.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service title chip
                  _buildServiceHeader(order),
                  const SizedBox(height: 20),

                  // Payout summary
                  _buildPayoutCard(orderValuesAsync),
                  const SizedBox(height: 16),

                  // Collect from customer
                  _buildCollectCard(orderValuesAsync),
                  const SizedBox(height: 20),

                  // Photo upload
                  _buildPhotoSection(order, beforeUploaded, afterUploaded),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom action bar
          _buildBottomBar(order, photosUploaded),
        ],
      ),
    );
  }

  Widget _buildServiceHeader(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.celebration_rounded,
                color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.serviceTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'In Progress',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF57C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(AsyncValue<Map<String, double>> orderValuesAsync) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Payout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  orderValuesAsync.when(
                    data: (v) => Text(
                      '₹${v['revenue']!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Breakdown
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: orderValuesAsync.when(
                data: (v) => Column(
                  children: [
                    _payoutRow('Order Value',
                        '₹${v['totalOrderValue']!.toStringAsFixed(0)}'),
                    const SizedBox(height: 10),
                    _payoutRow('Platform Fee (incl. GST)',
                        '−₹${v['platformFee']!.toStringAsFixed(0)}',
                        valueColor: AppTheme.errorColor),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    _payoutRow(
                      'SyloNow Transfer',
                      '₹${v['sylonowPayout']!.toStringAsFixed(0)}',
                      valueColor: AppTheme.successColor,
                      bold: true,
                    ),
                  ],
                ),
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payoutRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              color: bold
                  ? AppTheme.textPrimaryColor
                  : AppTheme.textSecondaryColor,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimaryColor,
            )),
      ],
    );
  }

  Widget _buildCollectCard(AsyncValue<Map<String, double>> orderValuesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded,
                color: Color(0xFFF57C00), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collect from Customer',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                orderValuesAsync.when(
                  data: (v) => Text(
                    '₹${v['amountToCollect']!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                  loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.currency_rupee, size: 14,
                    color: AppTheme.textSecondaryColor),
                Text('Cash /\nUPI',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondaryColor,
                        height: 1.3),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(
      Order order, bool beforeUploaded, bool afterUploaded) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_camera_rounded,
                    size: 16, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              const Text(
                'Proof Photos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '${(beforeUploaded ? 1 : 0) + (afterUploaded ? 1 : 0)}/2',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (beforeUploaded && afterUploaded)
                      ? AppTheme.successColor
                      : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Photo cards row
          Row(
            children: [
              Expanded(
                child: _buildPhotoCard(
                  label: 'Before',
                  subtitle: 'Before service',
                  imageUrl: order.beforeDecorationImage,
                  canUpload: true,
                  isUploaded: beforeUploaded,
                  onTap: () => _uploadPhoto(order, isBefore: true),
                  onRemove: beforeUploaded
                      ? () => _removePhoto(order, isBefore: true)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPhotoCard(
                  label: 'After',
                  subtitle: 'After service',
                  imageUrl: order.afterDecorationImage,
                  canUpload: beforeUploaded,
                  isUploaded: afterUploaded,
                  onTap: () => _uploadPhoto(order, isBefore: false),
                  onRemove: afterUploaded
                      ? () => _removePhoto(order, isBefore: false)
                      : null,
                ),
              ),
            ],
          ),

          // Hint text
          if (!beforeUploaded || !afterUploaded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      !beforeUploaded
                          ? 'Start by uploading the before photo'
                          : 'Now upload the after photo to proceed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String label,
    required String subtitle,
    required String? imageUrl,
    required bool canUpload,
    required bool isUploaded,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: _isUploadingImage || !canUpload ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo area with fixed aspect ratio
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? Colors.black
                        : canUpload
                            ? const Color(0xFFF0F4FF)
                            : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUploaded
                          ? AppTheme.successColor
                          : canUpload
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : const Color(0xFFE0E0E0),
                      width: isUploaded ? 2 : 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _isUploadingImage
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : imageUrl != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          color: AppTheme.textSecondaryColor),
                                    ),
                                  ),
                                  // Retake overlay at bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black87,
                                          ],
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_rounded,
                                              size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text('Retake',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: canUpload
                                            ? AppTheme.primaryColor
                                                .withOpacity(0.12)
                                            : const Color(0xFFEEEEEE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        canUpload
                                            ? Icons.camera_alt_rounded
                                            : Icons.lock_outline_rounded,
                                        size: 20,
                                        color: canUpload
                                            ? AppTheme.primaryColor
                                            : const Color(0xFFBDBDBD),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      canUpload ? 'Tap to capture' : 'Locked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: canUpload
                                            ? AppTheme.primaryColor
                                            : const Color(0xFFBDBDBD),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),

                // Remove (×) button
                if (imageUrl != null && onRemove != null && !_isUploadingImage)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),

                // Done badge
                if (isUploaded)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Done',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Label below card
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUploaded
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 13,
                color: isUploaded
                    ? AppTheme.successColor
                    : canUpload
                        ? AppTheme.primaryColor
                        : const Color(0xFFBDBDBD),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUploaded
                      ? AppTheme.successColor
                      : canUpload
                          ? AppTheme.textPrimaryColor
                          : const Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Order order, bool photosUploaded) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!photosUploaded)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13,
                      color: AppTheme.textSecondaryColor.withOpacity(0.7)),
                  const SizedBox(width: 5),
                  Text(
                    'Upload both photos to enable completion',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: photosUploaded && !_isCompleting
                  ? () => _markAsCompleted(order)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB0BEC5),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mark as Completed',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(Order order, {required bool isBefore}) async {
    if (!isBefore && order.beforeDecorationImage == null) {
      _showSnackBar('Upload the before photo first.', isError: true);
      return;
    }
    setState(() => _isUploadingImage = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await ref.read(orderServiceProvider).uploadDecorationImage(
              orderId: order.id,
              imageType: isBefore ? 'before' : 'after',
              imagePath: pickedFile.path,
            );
        ref.invalidate(ordersProvider('All'));
        _showSnackBar(
            '${isBefore ? 'Before' : 'After'} photo uploaded!');
      }
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _removePhoto(Order order, {required bool isBefore}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Photo',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Remove the ${isBefore ? 'before' : 'after'} photo? You can take a new one after.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isUploadingImage = true);
    try {
      await ref.read(orderServiceProvider).clearDecorationImage(
            orderId: order.id,
            imageType: isBefore ? 'before' : 'after',
          );
      ref.invalidate(ordersProvider('All'));
      _showSnackBar('Photo removed.');
    } catch (e) {
      _showSnackBar('Failed to remove: $e', isError: true);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _markAsCompleted(Order order) async {
    setState(() => _isCompleting = true);
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
            orderId: order.id,
            status: 'completed',
          );
      ref.invalidate(ordersProvider);
      if (mounted) {
        context.go('/order-success/${order.id}',
            extra: order.copyWith(status: 'completed'));
      }
    } catch (e) {
      _showSnackBar('Failed to complete: $e', isError: true);
      setState(() => _isCompleting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}
