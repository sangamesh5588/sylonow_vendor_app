import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/add_service_controller.dart';
import '../providers/venue_provider.dart';

class AreaSection extends ConsumerStatefulWidget {
  final AddServiceController controller;

  const AreaSection({
    super.key,
    required this.controller,
  });

  @override
  ConsumerState<AreaSection> createState() => _AreaSectionState();
}

class _AreaSectionState extends ConsumerState<AreaSection> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Coverage Toggle
          _buildServiceCoverageToggle(),
          
          const SizedBox(height: 24),
          
          // Pincodes Section (only show when not servicing all over Bangalore)
          if (!widget.controller.serviceAllOverBangalore) ...[
            _buildSectionTitle('Service Areas'),
            const SizedBox(height: 8),
            const Text(
              'Add pincodes where you provide services (max 20).',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildPincodesSection(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Service coverage: All over Bangalore',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Venue Types Section
          _buildSectionTitle('Venue Types'),
          const SizedBox(height: 8),
          const Text(
            'Select the types of venues where you can provide services.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildVenueTypesSection(),
          
          const SizedBox(height: 24),
          
          // Service Charges Section
          _buildSectionTitle('Service Charges'),
          const SizedBox(height: 8),
          const Text(
            'Set delivery/travel charges for your service area.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildServiceChargesSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildServiceCoverageToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.controller.serviceAllOverBangalore
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_city_rounded,
            color: widget.controller.serviceAllOverBangalore
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service All Over Bangalore',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.controller.serviceAllOverBangalore
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.controller.serviceAllOverBangalore
                      ? 'You provide service across entire Bangalore'
                      : 'Enable to provide service city-wide',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.controller.serviceAllOverBangalore
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.controller.serviceAllOverBangalore,
            onChanged: (value) {
              setState(() {
                widget.controller.serviceAllOverBangalore = value;
                if (value) {
                  // If enabled, clear specific pincodes as they're not needed
                  widget.controller.pincodes.clear();
                }
              });
            },
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPincodesSection() {
    return Column(
      children: [
        // Pincode input
        TextFormField(
          controller: widget.controller.pincodeController,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit pincode',
            prefixIcon: const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.controller.pincodes.length < 20
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: widget.controller.pincodes.length < 20 ? _addPincode : null,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
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
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (_) => null,
          onFieldSubmitted: (value) => _addPincode(),
        ),
        
        const SizedBox(height: 16),
        
        // Pincodes list
        if (widget.controller.pincodes.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Added Pincodes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                '${widget.controller.pincodes.length}/20',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.pincodes.map((pincode) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pincode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.controller.removePincode(pincode);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add at least one pincode to continue',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVenueTypesSection() {
    final venuesAsync = ref.watch(venuesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select applicable venue types:',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        venuesAsync.when(
          data: (venues) {
            if (venues.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No venue types available',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: venues.map((venue) {
                final isSelected = widget.controller.selectedVenueTypes.contains(venue.name);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.controller.toggleVenueType(venue.name);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getVenueIcon(venue.iconName),
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          venue.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load venue types',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    ref.invalidate(venuesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${widget.controller.selectedVenueTypes.length} venue types selected',
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),

        // Service area summary
        if (widget.controller.pincodes.isNotEmpty &&
            widget.controller.selectedVenueTypes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildServiceAreaSummary(),
        ],
      ],
    );
  }

  Widget _buildServiceAreaSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'Service Area Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.controller.pincodes.length} pincodes',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.business,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.controller.selectedVenueTypes.length} venue types',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getVenueIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'home':
      case 'home_rounded':
        return Icons.home_rounded;
      case 'apartment':
      case 'apartment_rounded':
        return Icons.apartment_rounded;
      case 'restaurant':
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'local_cafe':
      case 'local_cafe_rounded':
        return Icons.local_cafe_rounded;
      case 'roofing':
      case 'roofing_rounded':
        return Icons.roofing_rounded;
      case 'local_florist':
      case 'local_florist_rounded':
        return Icons.local_florist_rounded;
      case 'meeting_room':
      case 'meeting_room_rounded':
        return Icons.meeting_room_rounded;
      case 'hotel':
      case 'hotel_rounded':
        return Icons.hotel_rounded;
      case 'business':
      case 'business_rounded':
        return Icons.business_rounded;
      case 'landscape':
      case 'landscape_rounded':
        return Icons.landscape_rounded;
      case 'cottage':
      case 'cottage_rounded':
        return Icons.cottage_rounded;
      case 'beach_access':
      case 'beach_access_rounded':
        return Icons.beach_access_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Widget _buildServiceChargesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Free Service KM
        const Text(
          'Free Service Distance (KM):',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller.freeServiceKmController,
          decoration: InputDecoration(
            hintText: 'e.g., 10',
            prefixIcon: const Icon(Icons.directions_car_rounded, color: AppTheme.primaryColor),
            suffixText: 'KM',
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
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: widget.controller.validateFreeServiceKm,
          onChanged: (value) => setState(() {}), // Refresh summary on change
        ),
        const SizedBox(height: 8),
        const Text(
          'Distance within which you provide free service (Optional)',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),

        const SizedBox(height: 20),

        // Extra Charges Per KM
        const Text(
          'Extra Charges Per KM:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller.extraChargesPerKmController,
          decoration: InputDecoration(
            hintText: 'e.g., 15',
            prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primaryColor),
            suffixText: 'per KM',
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
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: widget.controller.validateExtraChargesPerKm,
          onChanged: (value) => setState(() {}), // Refresh summary on change
        ),
        const SizedBox(height: 8),
        const Text(
          'Charge per kilometer beyond free service distance (Optional)',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),

        // Service charges summary
        if (widget.controller.freeServiceKmController.text.isNotEmpty || 
            widget.controller.extraChargesPerKmController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildServiceChargesSummary(),
        ],
      ],
    );
  }

  Widget _buildServiceChargesSummary() {
    final freeKm = double.tryParse(widget.controller.freeServiceKmController.text);
    final extraCharge = double.tryParse(widget.controller.extraChargesPerKmController.text);
    
    if (freeKm == null && extraCharge == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                'Service Charges Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (freeKm != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  'Free service up to ${freeKm.toStringAsFixed(freeKm.truncateToDouble() == freeKm ? 0 : 1)} KM',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
          if (extraCharge != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.currency_rupee,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  '₹${extraCharge.toStringAsFixed(extraCharge.truncateToDouble() == extraCharge ? 0 : 1)} per KM beyond free distance',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _addPincode() {
    if (widget.controller.pincodeController.text.length == 6) {
      final isValid = widget.controller.validatePincode(widget.controller.pincodeController.text) == null;
      if (isValid) {
        setState(() {
          widget.controller.addPincode();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 6-digit pincode'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pincode must be 6 digits'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
} 