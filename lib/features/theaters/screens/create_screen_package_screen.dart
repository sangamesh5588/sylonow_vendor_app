import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../addons/models/addon.dart';
import '../../addons/service/addon_service.dart';

class CreateScreenPackageScreen extends ConsumerStatefulWidget {
  final String screenId;
  final String screenName;
  final String theaterId;

  const CreateScreenPackageScreen({
    super.key,
    required this.screenId,
    required this.screenName,
    required this.theaterId,
  });

  @override
  ConsumerState<CreateScreenPackageScreen> createState() =>
      _CreateScreenPackageScreenState();
}

class _CreateScreenPackageScreenState
    extends ConsumerState<CreateScreenPackageScreen> {
  final _customPriceController = TextEditingController();

  List<Addon> _availableAddons = [];
  final List<String> _selectedAddonIds = [];
  double _totalPrice = 0.0;
  double _customPrice = 0.0;
  bool _isLoading = true;
  bool _packageExists = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddons();
    _checkExistingPackage();
    _customPriceController.addListener(_onCustomPriceChanged);
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadAddons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final addonService = ref.read(addonServiceProvider);
      final addons = await addonService.getVendorAddons();

      setState(() {
        _availableAddons = addons.where((addon) => addon.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load add-ons: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkExistingPackage() async {
    try {
      final response = await ref.read(supabaseClientProvider)
          .from('screen_packages')
          .select('id')
          .eq('screen_id', widget.screenId)
          .maybeSingle();

      setState(() {
        _packageExists = response != null;
      });
    } catch (e) {
      // If error checking existing package, assume it doesn't exist
      setState(() {
        _packageExists = false;
      });
    }
  }

  void _onAddonToggle(String addonId) {
    setState(() {
      if (_selectedAddonIds.contains(addonId)) {
        _selectedAddonIds.remove(addonId);
      } else {
        _selectedAddonIds.add(addonId);
      }
      _calculateTotalPrice();
    });
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (final addonId in _selectedAddonIds) {
      final addon = _availableAddons.firstWhere((a) => a.id == addonId);
      total += addon.price;
    }
    setState(() {
      _totalPrice = total;
      if (_customPrice == 0.0) {
        _customPrice = total;
        _customPriceController.text = total.toStringAsFixed(2);
      }
    });
  }

  void _onCustomPriceChanged() {
    final text = _customPriceController.text;
    if (text.isNotEmpty) {
      final price = double.tryParse(text) ?? 0.0;
      // Restrict price - cannot increase above total price
      if (price > _totalPrice) {
        _customPriceController.text = _totalPrice.toStringAsFixed(2);
        _customPrice = _totalPrice;
      } else {
        _customPrice = price;
      }
    }
  }

  Future<void> _createPackage() async {
    if (_selectedAddonIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one add-on'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create package data
      final packageData = {
        'screen_id': widget.screenId,
        'package_name': 'Screen ${widget.screenName} Package',
        'package_price': _customPrice > 0 ? _customPrice : _totalPrice,
        'package_description': 'Package for ${widget.screenName}',
        'package_addons': _selectedAddonIds,
      };

      // Insert package into screen_packages table
      await ref.read(supabaseClientProvider)
          .from('screen_packages')
          .insert(packageData)
          .select()
          .single();

      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        context.pop();
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create package: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Add-ons - ${widget.screenName}',
          style: const TextStyle(
            fontSize: 18,
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
      bottomNavigationBar: _packageExists ? null : _buildBottomSection(),
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
              onPressed: _loadAddons,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_packageExists) {
      return _buildPackageExistsState();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddonsSection(),
          const SizedBox(height: 100), // Space for bottom section
        ],
      ),
    );
  }

  Widget _buildPackageExistsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const HeroIcon(
                HeroIcons.gift,
                style: HeroIconStyle.outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Package Already Created',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A package has already been created for ${widget.screenName}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each screen can only have one package.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonsSection() {
    if (_availableAddons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              HeroIcon(
                HeroIcons.gift,
                style: HeroIconStyle.outline,
                size: 48,
                color: AppTheme.textSecondaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'No Add-ons Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create some add-ons first to include in packages',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Select Add-ons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _availableAddons.length,
            itemBuilder: (context, index) {
              final addon = _availableAddons[index];
              return _buildAddonItem(addon);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddonItem(Addon addon) {
    final isSelected = _selectedAddonIds.contains(addon.id);

    return GestureDetector(
      onTap: () => _onAddonToggle(addon.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  image: addon.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(addon.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: addon.imageUrl == null
                    ? const Center(
                        child: HeroIcon(
                          HeroIcons.gift,
                          style: HeroIconStyle.outline,
                          size: 24,
                          color: AppTheme.textSecondaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    addon.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${addon.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HeroIcon(
                    HeroIcons.check,
                    style: HeroIconStyle.outline,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedAddonIds.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Total Amount: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  '₹${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Package Price',
                      hintText: 'Edit package price',
                      prefixText: '₹',
                      border: const OutlineInputBorder(),
                      helperText: 'Price cannot exceed ₹${_totalPrice.toStringAsFixed(2)}',
                      helperStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAddonIds.isNotEmpty ? _createPackage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Create Package',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}