import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/providers/vendor_provider.dart';
import '../models/private_theater.dart';
import '../models/theater_screen.dart';
import '../providers/vendor_theaters_provider.dart';
import '../service/theater_management_service.dart';
import 'add_edit_theater_screen.dart';
import 'screen_details_screen.dart';

class VendorScreensOverviewScreen extends ConsumerStatefulWidget {
  const VendorScreensOverviewScreen({super.key});

  @override
  ConsumerState<VendorScreensOverviewScreen> createState() =>
      _VendorScreensOverviewScreenState();
}

class _VendorScreensOverviewScreenState
    extends ConsumerState<VendorScreensOverviewScreen> {
  List<PrivateTheater> _vendorTheaters = [];
  Map<String, List<TheaterScreen>> _theaterScreens = {};
  bool _isLoading = true;
  String? _error;
  final Set<String> _togglingScreenIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllScreens();
  }

  Future<void> _loadAllScreens() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final vendor = await ref.read(vendorProvider.future);
      if (vendor?.authUserId == null) {
        setState(() {
          _error = 'Vendor information not found';
          _isLoading = false;
        });
        return;
      }

      // Get all theaters for vendor (force refresh to avoid stale cached data)
      ref.invalidate(vendorTheatersProvider);
      final theaters = await ref.read(vendorTheatersProvider.future);
      final service = ref.read(theaterManagementServiceProvider);

      // Load screens for each theater
      Map<String, List<TheaterScreen>> allScreens = {};
      for (final theater in theaters) {
        final screens = await service.getTheaterScreens(theater.id);
        allScreens[theater.id] = screens;
      }

      setState(() {
        _vendorTheaters = theaters;
        _theaterScreens = allScreens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load screens: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int get _totalScreenCount {
    return _theaterScreens.values
        .fold(0, (sum, screens) => sum + screens.length);
  }

  int get _activeScreenCount {
    return _theaterScreens.values.fold(
        0, (sum, screens) => sum + screens.where((s) => s.isActive).length);
  }

  int get _inactiveScreenCount => _totalScreenCount - _activeScreenCount;

  bool _isPendingTheaterStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'pending' ||
        normalized == 'pending_approval' ||
        normalized == 'under_review';
  }

  PrivateTheater? _getPendingTheater(List<PrivateTheater> theaters) {
    for (final theater in theaters) {
      if (_isPendingTheaterStatus(theater.approvalStatus)) {
        return theater;
      }
    }
    return null;
  }

  Future<void> _toggleScreenStatus(
      TheaterScreen screen, String theaterId) async {
    // Block toggle if not approved yet
    if (screen.activationStatus != 'approved') return;

    final newStatus = !screen.isActive;
    final action = newStatus ? 'activate' : 'deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: newStatus
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HeroIcon(
                newStatus ? HeroIcons.checkCircle : HeroIcons.pauseCircle,
                size: 20,
                color: newStatus ? AppTheme.successColor : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${newStatus ? 'Activate' : 'Deactivate'} Screen',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          newStatus
              ? 'Activating "${screen.screenName}" will make it visible to customers for booking. Continue?'
              : 'Deactivating "${screen.screenName}" will hide it from customers and prevent new bookings. Continue?',
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textSecondaryColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? AppTheme.successColor : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _togglingScreenIds.add(screen.id));

    try {
      final service = ref.read(theaterManagementServiceProvider);
      final updatedScreen =
          await service.toggleScreenStatus(screen.id, newStatus);

      setState(() {
        final screens = _theaterScreens[theaterId]!;
        final idx = screens.indexWhere((s) => s.id == screen.id);
        if (idx != -1) screens[idx] = updatedScreen;
        _togglingScreenIds.remove(screen.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                HeroIcon(
                  newStatus ? HeroIcons.checkCircle : HeroIcons.pauseCircle,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${screen.screenName}" ${newStatus ? 'activated' : 'deactivated'} successfully',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus ? AppTheme.successColor : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      setState(() => _togglingScreenIds.remove(screen.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action screen. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  Future<void> _reRequestApproval(TheaterScreen screen) async {
    setState(() => _togglingScreenIds.add(screen.id));
    try {
      final service = ref.read(theaterManagementServiceProvider);
      final updatedScreen = await service.requestActivationApproval(screen.id);

      // Find which theater this screen belongs to and update
      for (final theaterId in _theaterScreens.keys) {
        final screens = _theaterScreens[theaterId]!;
        final idx = screens.indexWhere((s) => s.id == screen.id);
        if (idx != -1) {
          setState(() {
            screens[idx] = updatedScreen;
            _togglingScreenIds.remove(screen.id);
          });
          break;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Re-submitted for approval. Admin will review shortly.'),
            backgroundColor: Colors.amber.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      setState(() => _togglingScreenIds.remove(screen.id));
    }
  }

  void _showEditInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            HeroIcon(
              HeroIcons.informationCircle,
              style: HeroIconStyle.outline,
              size: 22,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              'Editing Info',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'If you are editing a screen, please first deactivate the screen and then make edits.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditScreenTap(
      TheaterScreen screen, PrivateTheater theater) async {
    if (screen.isActive) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              HeroIcon(
                HeroIcons.pencilSquare,
                style: HeroIconStyle.outline,
                size: 22,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'Edit Screen',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Please deactivate this screen first, then edit price/images/details.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('info'),
              child: const Text('i'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('deactivate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (action == 'info') {
        _showEditInfoDialog();
      } else if (action == 'deactivate') {
        await _toggleScreenStatus(screen, theater.id);
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditTheaterScreen(
          theaterId: theater.id,
          existingScreen: screen,
        ),
      ),
    );

    if (mounted) {
      await _loadAllScreens();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPendingTheater = _getPendingTheater(_vendorTheaters) != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Screens',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const HeroIcon(
            HeroIcons.arrowLeft,
            style: HeroIconStyle.outline,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: hasPendingTheater
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final navigator = GoRouter.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final pendingTheater = _getPendingTheater(_vendorTheaters);
                if (pendingTheater != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Your theater "${pendingTheater.name}" is under review.',
                      ),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                  return;
                }

                if (_vendorTheaters.isNotEmpty) {
                  await navigator
                      .push('/add-screen/${_vendorTheaters.first.id}');
                  if (mounted) {
                    await _loadAllScreens();
                  }
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please add a theater first'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              backgroundColor: AppTheme.primaryColor,
              child: const HeroIcon(
                HeroIcons.plus,
                style: HeroIconStyle.outline,
                color: Colors.white,
                size: 24,
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HeroIcon(
              HeroIcons.exclamationTriangle,
              style: HeroIconStyle.outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllScreens,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_totalScreenCount == 0) {
      return RefreshIndicator(
        onRefresh: _loadAllScreens,
        color: AppTheme.primaryColor,
        child: _buildEmptyState(_vendorTheaters),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllScreens,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Summary card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSummaryCard(),
            ),
          ),
          // Screens list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildSingleScreenSections(_vendorTheaters),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSingleScreenSections(List<PrivateTheater> theaters) {
    final sections = <Widget>[];
    for (final entry in _theaterScreens.entries) {
      final theaterId = entry.key;
      final screens = entry.value;
      if (screens.isEmpty) continue;

      final theater = theaters.firstWhere(
        (t) => t.id == theaterId,
        orElse: () => PrivateTheater(
          id: theaterId,
          name: 'Unknown Theater',
          address: '',
          city: '',
          state: '',
          pinCode: '',
          description: '',
          amenities: const [],
          images: const [],
          isActive: true,
        ),
      );

      for (final screen in screens) {
        sections.add(_buildScreenSection(theater, screen));
      }
    }
    return sections;
  }

  Widget _buildEmptyState(List<PrivateTheater> theaters) {
    final pendingTheater = _getPendingTheater(theaters);
    final hasTheater = theaters.isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeroIcon(
                  pendingTheater != null
                      ? HeroIcons.clock
                      : HeroIcons.buildingOffice2,
                  style: HeroIconStyle.outline,
                  size: 64,
                  color: pendingTheater != null
                      ? AppTheme.warningColor
                      : AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  pendingTheater != null
                      ? 'Theater Under Review'
                      : 'No Screens Yet',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pendingTheater != null
                      ? 'Your theater "${pendingTheater.name}" is under review. Please wait until your theater is approved. You cannot add another theater now.'
                      : hasTheater
                          ? 'Add screens to your existing theater to get started'
                          : 'Add your first theater and configure screens to get started',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                if (pendingTheater != null)
                  ElevatedButton.icon(
                    onPressed: () => context.push('/vendor-theaters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const HeroIcon(
                      HeroIcons.buildingOffice2,
                      style: HeroIconStyle.outline,
                      size: 20,
                    ),
                    label: const Text('View My Theater'),
                  )
                else if (hasTheater)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/add-screen/${theaters.first.id}');
                      if (mounted) {
                        await _loadAllScreens();
                      }
                    },
                    icon: const HeroIcon(
                      HeroIcons.plus,
                      style: HeroIconStyle.outline,
                      size: 20,
                    ),
                    label: const Text('Add Screen'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/simple-add-theater');
                      if (mounted) {
                        await _loadAllScreens();
                      }
                    },
                    icon: const HeroIcon(
                      HeroIcons.plus,
                      style: HeroIconStyle.outline,
                      size: 20,
                    ),
                    label: const Text('Add Theater'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HeroIcon(
                  HeroIcons.squares2x2,
                  style: HeroIconStyle.outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Screens',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_totalScreenCount',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Across ${_theaterScreens.length} ${_theaterScreens.length == 1 ? 'Theater' : 'Theaters'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusPill(
                icon: HeroIcons.checkCircle,
                label: 'Active',
                count: _activeScreenCount,
                color: Colors.greenAccent.shade400,
              ),
              const SizedBox(width: 12),
              _buildStatusPill(
                icon: HeroIcons.pauseCircle,
                label: 'Inactive',
                count: _inactiveScreenCount,
                color: Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required HeroIcons icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenSection(PrivateTheater theater, TheaterScreen screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HeroIcon(
                    HeroIcons.buildingOffice2,
                    style: HeroIconStyle.outline,
                    color: AppTheme.accentTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theater.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Screen #${screen.screenNumber} • ${screen.screenName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildScreenItem(screen, theater),
        ],
      ),
    );
  }

  Widget _buildScreenItem(TheaterScreen screen, PrivateTheater theater) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: screen.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: screen.images.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, url, error) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HeroIcon(
                              HeroIcons.photo,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HeroIcon(
                            HeroIcons.photo,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              // Screen Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${screen.screenNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: screen.isActive
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            screen.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: screen.isActive
                                  ? AppTheme.successColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      screen.screenName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Capacity ${screen.allowedCapacity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
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
          const SizedBox(height: 12),
          // Activate / Deactivate toggle row
          _buildToggleRow(screen, theater),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                        '/time-slots/${screen.id}?screenName=${Uri.encodeComponent(screen.screenName)}&theaterId=${theater.id}');
                  },
                  icon: const HeroIcon(
                    HeroIcons.clock,
                    style: HeroIconStyle.outline,
                    size: 16,
                  ),
                  label: const Text('Manage Slots'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleEditScreenTap(screen, theater),
                  icon: const HeroIcon(
                    HeroIcons.pencilSquare,
                    style: HeroIconStyle.outline,
                    size: 16,
                  ),
                  label: const Text('Edit Screen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) {
                  if (value == 'details') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScreenDetailsScreen(
                          screen: screen,
                          theater: theater,
                        ),
                      ),
                    );
                  } else if (value == 'info') {
                    _showEditInfoDialog();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'details',
                    child: Row(
                      children: [
                        HeroIcon(
                          HeroIcons.eye,
                          style: HeroIconStyle.outline,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'info',
                    child: Row(
                      children: [
                        HeroIcon(
                          HeroIcons.informationCircle,
                          style: HeroIconStyle.outline,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        SizedBox(width: 8),
                        Text('Editing Info'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(
                        HeroIcons.ellipsisHorizontal,
                        style: HeroIconStyle.outline,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildToggleRow(TheaterScreen screen, PrivateTheater theater) {
    final isToggling = _togglingScreenIds.contains(screen.id);
    final status = screen.activationStatus;

    // ── STATE 1: not_requested — show "Request Activation" button ──────────
    if (status == 'not_requested') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isToggling ? null : () => _reRequestApproval(screen),
          icon: isToggling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const HeroIcon(
                  HeroIcons.paperAirplane,
                  style: HeroIconStyle.outline,
                  size: 16,
                  color: Colors.white,
                ),
          label: Text(
            isToggling ? 'Submitting...' : 'Request Activation',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    // ── STATE 2: pending_approval — waiting for admin review ────────────────
    if (status == 'pending_approval') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const HeroIcon(
                HeroIcons.clock,
                size: 16,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Under Review',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Activation request sent · Awaiting admin approval',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── STATE 3: rejected — show rejection notice + Re-submit button ────────
    if (status == 'rejected') {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppTheme.errorColor.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const HeroIcon(
                HeroIcons.xCircle,
                size: 16,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Rejected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Update screen details and re-submit',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isToggling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.errorColor,
                    ),
                  )
                : TextButton(
                    onPressed: () => _reRequestApproval(screen),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                            color: AppTheme.errorColor, width: 1),
                      ),
                    ),
                    child: const Text(
                      'Re-submit',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
      );
    }

    // ── STATE 4: approved — show active/inactive toggle ─────────────────────
    final isActive = screen.isActive;
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.successColor.withValues(alpha: 0.06)
            : Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppTheme.successColor.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          HeroIcon(
            isActive ? HeroIcons.checkCircle : HeroIcons.pauseCircle,
            size: 18,
            color: isActive ? AppTheme.successColor : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Screen is Active' : 'Screen is Inactive',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.successColor : Colors.orange,
                  ),
                ),
                Text(
                  isActive
                      ? 'Visible to customers for booking'
                      : 'Hidden from customers',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isToggling
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isActive ? AppTheme.successColor : Colors.orange,
                  ),
                )
              : GestureDetector(
                  onTap: () => _toggleScreenStatus(screen, theater.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.successColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          left: isActive ? 24 : 2,
                          top: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
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
}
