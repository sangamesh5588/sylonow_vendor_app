import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';
import '../models/theater_screen.dart';
import '../models/theater_time_slot.dart';
import '../providers/theater_screens_provider.dart';
import '../providers/theater_time_slot_provider.dart';
import '../service/theater_time_slot_service.dart';

class TimeSlotManagementScreen extends ConsumerStatefulWidget {
  final String screenId;
  final String screenName;
  final String theaterId;

  const TimeSlotManagementScreen({
    super.key,
    required this.screenId,
    required this.screenName,
    required this.theaterId,
  });

  @override
  ConsumerState<TimeSlotManagementScreen> createState() =>
      _TimeSlotManagementScreenState();
}

class _TimeSlotManagementScreenState
    extends ConsumerState<TimeSlotManagementScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _slotBookingStatus = {};
  bool _isDeleteMode = false; // New state for delete mode

  @override
  void initState() {
    super.initState();
    _loadBookingStatusForDate();
  }

  @override
  Widget build(BuildContext context) {
    final timeSlotsAsync = ref.watch(screenTimeSlotsProvider(widget.screenId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const HeroIcon(
            HeroIcons.arrowLeft,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              widget.screenName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Manage time slots',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Date Selection View
          _buildDateSelectionView(),

          // Time Slots Grid
          Expanded(
            child: timeSlotsAsync.when(
              data: (timeSlots) => _buildTimeSlotGrid(timeSlots),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Loading time slots...',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(
                      HeroIcons.exclamationTriangle,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load time slots',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        ref.invalidate(screenTimeSlotsProvider);
                      },
                      icon: const HeroIcon(HeroIcons.arrowPath, size: 16),
                      label: const Text('Try Again'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeTo12Hour(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  String _formatTimeStringTo12Hour(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  String _calculateDuration(String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    // Convert to minutes for easier calculation
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    // Handle case where end time is on next day
    final durationMinutes = endTotalMinutes >= startTotalMinutes
        ? endTotalMinutes - startTotalMinutes
        : (24 * 60 - startTotalMinutes) + endTotalMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  Widget _buildTimeSlotGrid(List<TheaterTimeSlot> timeSlots) {
    // Get screen information to display correct price
    final screensAsync = ref.watch(theaterScreensProvider(widget.theaterId));

    return screensAsync.when(
      data: (screens) {
        final screen = screens.firstWhere(
          (s) => s.id == widget.screenId,
          orElse: () => TheaterScreen(
            id: widget.screenId,
            theaterId: widget.theaterId,
            screenName: widget.screenName,
            screenNumber: 0,
          ),
        );

        // Create grid items - add plus button at the end
        final List<Widget> gridItems = [];

        // Add existing time slots
        for (final timeSlot in timeSlots) {
          gridItems.add(_buildTimeSlotGridItem(timeSlot, screen));
        }

        // Add plus button for adding new time slot (only if not in delete mode)
        if (!_isDeleteMode) {
          gridItems.add(_buildAddTimeSlotGridItem());
        }

        // If no time slots, show empty state with just the plus button
        if (timeSlots.isEmpty) {
          return Container(
            color: Colors.grey.shade50,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(
                    HeroIcons.clock,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No time slots yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button below to create\\nyour first time slot',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 100,
                    height: 70,
                    child: _buildAddTimeSlotGridItem(),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Delete mode indicator
              if (_isDeleteMode) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the X button on time slots to delete them',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDeleteMode = false;
                          });
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) => gridItems[index],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (err, stack) => Center(
        child: Text('Error loading screen info: $err'),
      ),
    );
  }

  Widget _buildTimeSlotGridItem(
      TheaterTimeSlot timeSlot, TheaterScreen screen) {
    final isBooked = _slotBookingStatus[timeSlot.id] ?? false;

    // Capacity display for the time slot

    return GestureDetector(
      onTap: () {
        if (_isDeleteMode) {
          _showDeleteConfirmation(timeSlot);
        } else {
          _showTimeSlotOptionsDialog(timeSlot);
        }
      },
      onLongPress: () {
        if (!_isDeleteMode) {
          setState(() {
            _isDeleteMode = true;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform:
            _isDeleteMode ? Matrix4.rotationZ(0.02) : Matrix4.rotationZ(0.0),
        child: Container(
          decoration: BoxDecoration(
            color: isBooked ? Colors.grey.shade200 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBooked ? Colors.grey.shade300 : AppTheme.primaryColor,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Delete button (only visible in delete mode)
              if (_isDeleteMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _showDeleteConfirmation(timeSlot),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _formatTimeTo12Hour(timeSlot.startTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isBooked ? Colors.grey.shade600 : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Flexible(
                      child: Text(
                        _formatTimeTo12Hour(timeSlot.endTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isBooked
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        _calculateDuration(
                            timeSlot.startTime, timeSlot.endTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isBooked
                              ? Colors.grey.shade500
                              : AppTheme.accentTeal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isBooked) ...[
                      const SizedBox(height: 2),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: ref
                            .read(theaterTimeSlotServiceProvider)
                            .getBookingDetailsForSlotAndDate(
                                timeSlot.id, _selectedDate),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final bookingType = snapshot.data!['type'];
                            final isCustomerBooking =
                                bookingType == 'customer_booking';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isCustomerBooking
                                    ? Colors.blue.shade400
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCustomerBooking ? 'CUSTOMER' : 'BLOCKED',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BOOKED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTimeSlotGridItem() {
    return GestureDetector(
      onTap: () => _showCreateTimeSlotDialog(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              HeroIcons.plus,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 4),
            Text(
              'Add Slot',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotOptionsDialog(TheaterTimeSlot timeSlot) async {
    final isBooked = _slotBookingStatus[timeSlot.id] ?? false;

    // Get detailed booking information if slot is booked
    Map<String, dynamic>? bookingDetails;
    if (isBooked) {
      bookingDetails = await ref
          .read(theaterTimeSlotServiceProvider)
          .getBookingDetailsForSlotAndDate(timeSlot.id, _selectedDate);
    }

    if (!mounted) return;

    // Get screen information to display correct price
    final screensAsync = ref.read(theaterScreensProvider(widget.theaterId));
    TheaterScreen screen;
    if (screensAsync.hasValue) {
      screen = screensAsync.value!.firstWhere(
        (s) => s.id == widget.screenId,
        orElse: () => TheaterScreen(
          id: widget.screenId,
          theaterId: widget.theaterId,
          screenName: widget.screenName,
          screenNumber: 0,
        ),
      );
    } else {
      screen = TheaterScreen(
        id: widget.screenId,
        theaterId: widget.theaterId,
        screenName: widget.screenName,
        screenNumber: 0,
      );
    }

    // Capacity display for the time slot

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Time Slot: ${_formatTimeTo12Hour(timeSlot.startTime)} - ${_formatTimeTo12Hour(timeSlot.endTime)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capacity: ${screen.allowedCapacity}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            if (isBooked && bookingDetails != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (bookingDetails['type'] == 'customer_booking') ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Customer Booking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: ${bookingDetails['customer_name']}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'Status: ${bookingDetails['booking_status'].toString().toUpperCase()}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.bookmark,
                        size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Vendor Marked',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Marked as unavailable by you',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (!isBooked)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markAsBookedForSelectedDate(timeSlot);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Booked'),
            )
          else if (bookingDetails != null &&
              bookingDetails['can_unbook'] == true)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unmarkAsBookedForDate(timeSlot);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove Booking'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditTimeSlotBottomSheet(timeSlot);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(timeSlot);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateTimeSlotDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimeSlotFormBottomSheet(
        screenId: widget.screenId,
        theaterId: widget.theaterId,
        onSlotCreated: () {
          ref.invalidate(screenTimeSlotsProvider);
        },
      ),
    );
  }

  void _showEditTimeSlotBottomSheet(TheaterTimeSlot timeSlot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimeSlotFormBottomSheet(
        screenId: widget.screenId,
        theaterId: widget.theaterId,
        timeSlot: timeSlot,
        onSlotCreated: () {
          ref.invalidate(screenTimeSlotsProvider);
        },
      ),
    );
  }

  Widget _buildDateSelectionView() {
    return Container(
      height: 120,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 30, // Next 30 days
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, DateTime.now());

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _loadBookingStatusForDate();
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppTheme.primaryColor
                                    : Colors.black87,
                          ),
                        ),
                        Text(
                          _getMonthName(date.month).substring(0, 3),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Future<void> _loadBookingStatusForDate() async {
    try {
      final timeSlotsAsync = ref.read(screenTimeSlotsProvider(widget.screenId));
      if (timeSlotsAsync.hasValue) {
        final timeSlots = timeSlotsAsync.value!;
        final Map<String, bool> newStatus = {};

        for (final slot in timeSlots) {
          final isBooked = await ref
              .read(theaterTimeSlotServiceProvider)
              .isSlotBookedForDate(slot.id, _selectedDate);
          newStatus[slot.id] = isBooked;
        }

        if (mounted) {
          setState(() {
            _slotBookingStatus = newStatus;
          });
        }
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to load booking status: $e');
    }
  }

  Future<void> _markAsBookedForSelectedDate(TheaterTimeSlot timeSlot) async {
    await _markAsBooked(timeSlot, _selectedDate);
    await _loadBookingStatusForDate();
  }

  Future<void> _unmarkAsBookedForDate(TheaterTimeSlot timeSlot) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removing booking...')),
      );

      await ref
          .read(theaterTimeSlotServiceProvider)
          .unmarkSlotAsBookedForDate(timeSlot.id, _selectedDate);

      await _loadBookingStatusForDate();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final dateStr =
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking removed for $dateStr'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsBooked(TheaterTimeSlot timeSlot, DateTime date) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marking slot as booked...')),
      );

      await ref
          .read(theaterTimeSlotServiceProvider)
          .markSlotAsBooked(timeSlot.id, date);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final dateStr = '${date.day}/${date.month}/${date.year}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time slot marked as booked for $dateStr'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as booked: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(TheaterTimeSlot timeSlot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: Text(
          'Are you sure you want to delete the time slot ${timeSlot.startTime} - ${timeSlot.endTime}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTimeSlot(timeSlot);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTimeSlot(TheaterTimeSlot timeSlot) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting time slot...')),
      );

      await ref
          .read(theaterTimeSlotServiceProvider)
          .deleteTimeSlot(timeSlot.id);

      ref.invalidate(screenTimeSlotsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time slot deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete time slot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _QuickCreateTimeSlotDialog extends ConsumerStatefulWidget {
  final String screenId;
  final String theaterId;
  final VoidCallback onSlotCreated;

  const _QuickCreateTimeSlotDialog({
    required this.screenId,
    required this.theaterId,
    required this.onSlotCreated,
  });

  @override
  ConsumerState<_QuickCreateTimeSlotDialog> createState() =>
      _QuickCreateTimeSlotDialogState();
}

class _QuickCreateTimeSlotDialogState
    extends ConsumerState<_QuickCreateTimeSlotDialog> {
  final _commonTimeSlots = [
    {
      'start': '09:00',
      'end': '17:00',
      'name': 'Full Day',
      'display': '9:00 AM - 5:00 PM'
    },
    {
      'start': '09:00',
      'end': '13:00',
      'name': 'Morning',
      'display': '9:00 AM - 1:00 PM'
    },
    {
      'start': '14:00',
      'end': '18:00',
      'name': 'Afternoon',
      'display': '2:00 PM - 6:00 PM'
    },
    {
      'start': '19:00',
      'end': '23:00',
      'name': 'Evening',
      'display': '7:00 PM - 11:00 PM'
    },
    {
      'start': '10:00',
      'end': '22:00',
      'name': 'Extended',
      'display': '10:00 AM - 10:00 PM'
    },
  ];

  bool _isLoading = false;
  String? _errorMessage;

  String _formatTimeStringTo12Hour(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  String _calculateDuration(String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    // Convert to minutes for easier calculation
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    // Handle case where end time is on next day
    final durationMinutes = endTotalMinutes >= startTotalMinutes
        ? endTotalMinutes - startTotalMinutes
        : (24 * 60 - startTotalMinutes) + endTotalMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const HeroIcon(
              HeroIcons.bolt,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add Time Slots',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Choose from common time slots',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...(_commonTimeSlots.map((slot) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _isLoading ? null : () => _createTimeSlot(slot),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const HeroIcon(
                              HeroIcons.clock,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  slot['display'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _calculateDuration(slot['start'] as String,
                                      slot['end'] as String),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.accentTeal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Screen Price',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))),

            // Error Message Display
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _createTimeSlot(Map<String, dynamic> slot) async {
    // Clear any previous error message
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Check for overlapping time slots
      final service = ref.read(theaterTimeSlotServiceProvider);
      final overlapResult = await service.checkTimeSlotOverlap(
        widget.screenId,
        slot['start'] as String,
        slot['end'] as String,
      );

      if (overlapResult != null) {
        final overlappingSlots =
            overlapResult['overlapping_slots'] as List<dynamic>;
        String errorMessage =
            'Time slot "${slot['name']}" conflicts with existing slot(s):\n';

        for (final overlappingSlot in overlappingSlots) {
          final slotStart = overlappingSlot['start_time'] as String;
          final slotEnd = overlappingSlot['end_time'] as String;
          errorMessage +=
              '• ${_formatTimeStringTo12Hour(slotStart)} - ${_formatTimeStringTo12Hour(slotEnd)}\n';
        }
        errorMessage +=
            '\nYou can only create time slots that are completely separate from existing ones.';

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
        return;
      }

      final newTimeSlot = TheaterTimeSlot(
        id: '',
        theaterId: widget.theaterId,
        screenId: widget.screenId,
        startTime: slot['start'] as String,
        endTime: slot['end'] as String,
        basePrice: 0.0, // Default price for quick create
        pricePerHour: 0.0, // Default price for quick create
        isAvailable: true,
        isActive: true,
      );

      await ref
          .read(theaterTimeSlotServiceProvider)
          .createTimeSlot(newTimeSlot);

      widget.onSlotCreated();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time slot "${slot['name']}" created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create time slot: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _TimeSlotFormBottomSheet extends ConsumerStatefulWidget {
  final String screenId;
  final String theaterId;
  final TheaterTimeSlot? timeSlot;
  final VoidCallback onSlotCreated;

  const _TimeSlotFormBottomSheet({
    required this.screenId,
    required this.theaterId,
    this.timeSlot,
    required this.onSlotCreated,
  });

  @override
  ConsumerState<_TimeSlotFormBottomSheet> createState() =>
      _TimeSlotFormBottomSheetState();
}

class _TimeSlotFormBottomSheetState
    extends ConsumerState<_TimeSlotFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _comparePriceController = TextEditingController();
  final _priceController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.timeSlot != null) {
      // Parse existing time slot times
      final startParts = widget.timeSlot!.startTime.split(':');
      final endParts = widget.timeSlot!.endTime.split(':');
      _startTime = TimeOfDay(
          hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      _endTime = TimeOfDay(
          hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

      // Set the prices from existing time slot
      _comparePriceController.text = widget.timeSlot!.comparePrice.toString();
      _priceController.text = widget.timeSlot!.basePrice.toString();
    }
  }

  @override
  void dispose() {
    _comparePriceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeTo12Hour(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');

    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  String _formatTimeStringTo12Hour(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  String _calculateDuration(String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    // Convert to minutes for easier calculation
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    // Handle case where end time is on next day
    final durationMinutes = endTotalMinutes >= startTotalMinutes
        ? endTotalMinutes - startTotalMinutes
        : (24 * 60 - startTotalMinutes) + endTotalMinutes;

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? _startTime ?? TimeOfDay.now()
          : _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodBorderSide:
                  const BorderSide(color: AppTheme.primaryColor),
              dayPeriodColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              dayPeriodTextColor: AppTheme.primaryColor,
              hourMinuteColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              hourMinuteTextColor: AppTheme.primaryColor,
              dialHandColor: AppTheme.primaryColor,
              dialBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              dialTextColor: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.timeSlot != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            isEditing ? 'Edit Time Slot' : 'Create Time Slot',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                // Time Selection Column
                Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const HeroIcon(
                                  HeroIcons.clock,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _startTime != null
                                      ? _formatTimeTo12Hour(_startTime!)
                                      : 'Select start time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _startTime != null
                                        ? AppTheme.textPrimaryColor
                                        : AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(false),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const HeroIcon(
                                  HeroIcons.clock,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _endTime != null
                                      ? _formatTimeTo12Hour(_endTime!)
                                      : 'Select end time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _endTime != null
                                        ? AppTheme.textPrimaryColor
                                        : AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Compare Price Field
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Base Price (₹)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Original price to show discount',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _comparePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter compare price',
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter compare price';
                        }
                        final comparePrice = double.tryParse(value.trim());
                        if (comparePrice == null || comparePrice <= 0) {
                          return 'Please enter a valid price greater than 0';
                        }

                        // Check if base price is entered and validate
                        final basePriceText = _priceController.text.trim();
                        if (basePriceText.isNotEmpty) {
                          final basePrice = double.tryParse(basePriceText);
                          if (basePrice != null && comparePrice <= basePrice) {
                            return 'Compare price must be higher than base price';
                          }
                        }

                        return null;
                      },
                    ),
                  ],
                ),

                // Base Price Field
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discounted Price (₹)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Actual price (should be lower)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter base price',
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a base price';
                        }
                        final basePrice = double.tryParse(value.trim());
                        if (basePrice == null || basePrice <= 0) {
                          return 'Please enter a valid price greater than 0';
                        }

                        // Check if compare price is entered and validate
                        final comparePriceText = _comparePriceController.text.trim();
                        if (comparePriceText.isNotEmpty) {
                          final comparePrice = double.tryParse(comparePriceText);
                          if (comparePrice != null && basePrice >= comparePrice) {
                            return 'Base price must be lower than compare price';
                          }
                        }

                        return null;
                      },
                    ),
                  ],
                ),

                // Duration Display
                if (_startTime != null && _endTime != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.accentTeal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const HeroIcon(
                          HeroIcons.clock,
                          size: 16,
                          color: AppTheme.accentTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${_calculateDuration(_formatTimeOfDay(_startTime!), _formatTimeOfDay(_endTime!))}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Error Message Display
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTimeSlot,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update' : 'Create',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _saveTimeSlot() async {
    // Clear any previous error message
    setState(() {
      _errorMessage = null;
    });

    if (_startTime == null || _endTime == null) {
      setState(() {
        _errorMessage = 'Please select both start and end times';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.timeSlot != null;
      final startTimeStr = _formatTimeOfDay(_startTime!);
      final endTimeStr = _formatTimeOfDay(_endTime!);
      final comparePrice = double.parse(_comparePriceController.text.trim());
      final basePrice = double.parse(_priceController.text.trim());

      // Check for overlapping time slots (only for new slots, not when editing)
      if (!isEditing) {
        final service = ref.read(theaterTimeSlotServiceProvider);
        final overlapResult = await service.checkTimeSlotOverlap(
          widget.screenId,
          startTimeStr,
          endTimeStr,
        );

        if (overlapResult != null) {
          final overlappingSlots =
              overlapResult['overlapping_slots'] as List<dynamic>;
          String errorMessage = 'Time slot conflicts with existing slot(s):\n';

          for (final slot in overlappingSlots) {
            final slotStart = slot['start_time'] as String;
            final slotEnd = slot['end_time'] as String;
            errorMessage +=
                '• ${_formatTimeStringTo12Hour(slotStart)} - ${_formatTimeStringTo12Hour(slotEnd)}\n';
          }
          errorMessage +=
              '\nYou can only create time slots that are completely separate from existing ones.';

          setState(() {
            _errorMessage = errorMessage;
            _isLoading = false;
          });
          return;
        }
      }

      if (isEditing) {
        // Update existing time slot
        await ref.read(theaterTimeSlotServiceProvider).updateTimeSlot(
          widget.timeSlot!.id,
          {
            'start_time': startTimeStr,
            'end_time': endTimeStr,
            'compare_price': comparePrice,
            'base_price': basePrice,
            'price_per_hour': basePrice, // Also update price_per_hour for compatibility
          },
        );
      } else {
        // Create new time slot
        final newTimeSlot = TheaterTimeSlot(
          id: '', // Will be auto-generated
          theaterId: widget.theaterId,
          screenId: widget.screenId,
          startTime: startTimeStr,
          endTime: endTimeStr,
          comparePrice: comparePrice, // Set compare price
          basePrice: basePrice, // Use the base price entered by user
          pricePerHour: basePrice, // Also set price_per_hour for compatibility
          isAvailable: true,
          isActive: true,
        );

        await ref
            .read(theaterTimeSlotServiceProvider)
            .createTimeSlot(newTimeSlot);
      }

      widget.onSlotCreated();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Time slot ${isEditing ? 'updated' : 'created'} successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to ${widget.timeSlot != null ? 'update' : 'create'} time slot: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
