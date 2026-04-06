import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/guest_access_guard.dart';
import '../models/service_listing.dart';
import '../providers/service_listing_provider.dart';

class ServiceListingsScreen extends ConsumerStatefulWidget {
  const ServiceListingsScreen({super.key});

  @override
  ConsumerState<ServiceListingsScreen> createState() =>
      _ServiceListingsScreenState();
}

class _ServiceListingsScreenState extends ConsumerState<ServiceListingsScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(serviceListingsProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceListingsAsync = ref.watch(serviceListingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'My Service Listings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(serviceListingsProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: serviceListingsAsync.when(
        data: (listings) => _buildListingsView(listings),
        loading: () => _buildLoadingView(),
        error: (error, stack) => _buildErrorView(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () async {
          // Check if user is guest - show popup if so
          final hasAccess = await GuestAccessGuard.checkAccess(
            context,
            ref,
            featureName: 'add new services',
          );
          if (hasAccess && mounted) {
            context.push('/add-service');
          }
        },
        icon: const HeroIcon(HeroIcons.plus, color: Colors.white),
        label: const Text(
          'Add Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildListingsView(List<ServiceListing> listings) {
    if (listings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(serviceListingsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return _buildListingCard(listing);
        },
      ),
    );
  }

  Widget _buildListingCard(ServiceListing listing) {
    final hasDiscount = listing.originalPrice > listing.offerPrice;
    final discountPercent = hasDiscount
        ? ((listing.originalPrice - listing.offerPrice) / listing.originalPrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _navigateToServiceDetailScreen(listing),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Cover Image
            Container(
              height: 180,
              width: double.infinity,
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              child: listing.coverPhoto != null
                  ? Image.network(
                      listing.coverPhoto!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildBannerPlaceholder(),
                    )
                  : _buildBannerPlaceholder(),
            ),

            // Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: listing.isActive
                    ? AppTheme.successColor.withValues(alpha: 0.06)
                    : AppTheme.errorColor.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: listing.isActive
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          listing.isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          listing.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Featured badge
                  if (listing.isFeatured) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Category
                  Text(
                    listing.category?.isNotEmpty == true
                        ? listing.category!
                        : 'Uncategorized',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title?.isNotEmpty == true
                        ? listing.title!
                        : 'Untitled',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₹${listing.offerPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${listing.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                            color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPercent% off',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (listing.promotionalTag?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.warningColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            listing.promotionalTag!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Tags Section
                  if (listing.themeTags.isNotEmpty || listing.serviceEnvironment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...listing.serviceEnvironment.map((env) {
                          final envString = env.toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  envString.toLowerCase() == 'indoor'
                                      ? Icons.home_rounded
                                      : Icons.park_rounded,
                                  size: 12,
                                  color: AppTheme.accentBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  envString.isNotEmpty ? envString[0].toUpperCase() + envString.substring(1) : 'Env',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        ...listing.themeTags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag.toString().isNotEmpty == true ? tag.toString() : 'Tag',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentPurple.withValues(alpha: 0.8),
                              ),
                            ),
                          );
                        }),
                        if (listing.themeTags.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${listing.themeTags.length - 3} more',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Activation / Deactivation Request Section
                  if (!listing.isActive) ...[
                    const SizedBox(height: 12),
                    _buildRequestSection(
                      isRequested: listing.activationRequested,
                      requestedAt: listing.activationRequestedAt,
                      label: 'Activation Requested',
                      buttonLabel: 'Request Activation',
                      buttonIcon: Icons.rocket_launch_rounded,
                      color: AppTheme.primaryColor,
                      onRequest: () => _requestActivation(listing),
                    ),
                  ],
                  if (listing.isActive) ...[
                    const SizedBox(height: 12),
                    _buildRequestSection(
                      isRequested: listing.deactivationRequested,
                      requestedAt: listing.deactivationRequestedAt,
                      label: 'Deactivation Requested',
                      buttonLabel: 'Request Deactivation',
                      buttonIcon: Icons.power_settings_new_rounded,
                      color: AppTheme.errorColor,
                      onRequest: () => _requestDeactivation(listing),
                    ),
                  ],

                  // Footer
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        listing.createdAt != null
                            ? 'Created ${_formatDate(listing.createdAt!)}'
                            : 'Recently created',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.4),
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

  Widget _buildRequestSection({
    required bool isRequested,
    required DateTime? requestedAt,
    required String label,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color color,
    required VoidCallback onRequest,
  }) {
    if (isRequested) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_top_rounded, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (requestedAt != null)
                    Text(
                      'Sent ${_formatDate(requestedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.warningColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onRequest,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          backgroundColor: color.withValues(alpha: 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
        icon: Icon(buttonIcon, size: 16),
        label: Text(
          buttonLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.accentBlue.withValues(alpha: 0.06),
            AppTheme.primaryColor.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No cover image',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToServiceDetailScreen(ServiceListing listing) {
    context.push('/service-listing/${listing.id}');
  }

  Future<void> _requestActivation(ServiceListing listing) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Sending activation request...'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 1),
        ),
      );

      await ref.read(serviceListingsProvider.notifier).requestActivation(listing.id);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Activation request sent to admin'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Failed to send request. Please try again.'),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _requestDeactivation(ServiceListing listing) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Sending deactivation request...'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 1),
        ),
      );

      await ref.read(serviceListingsProvider.notifier).requestDeactivation(listing.id);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Deactivation request sent to admin'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Failed to send request. Please try again.'),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset('assets/animations/service.json'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lets 😍 create first service listing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first service listing to\nstart attracting customers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Your First Service',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your service listings...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to Load Listings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorColor,
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(serviceListingsProvider.notifier).refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
