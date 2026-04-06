import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/service_listings/service/service_listing_service.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  final BookingService _bookingService = BookingService();
  Booking? _booking;
  bool _isLoading = true;
  bool _isAccepting = false;
  bool _isDeclining = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);

    try {
      // Decode the booking ID in case it was URL encoded
      final decodedBookingId = Uri.decodeComponent(widget.bookingId);
// TODO: Replace with proper logging - print('🔍 Loading booking details for ID: $decodedBookingId (original: ${widget.bookingId})');

      final booking = await _bookingService.getBookingDetails(decodedBookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load booking details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptBooking() async {
    if (_booking == null) return;

    setState(() => _isAccepting = true);

    try {
      final success = await _bookingService.acceptBooking(_booking!.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate booking was accepted
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to accept booking. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isAccepting = false);
    }
  }

  Future<void> _declineBooking() async {
    if (_booking == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking'),
        content: const Text(
            'Are you sure you want to decline this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeclining = true);

    try {
      final success = await _bookingService.declineBooking(_booking!.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking declined successfully.'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop(true); // Return true to indicate booking was declined
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to decline booking. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDeclining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(
                  child: Text(
                    'Booking not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : _buildBookingDetails(),
    );
  }

  Widget _buildBookingDetails() {
    final booking = _booking!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booking.status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Service Information
          _buildInfoCard(
            title: 'Service Details',
            children: [
              _buildInfoRow('Service', booking.serviceTitle),
              _buildInfoRow(
                  'Amount', '₹${booking.totalAmount.toStringAsFixed(0)}'),
              if (booking.originalPrice != null)
                _buildInfoRow('Original Price',
                    '₹${booking.originalPrice!.toStringAsFixed(0)}'),
              if (booking.offerPrice != null)
                _buildInfoRow('Offer Price',
                    '₹${booking.offerPrice!.toStringAsFixed(0)}'),
              _buildInfoRow(
                  'Booking Date',
                  DateFormat('E, MMM d, yyyy - h:mm a')
                      .format(booking.bookingDate)),
            ],
          ),

          const SizedBox(height: 16),

          // Customer Information
          _buildInfoCard(
            title: 'Customer Details',
            children: [
              _buildInfoRow('Name', booking.customerName ?? 'Customer'),
              if (booking.customerEmail != null)
                _buildInfoRow('Email', booking.customerEmail!)
              else
                _buildInfoRow('Email', 'Not available'),
              _buildInfoRow('Customer ID', booking.userId),
            ],
          ),

          const SizedBox(height: 16),

          // Booking Information
          _buildInfoCard(
            title: 'Booking Information',
            children: [
              _buildInfoRow('Booking ID', booking.id),
              _buildInfoRow('Created',
                  DateFormat('MMM d, yyyy - h:mm a').format(booking.createdAt)),
              _buildInfoRow('Last Updated',
                  DateFormat('MMM d, yyyy - h:mm a').format(booking.updatedAt)),
            ],
          ),

          const SizedBox(height: 16),

          // Setup Timeline Section
          FutureBuilder(
            future: ref
                .read(serviceListingServiceProvider)
                .getServiceListingById(booking.serviceListingId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildInfoCard(
                  title: 'Setup Timeline',
                  children: [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                final serviceListing = snapshot.data!;
                final setupTime = serviceListing.setupTime ?? '1 hr';

                // Parse setup time
                final setupHours = _parseSetupTime(setupTime);
                DateTime bookingDateTime = booking.bookingDate;

                // Parse booking time if available
                bookingDateTime = booking.bookingDate;

                // Calculate setup times
                final setupStartTime =
                    bookingDateTime.subtract(Duration(hours: setupHours));
                final setupEndTime = bookingDateTime;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
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
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: AppTheme.warningColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Setup Timeline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Setup Timeline Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.2),
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
                                    color:
                                        AppTheme.warningColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.schedule,
                                    color: AppTheme.warningColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Setup Timeline',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Setup starts',
                              DateFormat('h:mm a').format(setupStartTime),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Setup completes',
                              DateFormat('h:mm a').format(setupEndTime),
                            ),
                            const SizedBox(height: 12),
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
                                    'Please reach before setup time starts to ensure smooth decoration setup.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimaryColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Order needs to be completed by the booking time to make the event successful.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 30),

          // Action Buttons (only show if booking is pending)
          if (booking.status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeclining ? null : _declineBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isDeclining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Decline',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _acceptBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Accept',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

  Future<void> _openInGoogleMaps(Booking booking) async {
    // For now, show a message that location information is not available
    // The Booking model doesn't include venue address or coordinates
    _showSnackBar('Location information not available for this booking',
        isError: true);
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
