import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/service_listing.dart';
import '../providers/service_listing_provider.dart';

class ServiceListingDetailScreen extends ConsumerStatefulWidget {
  final String serviceListingId;

  const ServiceListingDetailScreen({
    super.key,
    required this.serviceListingId,
  });

  @override
  ConsumerState<ServiceListingDetailScreen> createState() =>
      _ServiceListingDetailScreenState();
}

class _ServiceListingDetailScreenState
    extends ConsumerState<ServiceListingDetailScreen> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceListingsAsync = ref.watch(serviceListingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: serviceListingsAsync.when(
        data: (listings) {
          final serviceListing = listings.firstWhere(
            (listing) => listing.id == widget.serviceListingId,
            orElse: () => throw Exception('Service listing not found'),
          );
          return _buildContent(context, serviceListing);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.textPrimaryColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: const Text(
        'Service Details',
        style: TextStyle(
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
    );
  }

  Widget _buildContent(BuildContext context, ServiceListing listing) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlidingPhotoGallery(listing),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBasicInfo(listing),
                const SizedBox(height: 16),
                _buildPricing(listing),
                const SizedBox(height: 16),
                _buildDescription(listing),
                const SizedBox(height: 16),
                _buildInclusions(listing),
                const SizedBox(height: 16),
                _buildExclusions(listing),
                const SizedBox(height: 16),
                _buildServiceDetails(listing),
                const SizedBox(height: 16),
                _buildLocationInfo(listing),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSlidingPhotoGallery(ServiceListing listing) {
    // Combine cover photo and additional photos, avoiding duplicates
    final allPhotos = <String>[];

    // Add cover photo first if it exists and is not empty
    if (listing.coverPhoto != null && listing.coverPhoto!.isNotEmpty) {
      allPhotos.add(listing.coverPhoto!);
    }

    // Add other photos, but skip if they're already the cover photo
    for (final photo in listing.photos) {
      if (photo != listing.coverPhoto) {
        allPhotos.add(photo);
      }
    }

    if (allPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: AppTheme.textDisabledColor,
              ),
              SizedBox(height: 12),
              Text(
                'No photos available',
                style: TextStyle(
                  color: AppTheme.textDisabledColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        children: [
          // Main sliding photo display
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemCount: allPhotos.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: allPhotos[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: AppTheme.textDisabledColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Photo counter overlay
                if (allPhotos.length > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPhotoIndex + 1}/${allPhotos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                // Navigation arrows (optional)
                if (allPhotos.length > 1) ...[
                  // Left arrow
                  if (_currentPhotoIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (_currentPhotoIndex < allPhotos.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          // Mini thumbnails navigation
          if (allPhotos.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allPhotos.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentPhotoIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: allPhotos[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.backgroundColor,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppTheme.textDisabledColor,
                                size: 20,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.backgroundColor,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.textDisabledColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(ServiceListing listing) {
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
          Text(
            listing.title ?? 'Untitled Service',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          if (listing.category != null && listing.category!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              listing.category!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (listing.themeTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: listing.themeTags
                  .map(
                    (tag) => Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricing(ServiceListing listing) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                currencyFormat.format(listing.offerPrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (listing.originalPrice != listing.offerPrice) ...[
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(listing.originalPrice),
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          if (listing.promotionalTag != null &&
              listing.promotionalTag!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                listing.promotionalTag!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(ServiceListing listing) {
    if (listing.description == null || listing.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            listing.description!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusions(ServiceListing listing) {
    if (listing.inclusions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s Included',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...listing.inclusions.map(
            (inclusion) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inclusion,
                      style: const TextStyle(fontSize: 14),
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

  Widget _buildExclusions(ServiceListing listing) {
    if (listing.exclusions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s Not Included',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...listing.exclusions.map(
            (exclusion) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exclusion,
                      style: const TextStyle(fontSize: 14),
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

  Widget _buildServiceDetails(ServiceListing listing) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Setup Time', listing.setupTime),
          _buildDetailRow('Booking Notice', listing.bookingNotice),
          if (listing.customizationAvailable) ...[
            _buildDetailRow('Customization', 'Available'),
            if (listing.customizationNote != null &&
                listing.customizationNote!.isNotEmpty)
              _buildDetailRow('Customization Note', listing.customizationNote!),
          ],
          if (listing.providesBanner) _buildDetailRow('Banner', 'Provided'),
          if (listing.customAmenities.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Custom Amenities',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: listing.customAmenities
                  .map(
                    (amenity) => Chip(
                      label: Text(
                        amenity,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green[50],
                      side: BorderSide(color: Colors.green[200]!),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(ServiceListing listing) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Area',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (listing.serviceAllOverBangalore)
            _buildDetailRow('Coverage', 'All over Bangalore')
          else if (listing.pincodes.isNotEmpty)
            _buildDetailRow('Pincodes', listing.pincodes.join(', ')),
          if (listing.freeServiceKm != null)
            _buildDetailRow(
                'Free Service Range', '${listing.freeServiceKm} km'),
          if (listing.extraChargesPerKm != null)
            _buildDetailRow(
              'Extra Charges',
              '₹${listing.extraChargesPerKm}/km beyond free range',
            ),
          if (listing.venueTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Venue Types',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: listing.venueTypes
                  .map(
                    (venue) => Chip(
                      label: Text(
                        venue,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor:AppTheme.primaryColor.withOpacity(0.1),
                      side: BorderSide(color:  AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading service details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
