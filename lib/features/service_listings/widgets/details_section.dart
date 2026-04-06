import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/add_service_controller.dart';

class DetailsSection extends StatefulWidget {
  final AddServiceController controller;

  const DetailsSection({
    super.key,
    required this.controller,
  });

  @override
  State<DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<DetailsSection> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          _buildSectionTitle('Service Description'),
          const SizedBox(height: 8),
          const Text(
            'Provide a detailed description of your service offering.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildDescriptionSection(),

          const SizedBox(height: 24),

          // Inclusions
          _buildSectionTitle('What\'s Included'),
          const SizedBox(height: 8),
          const Text(
            'List items that are included in your service package.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInclusionsSection(),

          const SizedBox(height: 24),

          // Exclusions
          _buildSectionTitle('What\'s Excluded'),
          const SizedBox(height: 8),
          const Text(
            'List items that are NOT included in your service package.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildExclusionsSection(),

          const SizedBox(height: 24),

          // Banner Service
          _buildSectionTitle('Banner Service'),
          const SizedBox(height: 8),
          const Text(
            'Do you provide banner services for events?',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildBannerServiceSection(),

          const SizedBox(height: 24),

          // Customization
          _buildSectionTitle('Customization'),
          const SizedBox(height: 12),
          _buildCustomizationSection(),

          const SizedBox(height: 24),

          // Setup Time
          _buildSectionTitle('Setup Time'),
          const SizedBox(height: 8),
          _buildDropdownField(
            value: widget.controller.selectedSetupTime,
            items: widget.controller.setupTimeOptions,
            hint: 'How long does setup take?',
            icon: Icons.access_time_rounded,
            onChanged: (value) {
              setState(() {
                widget.controller.selectedSetupTime = value;
                // Reset booking notice when setup time changes
                // Check if current booking notice is still valid
                final newBookingOptions = _getBookingNoticeOptions();
                if (widget.controller.selectedBookingNotice != null &&
                    !newBookingOptions.contains(widget.controller.selectedBookingNotice)) {
                  widget.controller.selectedBookingNotice = null;
                }
              });
            },
          ),

          const SizedBox(height: 24),

          // Booking Notice
          _buildSectionTitle('Booking Notice'),
          const SizedBox(height: 8),
          Text(
            widget.controller.selectedSetupTime != null
                ? 'Based on ${widget.controller.selectedSetupTime} setup time, select booking notice:'
                : 'How much advance notice do you need for bookings?',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildBookingNoticeDropdown(),
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

  Widget _buildDescriptionSection() {
    return TextFormField(
      controller: widget.controller.descriptionController,
      decoration: InputDecoration(
        hintText:
            'Describe your service in detail - what makes it special, what customers can expect, etc.',
        prefixIcon: const Icon(Icons.description_outlined,
            color: AppTheme.primaryColor),
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
      maxLines: 4,
      maxLength: 500,
      validator: (_) => null, // Optional field, always valid
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildInclusionsSection() {
    return Column(
      children: [
        // Inclusion input
        TextFormField(
          controller: widget.controller.inclusionController,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'e.g., Balloons, Banner, Setup',
            prefixIcon: const Icon(Icons.add_circle_outline,
                color: AppTheme.primaryColor),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _addInclusion,
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
              borderSide: const BorderSide(
                  color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
          validator: (_) => null, // Optional input field, always valid
          onFieldSubmitted: (value) => _addInclusion(),
        ),

        const SizedBox(height: 16),

        // Inclusions list
        if (widget.controller.inclusions.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Included Items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.inclusions.map((inclusion) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      inclusion,
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
                          widget.controller.removeInclusion(inclusion);
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
          const SizedBox(height: 8),
          Text(
            '${widget.controller.inclusions.length} items included',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
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
                    'Add at least one item to continue',
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

  Widget _buildExclusionsSection() {
    return Column(
      children: [
        // Exclusion input
        TextFormField(
          controller: widget.controller.exclusionController,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'e.g., Transportation, Photography, DJ',
            prefixIcon: const Icon(Icons.remove_circle_outline,
                color: Colors.red),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _addExclusion,
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
              borderSide: const BorderSide(
                  color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
          validator: (_) => null, // Optional input field, always valid
          onFieldSubmitted: (value) => _addExclusion(),
        ),

        const SizedBox(height: 16),

        // Exclusions list
        if (widget.controller.exclusions.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Excluded Items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.exclusions.map((exclusion) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cancel,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      exclusion,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.controller.removeExclusion(exclusion);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.controller.exclusions.length} items excluded',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No exclusions added (Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
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

  Widget _buildBannerServiceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flag_rounded,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banner Service',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Include banner design and printing in your service',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.controller.providesBanner,
            onChanged: (value) {
              setState(() {
                widget.controller.providesBanner = value;
              });
            },
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customization toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Customization',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Allow customers to customize the service',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.controller.customizationAvailable,
                onChanged: (value) {
                  setState(() {
                    // widget.controller.customizationAvailable = value;
                    //Coming soon
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),

        // Customization note (if enabled)
        if (widget.controller.customizationAvailable) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controller.customizationNoteController,
            decoration: InputDecoration(
              hintText: 'Describe what can be customized (optional)',
              prefixIcon: const Icon(Icons.edit_note_rounded,
                  color: AppTheme.primaryColor),
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
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
            ),
            validator: (_) => null, // Optional field, always valid
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonFormField<String>(
        
        initialValue: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        ),
        hint: Text(hint),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an option';
          }
          return null;
        },
      ),
    );
  }

  void _addInclusion() {
    if (widget.controller.inclusionController.text.isNotEmpty) {
      setState(() {
        widget.controller.addInclusion();
      });
    }
  }

  void _addExclusion() {
    if (widget.controller.exclusionController.text.isNotEmpty) {
      setState(() {
        widget.controller.addExclusion();
      });
    }
  }

  // Get booking notice options based on selected setup time
  List<String> _getBookingNoticeOptions() {
    final setupTime = widget.controller.selectedSetupTime;
    
    switch (setupTime) {
      case '2 hours':
        return ['4 hours', '6 hours', '8 hours', '12 hours', '1 Day', '2 Days', '3 Days'];
      case '4 hours':
        return ['6 hours', '8 hours', '12 hours', '1 Day', '2 Days', '3 Days'];
      case '6 hours':
        return ['8 hours', '12 hours', '1 Day', '2 Days', '3 Days'];
      case '8 hours':
        return ['12 hours', '1 Day', '2 Days', '3 Days'];
      case '12 hours':
        return ['1 Day', '2 Days', '3 Days'];
      default:
        return widget.controller.bookingNoticeOptions; // Fallback to all options
    }
  }

  Widget _buildBookingNoticeDropdown() {
    final availableOptions = _getBookingNoticeOptions();
    final currentSelection = widget.controller.selectedBookingNotice;
    
    // Reset booking notice if current selection is not valid for new setup time
    if (currentSelection != null && !availableOptions.contains(currentSelection)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          widget.controller.selectedBookingNotice = null;
        });
      });
    }
    
    return Container(
      decoration: BoxDecoration(
        color: widget.controller.selectedSetupTime == null 
            ? AppTheme.backgroundColor.withOpacity(0.5)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.controller.selectedSetupTime == null 
              ? AppTheme.borderColor.withOpacity(0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: availableOptions.contains(currentSelection) ? currentSelection : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(
            Icons.schedule_rounded, 
            color: widget.controller.selectedSetupTime == null 
                ? AppTheme.textDisabledColor 
                : AppTheme.primaryColor,
          ),
        ),
        hint: Text(
          widget.controller.selectedSetupTime == null 
              ? 'Select setup time first'
              : 'Select booking notice period',
          style: TextStyle(
            color: widget.controller.selectedSetupTime == null 
                ? AppTheme.textDisabledColor 
                : AppTheme.textSecondaryColor,
          ),
        ),
        items: availableOptions.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          );
        }).toList(),
        onChanged: widget.controller.selectedSetupTime == null 
            ? null 
            : (value) {
                setState(() {
                  widget.controller.selectedBookingNotice = value;
                });
              },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select booking notice period';
          }
          return null;
        },
      ),
    );
  }
}
