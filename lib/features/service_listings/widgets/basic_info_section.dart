import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/add_service_controller.dart';

class BasicInfoSection extends StatefulWidget {
  final AddServiceController controller;

  const BasicInfoSection({
    super.key,
    required this.controller,
  });

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await widget.controller.loadCategories();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check form key state during build
    if (kDebugMode) {
      print(
          '🔧 BasicInfoSection: Building with form key - ${widget.controller.formKey}');
      print(
          '🔧 BasicInfoSection: Form state exists - ${widget.controller.formKey.currentState != null}');
    }

    return Form(
      key: widget.controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Input
            _buildSectionTitle('Service Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.controller.titleController,
              decoration: _buildInputDecoration(
                'e.g., "Birthday Decor for Kids"',
                Icons.title_rounded,
              ),
              validator: widget.controller.validateTitle,
              maxLength: 100,
            ),

            const SizedBox(height: 24),

            // Category Selection
            _buildSectionTitle('Category'),
            const SizedBox(height: 8),
            _buildCategorySelection(),

            const SizedBox(height: 24),

            // Service Environment
            _buildSectionTitle('Service Environment'),
            const SizedBox(height: 8),
            _buildServiceEnvironmentSelection(),

            const SizedBox(height: 24),

            // Theme Tags
            _buildSectionTitle('Theme Tags'),
            const SizedBox(height: 8),
            _buildThemeTagsSelection(),
          ],
        ),
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

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textSecondaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: AppTheme.surfaceColor,
    );
  }

  Widget _buildCategorySelection() {
    if (widget.controller.isCategoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: widget.controller.selectedCategory,
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const HeroIcon(HeroIcons.cog, color: AppTheme.primaryColor),
      ),
      hint: const Text('Select a category'),
      items: widget.controller.categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          widget.controller.selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildServiceEnvironmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where can your service be provided?',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: widget.controller.selectedServiceEnvironments.isNotEmpty
              ? widget.controller.selectedServiceEnvironments.first
              : null,
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: const Icon(Icons.location_on_rounded,
                color: AppTheme.primaryColor),
          ),
          hint: const Text('Select service environment'),
          items: const [
            DropdownMenuItem<String>(
              value: 'indoor',
              child: Row(
                children: [
                  HeroIcon(HeroIcons.home,
                      size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Indoor'),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'outdoor',
              child: Row(
                children: [
                  HeroIcon(HeroIcons.buildingOffice,
                      size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Outdoor'),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'both',
              child: Row(
                children: [
                  Icon(Icons.home_work_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Indoor & Outdoor'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              widget.controller.selectedServiceEnvironments.clear();
              if (value != null) {
                if (value == 'both') {
                  widget.controller.selectedServiceEnvironments
                      .addAll(['indoor', 'outdoor']);
                } else {
                  widget.controller.selectedServiceEnvironments.add(value);
                }
              }
            });
          },
          validator: (value) {
            if (widget.controller.selectedServiceEnvironments.isEmpty) {
              return 'Please select a service environment';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          widget.controller.selectedServiceEnvironments.isEmpty
              ? 'No environment selected'
              : widget.controller.selectedServiceEnvironments.length == 2
                  ? 'Indoor & Outdoor service available'
                  : '${widget.controller.selectedServiceEnvironments.first.toUpperCase()} service available',
          style: TextStyle(
            fontSize: 12,
            color: widget.controller.selectedServiceEnvironments.isEmpty
                ? AppTheme.errorColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTagsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select tags that best describe your service theme:',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.controller.themeTags.map((tag) {
            final isSelected =
                widget.controller.selectedThemeTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  widget.controller.toggleThemeTag(tag);
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            );
          }).toList()
            ..add(
              // Add Custom Amenity Button
              GestureDetector(
                onTap: _showAddCustomAmenityDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Add More',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
        const SizedBox(height: 12),
        // Display custom amenities
        if (widget.controller.customAmenities.isNotEmpty) ...[
          const Text(
            'Custom Amenities:',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.customAmenities.map((amenity) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amenity,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.controller.removeCustomAmenity(amenity);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          '${widget.controller.selectedThemeTags.length} tags selected${widget.controller.customAmenities.isNotEmpty ? ' • ${widget.controller.customAmenities.length} custom amenities' : ''}',
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  void _showAddCustomAmenityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Add Custom Amenity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a custom amenity or service feature that best describes your offering:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.controller.customAmenityController,
              decoration: _buildInputDecoration(
                'e.g., "24/7 Support", "Free Setup"',
                Icons.star_outline,
              ),
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            if (widget.controller.customAmenities.length >= 10)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Maximum 10 custom amenities allowed',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: widget.controller.customAmenities.length >= 10
                ? null
                : () {
                    final amenity =
                        widget.controller.customAmenityController.text.trim();
                    if (amenity.isNotEmpty) {
                      setState(() {
                        widget.controller.addCustomAmenity();
                      });
                      Navigator.of(context).pop();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
