/// Utility functions for phone number handling
class PhoneUtils {
  /// Masks a phone number by hiding middle digits
  /// Example: "919731093102" -> "91****3102"
  /// Example: "+919731093102" -> "+91****3102"
  static String maskPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '';
    }

    // Remove any spaces or dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleanPhone.length < 6) {
      // Too short to mask meaningfully
      return cleanPhone;
    }

    // Handle phone numbers with + prefix
    final hasPlus = cleanPhone.startsWith('+');
    final phoneWithoutPlus = hasPlus ? cleanPhone.substring(1) : cleanPhone;

    if (phoneWithoutPlus.length <= 6) {
      return cleanPhone;
    }

    // Show first 2-3 digits and last 4 digits, mask the middle
    final prefix = hasPlus ? '+' : '';
    final visibleStart = phoneWithoutPlus.substring(0, 2);
    final visibleEnd = phoneWithoutPlus.substring(phoneWithoutPlus.length - 4);
    final maskedLength = phoneWithoutPlus.length - 6;
    final masked = '*' * maskedLength;

    return '$prefix$visibleStart$masked$visibleEnd';
  }

  /// Parses setup time string to minutes
  /// Examples: "2 hrs" -> 120, "3 hours" -> 180, "30 min" -> 30
  static int parseSetupTimeToMinutes(String? setupTime) {
    if (setupTime == null || setupTime.isEmpty) {
      return 60; // Default to 1 hour if not specified
    }

    final lowerSetupTime = setupTime.toLowerCase().trim();

    // Extract numeric value
    final numericMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lowerSetupTime);
    if (numericMatch == null) {
      return 60; // Default to 1 hour
    }

    final value = double.tryParse(numericMatch.group(1) ?? '1') ?? 1;

    // Determine unit
    if (lowerSetupTime.contains('hour') || lowerSetupTime.contains('hr')) {
      return (value * 60).round();
    } else if (lowerSetupTime.contains('min')) {
      return value.round();
    } else if (lowerSetupTime.contains('day')) {
      return (value * 24 * 60).round();
    }

    // Default to hours if no unit specified
    return (value * 60).round();
  }

  /// Checks if current time is within the visibility window for customer contact
  /// Contact is visible from (booking_time - setup_time - 2 hours) onwards
  /// But hidden if: event completed, order cancelled, or (setup completed + 2 hours passed)
  static bool shouldShowFullContact({
    required DateTime bookingDate,
    String? bookingTime,
    String? setupTime,
    String? orderStatus,
  }) {
    final now = DateTime.now();

    // Hide customer number if order is completed or cancelled
    if (orderStatus?.toLowerCase() == 'completed' || orderStatus?.toLowerCase() == 'cancelled') {
      return false;
    }

    // Parse booking time (format: "15:00:00" or "15:00" or "3:00 PM")
    DateTime bookingDateTime = bookingDate;

    if (bookingTime != null && bookingTime.isNotEmpty) {
      final timeParts = _parseTimeString(bookingTime);
      if (timeParts != null) {
        bookingDateTime = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
          timeParts['hour']!,
          timeParts['minute']!,
        );
      }
    }

    // Hide customer number if event time has passed
    if (now.isAfter(bookingDateTime)) {
      return false;
    }

    // Hide customer number if setup time has expired (setup completed + 2 hours)
    final setupMinutes = parseSetupTimeToMinutes(setupTime);
    final setupEndTime = bookingDateTime.add(Duration(minutes: setupMinutes));
    final hideTime = setupEndTime.add(const Duration(hours: 2));
    if (now.isAfter(hideTime)) {
      return false;
    }

    // Get setup time in minutes
    // Calculate reveal time: booking_time - setup_time - 2 hours
    final revealTime = bookingDateTime.subtract(Duration(minutes: setupMinutes, hours: 2));

    // Check if current time is after reveal time
    return now.isAfter(revealTime);
  }

  /// Parses time string to hour and minute
  /// Supports formats: "15:00:00", "15:00", "3:00 PM", "3 PM"
  static Map<String, int>? _parseTimeString(String timeStr) {
    final cleanTime = timeStr.trim().toUpperCase();

    // Check for AM/PM format
    final isPM = cleanTime.contains('PM');
    final isAM = cleanTime.contains('AM');

    // Remove AM/PM suffix
    final timeOnly = cleanTime
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();

    // Split by colon
    final parts = timeOnly.split(':');
    if (parts.isEmpty) return null;

    int? hour = int.tryParse(parts[0].trim());
    int minute = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;

    if (hour == null) return null;

    // Convert to 24-hour format
    if (isPM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    return {'hour': hour, 'minute': minute};
  }

  /// Returns masked or full phone based on visibility window
  static String getDisplayPhone({
    required String? phone,
    required DateTime bookingDate,
    String? bookingTime,
    String? setupTime,
  }) {
    if (phone == null || phone.isEmpty) {
      return '';
    }

    final shouldShowFull = shouldShowFullContact(
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      setupTime: setupTime,
    );

    return shouldShowFull ? phone : maskPhoneNumber(phone);
  }
}
