import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';
import '../models/private_theater.dart';
import '../models/theater_screen.dart';
import '../providers/theater_time_slot_provider.dart';

class ScreenDetailsScreen extends ConsumerWidget {
  final TheaterScreen screen;
  final PrivateTheater theater;

  const ScreenDetailsScreen({
    super.key,
    required this.screen,
    required this.theater,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Screen Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: const HeroIcon(
            HeroIcons.arrowLeft,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScreenImage(),
            const SizedBox(height: 16),
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildDetailsSection(),
            const SizedBox(height: 20),
            _buildDescriptionSection(),
            const SizedBox(height: 20),
            _buildAmenitiesSection(),
            const SizedBox(height: 20),
            _buildInclusionsSection(),
            const SizedBox(height: 20),
            _buildTimeSlotsSection(ref),
            const SizedBox(height: 28),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenImage() {
    if (screen.images.isEmpty) {
      return _buildImageShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              HeroIcons.photo,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No Images Available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildImageShell(
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: screen.images.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: HeroIcon(
                        HeroIcons.photo,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          screen.screenName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (screen.images.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${screen.images.length} photos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (screen.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: screen.images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == 0
                          ? AppTheme.primaryColor
                          : const Color(0xFFDCE3EE),
                      width: index == 0 ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: screen.images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageShell({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EBF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: screen.isActive
                      ? AppTheme.successColor.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${screen.screenNumber}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: screen.isActive
                          ? AppTheme.successColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      screen.screenName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theater.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: screen.isActive
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  screen.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: screen.isActive
                        ? AppTheme.successColor
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: HeroIcons.users,
                  label: 'Capacity',
                  value: '${screen.allowedCapacity}/${screen.totalCapacity}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  icon: HeroIcons.currencyRupee,
                  label: 'Extra/Person',
                  value: '₹${screen.chargesExtraPerPerson.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required HeroIcons icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      child: Row(
        children: [
          HeroIcon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
            style: HeroIconStyle.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: HeroIcons.informationCircle,
            title: 'Screen Information',
            iconColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: HeroIcons.userGroup,
            label: 'Allowed Capacity',
            value: '${screen.allowedCapacity} persons',
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            icon: HeroIcons.users,
            label: 'Total Capacity',
            value: '${screen.totalCapacity} persons',
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            icon: HeroIcons.buildingOffice2,
            label: 'Theater',
            value: theater.name,
            color: AppTheme.accentTeal,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            icon: HeroIcons.mapPin,
            label: 'Location',
            value: '${theater.city}, ${theater.state}',
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    if (screen.description == null || screen.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: HeroIcons.documentText,
            title: 'Description',
            iconColor: AppTheme.accentBlue,
          ),
          const SizedBox(height: 14),
          Text(
            screen.description!,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    if (screen.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: HeroIcons.sparkles,
            title: 'Amenities',
            iconColor: AppTheme.accentTeal,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: screen.amenities.map((amenity) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentTeal.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeroIcon(
                      HeroIcons.checkCircle,
                      size: 16,
                      color: AppTheme.accentTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentTeal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsSection() {
    if (screen.whatIncluded.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: HeroIcons.clipboardDocumentCheck,
            title: 'What\'s Included',
            iconColor: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          ...screen.whatIncluded.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: HeroIcon(
                      HeroIcons.checkCircle,
                      size: 20,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
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
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required HeroIcons icon,
    required String title,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HeroIcon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required HeroIcons icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final iconColor = color ?? AppTheme.accentTeal;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: HeroIcon(
            icon,
            style: HeroIconStyle.outline,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection(WidgetRef ref) {
    final timeSlotsAsync = ref.watch(screenTimeSlotsProvider(screen.id));

    return timeSlotsAsync.when(
      data: (timeSlots) {
        if (timeSlots.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Time Slots Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click below to add time slots for this screen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        final activeSlots = timeSlots.where((slot) => slot.isActive).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const HeroIcon(
                      HeroIcons.clock,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Available Time Slots',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activeSlots.length} Active',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...timeSlots.take(5).map((slot) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: slot.isActive
                          ? AppTheme.accentBlue.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: slot.isActive
                            ? AppTheme.accentBlue.withValues(alpha: 0.2)
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  HeroIcon(
                                    HeroIcons.clock,
                                    size: 16,
                                    color: slot.isActive
                                        ? AppTheme.accentBlue
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${slot.startTime} - ${slot.endTime}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: slot.isActive
                                          ? AppTheme.textPrimaryColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (slot.basePrice > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '₹${slot.basePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    if (slot.pricePerHour > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${slot.pricePerHour.toStringAsFixed(0)}/hr',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: slot.isActive
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slot.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: slot.isActive
                                  ? AppTheme.successColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (timeSlots.length > 5) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '+${timeSlots.length - 5} more time slots',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load time slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push(
            '/time-slots/${screen.id}?screenName=${Uri.encodeComponent(screen.screenName)}&theaterId=${theater.id}',
          );
        },
        icon: const HeroIcon(
          HeroIcons.clock,
          style: HeroIconStyle.outline,
          size: 20,
          color: Colors.white,
        ),
        label: const Text(
          'Manage Time Slots',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.95),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      );
}
