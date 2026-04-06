import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/theater_booking.dart';
import '../providers/theater_booking_provider.dart';
import '../service/theater_booking_service.dart';

class TheaterBookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TheaterBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<TheaterBookingDetailScreen> createState() => _TheaterBookingDetailScreenState();
}

class _TheaterBookingDetailScreenState extends ConsumerState<TheaterBookingDetailScreen> {
  bool _isUpdating = false;

  /// Computes the correct pricing from first principles:
  /// total = slotBasePrice + addonsTotal + extraPersonCharges
  /// pending = total / 2
  /// adminPayout = pending - (total × 5% × 1.18)
  Map<String, double> _computePricing(TheaterBooking booking) {
    final addonsTotal = booking.selectedAddons
        .map((a) => (a as Map<String, dynamic>)['total_price'] as num? ?? 0)
        .fold<double>(0, (sum, v) => sum + v.toDouble());

    final slotPrice = booking.slotBasePrice;

    // Extra person charges: only when capacity is set AND booking exceeds it
    final hasCapacityLimit = booking.allowedCapacity > 0;
    final extraPersons = hasCapacityLimit
        ? (booking.numberOfPeople - booking.allowedCapacity).clamp(0, 999)
        : 0;
    final extraPersonCharges =
        extraPersons > 0 ? extraPersons * booking.chargesExtraPerPerson : 0.0;

    final correctTotal = slotPrice + addonsTotal + extraPersonCharges;
    final pendingAmount = correctTotal / 2;

    final commission = correctTotal * 0.05;
    final gstOnCommission = commission * 0.18;
    final platformFee = commission + gstOnCommission;
    final adminPayout = pendingAmount - platformFee;

    return {
      'addonsTotal': addonsTotal,
      'slotPrice': slotPrice,
      'extraPersons': extraPersons.toDouble(),
      'extraPersonCharges': extraPersonCharges,
      'correctTotal': correctTotal,
      'pendingAmount': pendingAmount,
      'platformFee': platformFee,
      'adminPayout': adminPayout,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
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
              HeroIcons.questionMarkCircle,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => _showSupportInfoDialog(),
          ),
        ],
      ),
      body: bookingAsync.when(
        data: (booking) {
          if (booking == null) {
            return _buildNotFound();
          }
          return _buildBookingContent(booking);
        },
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(error),
      ),
      bottomNavigationBar: bookingAsync.when(
        data: (booking) {
          if (booking == null || !_shouldShowActionButtons(booking)) {
            return null;
          }
          return _buildActionButtons(booking);
        },
        loading: () => null,
        error: (error, stack) => null,
      ),
    );
  }

  Widget _buildBookingContent(TheaterBooking booking) {
    final pricing = _computePricing(booking);
    final correctTotal = pricing['correctTotal']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theater Images
          _buildTheaterImages(booking),
          const SizedBox(height: 16),

          // Payment Breakdown Card (Highlighted) - Right below images
          if (correctTotal > 0) ...[
            _buildPaymentBreakdownCard(booking, pricing),
            const SizedBox(height: 16),
          ],

          // Booking Status Card
          _buildStatusCard(booking, correctTotal),
          const SizedBox(height: 16),

          // Booking Information
          _buildBookingInfoCard(booking),
          const SizedBox(height: 16),

          // Theater Information
          _buildTheaterInfoCard(booking),
          const SizedBox(height: 16),

          // Payment Information
          _buildPaymentInfoCard(booking, pricing),
          const SizedBox(height: 16),

          // Add-ons
          if (booking.selectedAddons.isNotEmpty) ...[
            _buildAddonsCard(booking),
            const SizedBox(height: 16),
          ],

          // Additional Information
          if (booking.specialRequests != null || booking.celebrationName != null)
            _buildAdditionalInfoCard(booking),

          // Add bottom padding to account for action buttons
          if (_shouldShowActionButtons(booking))
            const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownCard(TheaterBooking booking, Map<String, double> pricing) {
    final pendingAmount = pricing['pendingAmount']!;
    final adminPayout = pricing['adminPayout']!;
    final extraPersonCharges = pricing['extraPersonCharges']!;
    final extraPersons = pricing['extraPersons']!.toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha((255 * 0.3).round()),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha((255 * 0.1).round()),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha((255 * 0.15).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HeroIcon(
                  HeroIcons.currencyRupee,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment breakdown items
          if (extraPersons > 0)
            _buildPaymentBreakdownItem(
              'Extra Person Charges ($extraPersons)',
              extraPersonCharges,
              AppTheme.warningColor,
              HeroIcons.userGroup,
            ),

          if (pendingAmount > 0)
            _buildPaymentBreakdownItem(
              'Pending Amount',
              pendingAmount,
              AppTheme.warningColor,
              HeroIcons.clock,
            ),

          if (adminPayout > 0)
            _buildPaymentBreakdownItem(
              'Admin Payout',
              adminPayout,
              AppTheme.primaryColor,
              HeroIcons.buildingLibrary,
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownItem(String label, double amount, Color color, HeroIcons icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HeroIcon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Text(
            '₹${_formatNumber(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheaterImages(TheaterBooking booking) {
    return FutureBuilder<List<String>>(
      future: _getScreenImages(
        booking.theaterId,
        booking.screenName,
        booking.timeSlotId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final images = snapshot.data!;
          return Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [AppTheme.cardShadow],
            ),
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onTap: () => _showImagePreview(images, index),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildTheaterImagePlaceholder();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        }
        
        // Fallback to placeholder if no images available
        return _buildTheaterImagePlaceholder();
      }, 
    );
  }
  
  Future<List<String>> _getScreenImages(
    String theaterId,
    String? screenName,
    String? timeSlotId,
  ) async {
    try {
      final service = ref.read(theaterBookingServiceProvider);
      final response = await service.getScreenImages(
        theaterId,
        screenName: screenName,
        timeSlotId: timeSlotId,
      );
      return response;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch screen images: $e');
      return [];
    }
  }

  void _showImagePreview(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        final pageController = PageController(initialPage: initialIndex);

        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 48,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTheaterImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withAlpha((255 * 0.8).round()),
            AppTheme.primaryColor,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              HeroIcons.buildingOffice2,
              size: 48,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Screen Images',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowActionButtons(TheaterBooking booking) {
    // Show accept/reject buttons for confirmed bookings with pending payment
    // OR show QR scanner button for confirmed bookings with paid payment
    return booking.bookingStatus.toLowerCase() == 'confirmed' && 
           (booking.paymentStatus.toLowerCase() == 'pending' || 
            booking.paymentStatus.toLowerCase() == 'paid');
  }

  Widget _buildActionButtons(TheaterBooking booking) {
    final isAwaitingApproval = booking.bookingStatus.toLowerCase() == 'confirmed' && 
                              booking.paymentStatus.toLowerCase() == 'pending';
    final canVerifyBooking = booking.bookingStatus.toLowerCase() == 'confirmed' && 
                            booking.paymentStatus.toLowerCase() == 'paid';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (isAwaitingApproval) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _rejectBooking(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isUpdating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const HeroIcon(HeroIcons.xMark, size: 18),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _acceptBooking(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isUpdating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const HeroIcon(HeroIcons.check, size: 18),
                  label: const Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else if (canVerifyBooking) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _openQRScanner(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isUpdating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const HeroIcon(HeroIcons.qrCode, size: 18),
                  label: const Text(
                    'Scan QR to Complete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(TheaterBooking booking, double correctTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(booking.bookingStatus, large: true),
                    const SizedBox(width: 12),
                    _buildPaymentStatusChip(booking.paymentStatus, large: true),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '₹${_formatNumber(correctTotal)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildBookingInfoCard(TheaterBooking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            HeroIcons.calendar,
            'Date',
            _formatDate(booking.bookingDate),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            HeroIcons.clock,
            'Time',
            '${_formatTimeTo12Hour(booking.startTime)} - ${_formatTimeTo12Hour(booking.endTime)}',
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            HeroIcons.hashtag,
            'Booking ID',
            booking.id.substring(0, 8).toUpperCase(),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            HeroIcons.calendar,
            'Booked On',
            _formatDateTime(booking.createdAt ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildTheaterInfoCard(TheaterBooking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theater Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            HeroIcons.buildingOffice,
            'Theater',
            booking.theaterName ?? 'Unknown Theater',
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            HeroIcons.tv,
            'Screen',
            booking.screenName ?? 'Screen ${booking.screenNumber ?? 'Unknown'}',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(TheaterBooking booking, Map<String, double> pricing) {
    final addonsTotal = pricing['addonsTotal']!;
    final screenPrice = pricing['slotPrice']!;
    final extraPersonCharges = pricing['extraPersonCharges']!;
    final extraPersons = pricing['extraPersons']!.toInt();
    final correctTotal = pricing['correctTotal']!;
    final hasAddons = addonsTotal > 0;
    final hasExtraPersons = extraPersons > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              if (booking.paymentStatus == 'pending')
                TextButton(
                  onPressed: _isUpdating ? null : () => _updatePaymentStatus(booking, 'paid'),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mark as Paid'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Order Value Breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Screen base price row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const HeroIcon(
                        HeroIcons.tv,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Screen Price',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '₹${_formatNumber(screenPrice)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),

                // Add-ons row (only if there are add-ons)
                if (hasAddons) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const HeroIcon(
                          HeroIcons.sparkles,
                          size: 14,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add-ons (${booking.selectedAddons.length} item${booking.selectedAddons.length > 1 ? 's' : ''})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '₹${_formatNumber(addonsTotal)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    ],
                  ),
                ],

                // Extra person charges row (only if extra people)
                if (extraPersons > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const HeroIcon(
                          HeroIcons.userGroup,
                          size: 14,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Extra Person ($extraPersons person${extraPersons > 1 ? 's' : ''})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '₹${_formatNumber(extraPersonCharges)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Total row
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Order Value',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Text(
                      '₹${_formatNumber(correctTotal)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildInfoRow(
            HeroIcons.creditCard,
            'Payment Status',
            booking.paymentStatus.toUpperCase(),
          ),

          if (booking.paymentId != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              HeroIcons.hashtag,
              'Payment ID',
              booking.paymentId!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddonsCard(TheaterBooking booking) {
    final addons = booking.selectedAddons
        .map((a) => a as Map<String, dynamic>)
        .toList();

    double addonsTotal = 0;
    for (final a in addons) {
      addonsTotal += (a['total_price'] as num? ?? 0).toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HeroIcon(
                  HeroIcons.sparkles,
                  size: 20,
                  color: AppTheme.accentTeal,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add-ons',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${addons.length} item${addons.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...addons.asMap().entries.map((entry) {
            final i = entry.key;
            final addon = entry.value;
            final name = addon['addon_name'] as String? ?? 'Add-on';
            final category = addon['addon_category'] as String? ?? '';
            final addonImageUrl = addon['addon_image_url'] as String? ?? '';
            final qty = (addon['quantity'] as num? ?? 1).toInt();
            final unitPrice = (addon['unit_price'] as num? ?? 0).toDouble();
            final totalPrice = (addon['total_price'] as num? ?? 0).toDouble();

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Addon image — tappable to view full screen
                    GestureDetector(
                      onTap: addonImageUrl.isNotEmpty
                          ? () => _showImagePreview([addonImageUrl], 0)
                          : null,
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withAlpha((255 * 0.08).round()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withAlpha((255 * 0.15).round()),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: addonImageUrl.isNotEmpty
                                ? Image.network(
                                    addonImageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Center(
                                        child: HeroIcon(
                                          HeroIcons.sparkles,
                                          size: 28,
                                          color: AppTheme.accentTeal,
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: HeroIcon(
                                      HeroIcons.sparkles,
                                      size: 28,
                                      color: AppTheme.accentTeal,
                                    ),
                                  ),
                          ),
                          // Tap-to-view overlay badge (only when image exists)
                          if (addonImageUrl.isNotEmpty)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const HeroIcon(
                                  HeroIcons.magnifyingGlassPlus,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'x$qty @ ₹${unitPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                if (i < addons.length - 1) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add-ons Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                '₹${addonsTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(TheaterBooking booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          if (booking.celebrationName != null) ...[
            _buildInfoRow(
              HeroIcons.gift,
              'Celebration',
              booking.celebrationName!,
            ),
            const SizedBox(height: 12),
          ],
          
          if (booking.specialRequests != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeroIcon(
                  HeroIcons.chatBubbleLeftEllipsis,
                  size: 20,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Requests',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.specialRequests!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(HeroIcons icon, String label, String value, {VoidCallback? onTap}) {
    Widget content = Row(
      children: [
        HeroIcon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildStatusChip(String status, {bool large = false}) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppTheme.successColor;
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      case 'completed':
        color = AppTheme.primaryColor;
        break;
      case 'no_show':
        color = AppTheme.warningColor;
        break;
      case 'pending':
        color = AppTheme.warningColor;
        break;
      default:
        color = AppTheme.textSecondaryColor;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String paymentStatus, {bool large = false}) {
    Color color;
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        color = AppTheme.successColor;
        break;
      case 'pending':
        color = AppTheme.warningColor;
        break;
      case 'failed':
        color = AppTheme.errorColor;
        break;
      case 'refunded':
        color = AppTheme.textSecondaryColor;
        break;
      default:
        color = AppTheme.textSecondaryColor;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Text(
        paymentStatus.toUpperCase(),
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.exclamationTriangle,
            size: 48,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load booking details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
            icon: const HeroIcon(HeroIcons.arrowPath, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.questionMarkCircle,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Booking not found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The booking you are looking for does not exist',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const HeroIcon(HeroIcons.arrowLeft, size: 16),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            HeroIcon(
              HeroIcons.informationCircle,
              size: 24,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text('Need Help?'),
          ],
        ),
        content: const Text(
          'Contact Support if you want to contact customer.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptBooking(TheaterBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Booking'),
        content: const Text('Are you sure you want to accept this booking and mark payment as received?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Accept',
              style: TextStyle(color: AppTheme.successColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Mark payment as paid when accepting
      await _updatePaymentStatus(booking, 'paid');
    }
  }

  Future<void> _rejectBooking(TheaterBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateBookingStatus(booking, 'cancelled');
    }
  }

  Future<void> _updateBookingStatus(TheaterBooking booking, String status) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await ref.read(bookingDetailProvider(widget.bookingId).notifier)
          .updateBookingStatus(booking.id, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${status == 'cancelled' ? 'cancelled' : 'completed'} successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updatePaymentStatus(TheaterBooking booking, String paymentStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await ref.read(bookingDetailProvider(widget.bookingId).notifier)
          .updatePaymentStatus(booking.id, paymentStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment status updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(date.year, date.month, date.day);
    
    if (bookingDate == today) {
      return 'Today';
    } else if (bookingDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0);
  }

  String _formatTimeTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }
      
      return '${hour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  Future<void> _openQRScanner(TheaterBooking booking) async {
    try {
// TODO: Replace with proper logging - print('🔍 Opening QR scanner for booking: ${booking.id}');
      
      final result = await context.push<bool>('/qr-scanner/${booking.id}');
      
      if (result == true && mounted) {
        // QR verification was successful, update booking status to completed
        await _updateBookingStatus(booking, 'completed');
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Failed to open QR scanner: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open QR scanner: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
