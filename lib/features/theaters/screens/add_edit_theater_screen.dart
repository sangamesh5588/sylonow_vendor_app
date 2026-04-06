import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';
import '../models/theater_screen.dart';
import '../providers/theater_screens_provider.dart';
import '../service/theater_management_service.dart';
import '../service/theater_media_service.dart';

class AddEditTheaterScreen extends ConsumerStatefulWidget {
  final String theaterId;
  final TheaterScreen? existingScreen;

  const AddEditTheaterScreen({
    super.key,
    required this.theaterId,
    this.existingScreen,
  });

  @override
  ConsumerState<AddEditTheaterScreen> createState() =>
      _AddEditTheaterScreenState();
}

class _AddEditTheaterScreenState extends ConsumerState<AddEditTheaterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _screenNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _totalCapacityController;
  late TextEditingController _allowedCapacityController;
  late TextEditingController _chargesExtraController;
  late TextEditingController _videoUrlController;
  late TextEditingController _whatIncludedController;

  // State variables
  List<String> _selectedAmenities = [];
  List<String> _imageUrls = [];
  String? _uploadedVideoUrl;
  bool _isLoading = false;
  bool _isUploadingMedia = false;
  int _currentPage = 0;

  // New fields for screen category and what's included
  String? _selectedCategoryId;
  final List<String> _whatIncludedList = [];

  // Custom amenity controller
  late TextEditingController _customAmenityController;

  final List<String> _availableAmenities = [
    'Air Conditioning',
    'Comfortable Seating',
    'Projector',
    'Sound System',
    'Emergency Exit',
    'Wheelchair Access',
    'Premium Seats',
    'Snack Counter',
    'WiFi',
    'Parking',
    'Gaming Setup',
    'Karaoke System'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.existingScreen == null) {
      _loadNextAvailableScreenNumber();
    }
  }

  void _initializeControllers() {
    final screen = widget.existingScreen;
    _nameController = TextEditingController(text: screen?.screenName ?? '');
    _screenNumberController = TextEditingController(
      text: screen?.screenNumber.toString() ?? '',
    );
    _descriptionController =
        TextEditingController(text: screen?.description ?? '');
    _totalCapacityController = TextEditingController(
      text: screen?.totalCapacity.toString() ?? '',
    );
    _allowedCapacityController = TextEditingController(
      text: screen?.allowedCapacity.toString() ?? '',
    );
    _chargesExtraController = TextEditingController(
      text: screen?.chargesExtraPerPerson.toString() ?? '',
    );
    _videoUrlController = TextEditingController(text: screen?.videoUrl ?? '');
    _whatIncludedController = TextEditingController();
    _customAmenityController = TextEditingController();

    _selectedAmenities = List<String>.from(screen?.amenities ?? []);
    _imageUrls = List<String>.from(screen?.images ?? []);
    _uploadedVideoUrl = screen?.videoUrl;
  }

  Future<void> _loadNextAvailableScreenNumber() async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Loading next available screen number for theater ${widget.theaterId}');
      final service = ref.read(theaterManagementServiceProvider);
      final nextNumber =
          await service.getNextAvailableScreenNumber(widget.theaterId);
// TODO: Replace with proper logging - print('🔍 DEBUG: Next available screen number: $nextNumber');

      if (mounted) {
        setState(() {
          _screenNumberController.text = nextNumber.toString();
        });
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to load next available screen number: $e');
      // Fallback to 1 if there's an error
      if (mounted) {
        setState(() {
          _screenNumberController.text = '1';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _screenNumberController.dispose();
    _descriptionController.dispose();
    _totalCapacityController.dispose();
    _allowedCapacityController.dispose();
    _chargesExtraController.dispose();
    _videoUrlController.dispose();
    _whatIncludedController.dispose();
    _customAmenityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.existingScreen == null ? 'Add Screen' : 'Edit Screen',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const HeroIcon(
            HeroIcons.arrowLeft,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveScreen,
            child: Text(
              widget.existingScreen == null ? 'Add' : 'Update',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Page indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildPageIndicator(0, 'Basic Info'),
                  _buildPageIndicator(1, 'Capacity & Pricing'),
                  _buildPageIndicator(2, 'Media & Amenities'),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildBasicInfoPage(),
                  _buildCapacityPricingPage(),
                  _buildMediaAmenitiesPage(),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const HeroIcon(HeroIcons.arrowLeft, size: 16),
                      label: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentPage < 2)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_validateCurrentPage()) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: const HeroIcon(HeroIcons.arrowRight, size: 16),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveScreen,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const HeroIcon(HeroIcons.check, size: 16),
                      label: Text(widget.existingScreen == null
                          ? 'Add Screen'
                          : 'Update Screen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int page, String title) {
    final isActive = _currentPage == page;
    final isCompleted = _currentPage > page;

    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successColor
                  : isActive
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const HeroIcon(HeroIcons.check,
                      size: 16, color: Colors.white)
                  : Text(
                      '${page + 1}',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (page < 2)
            Container(
              height: 2,
              width: 20,
              color: isCompleted ? AppTheme.primaryColor : AppTheme.borderColor,
              margin: const EdgeInsets.only(left: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Screen Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Screen Name *',
              hintText: 'e.g., Screen 1, Premium Hall',
              prefixIcon: HeroIcon(HeroIcons.tv),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a screen name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Screen Number
          TextFormField(
            controller: _screenNumberController,
            decoration: InputDecoration(
              labelText: 'Screen Number *',
              hintText: '1, 2, 3...',
              prefixIcon: const HeroIcon(HeroIcons.hashtag),
              helperText: widget.existingScreen == null
                  ? 'Auto-suggested next available number'
                  : null,
              suffixIcon: widget.existingScreen == null
                  ? IconButton(
                      icon: const HeroIcon(HeroIcons.arrowPath, size: 16),
                      onPressed: _loadNextAvailableScreenNumber,
                      tooltip: 'Refresh suggested number',
                    )
                  : null,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a screen number';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
            onChanged: (value) {
              // Clear any previous validation errors when user types
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Screen Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Screen Category *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getScreenCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.errorColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Failed to load categories'),
                      ),
                    );
                  }

                  final categories = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      hintText: 'Select screen category',
                      prefixIcon: HeroIcon(HeroIcons.tag),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'],
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(int.parse(
                                        category['color'].substring(1),
                                        radix: 16) +
                                    0xFF000000),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(category['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a screen category';
                      }
                      return null;
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'e.g., Large screen, great sound, comfortable seating',
              prefixIcon: HeroIcon(HeroIcons.documentText),
            ),
            maxLines: 3,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityPricingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capacity & Pricing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Max Allowed Capacity
          TextFormField(
            controller: _totalCapacityController,
            decoration: const InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppTheme.borderColor,
                  width: 2,
                ),
              ),
              labelText: 'Max Allowed Capacity',
              hintText: 'Maximum people allowed',
              prefixIcon: HeroIcon(HeroIcons.userGroup),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Seat Capacity
          TextFormField(
            controller: _allowedCapacityController,
            decoration: const InputDecoration(
              labelText: 'Allowed or Seat Capacity',
              hintText: 'Current seating capacity',
              prefixIcon: HeroIcon(HeroIcons.checkCircle),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Extra Charges Per Person
          TextFormField(
            controller: _chargesExtraController,
            decoration: const InputDecoration(
              labelText: 'Extra Charges Per Person',
              hintText: 'Additional charges beyond base capacity',
              prefixIcon: HeroIcon(HeroIcons.currencyRupee),
              prefixText: '₹',
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),

          // What's Included Section
          const Text(
            'What\'s Included',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items that are included with this screen booking',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // What's Included List
          if (_whatIncludedList.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _whatIncludedList
                  .map((item) => Chip(
                        label: Text(item),
                        onDeleted: () {
                          setState(() {
                            _whatIncludedList.remove(item);
                          });
                        },
                        deleteIcon: const HeroIcon(HeroIcons.xMark, size: 16),
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        deleteIconColor: AppTheme.primaryColor,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Add What's Included Item
          TextFormField(
            controller: _whatIncludedController,
            decoration: InputDecoration(
              hintText: 'e.g., Sound System, Projector, Seating',
              prefixIcon: const HeroIcon(HeroIcons.plus),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  onPressed: _addWhatIncludedItem,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const HeroIcon(
                      HeroIcons.plus,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (_) => _addWhatIncludedItem(),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaAmenitiesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media & Amenities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Video Upload
          _buildVideoUploadSection(),
          const SizedBox(height: 24),

          // Images Section
          _buildImagesUploadSection(),

          const SizedBox(height: 24),

          // Amenities
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select available amenities for your theater screen',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // Predefined Amenities
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
                selectedColor:
                    AppTheme.primaryColor.withAlpha((255 * 0.1).round()),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),

          // Custom Amenities Section
          if (_selectedAmenities
              .any((amenity) => !_availableAmenities.contains(amenity))) ...[
            const SizedBox(height: 16),
            const Text(
              'Custom Amenities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedAmenities
                  .where((amenity) => !_availableAmenities.contains(amenity))
                  .map((amenity) => FilterChip(
                        label: Text(amenity),
                        selected: true,
                        onSelected: (selected) {
                          setState(() {
                            _selectedAmenities.remove(amenity);
                          });
                        },
                        selectedColor: AppTheme.successColor
                            .withAlpha((255 * 0.1).round()),
                        checkmarkColor: AppTheme.successColor,
                        deleteIcon: const HeroIcon(HeroIcons.xMark, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedAmenities.remove(amenity);
                          });
                        },
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Add Custom Amenity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Custom Amenity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customAmenityController,
                  decoration: InputDecoration(
                    hintText: 'Enter custom amenity name',
                    prefixIcon: const HeroIcon(HeroIcons.plus),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        onPressed: _addCustomAmenity,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const HeroIcon(
                            HeroIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (_) => _addCustomAmenity(),
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add specific amenities unique to your theater that aren\'t listed above',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      // Only validate fields on the first page
      return _nameController.text.trim().isNotEmpty &&
          _screenNumberController.text.trim().isNotEmpty;
    } else if (_currentPage == 1) {
      // All pricing fields are optional now, but you could add validation here if needed.
      return true;
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> _getScreenCategories() async {
    try {
      final response = await ref
          .read(theaterManagementServiceProvider)
          .getScreenCategories();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching screen categories: $e');
      }
      return [];
    }
  }

  void _addWhatIncludedItem() {
    final item = _whatIncludedController.text.trim();

    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_whatIncludedList.contains(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is already added'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _whatIncludedList.add(item);
      _whatIncludedController.clear();
    });
  }

  void _addCustomAmenity() {
    final customAmenity = _customAmenityController.text.trim();

    if (customAmenity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amenity name'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Check if amenity already exists (case insensitive)
    final lowercaseAmenity = customAmenity.toLowerCase();
    final existsInPredefined = _availableAmenities
        .any((amenity) => amenity.toLowerCase() == lowercaseAmenity);
    final existsInSelected = _selectedAmenities
        .any((amenity) => amenity.toLowerCase() == lowercaseAmenity);

    if (existsInPredefined || existsInSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This amenity already exists'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _selectedAmenities.add(customAmenity);
      _customAmenityController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$customAmenity" to amenities'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _saveScreen() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(theaterManagementServiceProvider);
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Check for duplicate screen numbers
      final screenNumberText = _screenNumberController.text.trim();
      if (screenNumberText.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a screen number.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final screenNumber = int.tryParse(screenNumberText);
      if (screenNumber == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid screen number.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

// TODO: Replace with proper logging - print('🔍 DEBUG: Checking screen number $screenNumber for theater ${widget.theaterId}');
// TODO: Replace with proper logging - print('🔍 DEBUG: Existing screen ID: ${widget.existingScreen?.id}');

      final isExists = await service.isScreenNumberExists(
        widget.theaterId,
        screenNumber,
        excludeScreenId: widget.existingScreen?.id,
      );

// TODO: Replace with proper logging - print('🔍 DEBUG: Screen number exists: $isExists');

      if (isExists) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Screen number $screenNumber already exists for this theater. Please choose a different number.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (widget.existingScreen == null) {
        // Add new screen
        final newScreen = TheaterScreen(
          id: '', // Handled by backend
          theaterId: widget.theaterId,
          screenName: _nameController.text.trim(),
          screenNumber: int.parse(_screenNumberController.text),
          description: _descriptionController.text.trim(),
          totalCapacity: int.tryParse(_totalCapacityController.text) ?? 0,
          allowedCapacity: int.tryParse(_allowedCapacityController.text) ?? 0,
          chargesExtraPerPerson:
              double.tryParse(_chargesExtraController.text) ?? 0.0,
          videoUrl: _uploadedVideoUrl,
          images: _imageUrls,
          amenities: _selectedAmenities,
          isActive: true,
          categoryId: _selectedCategoryId,
          whatIncluded: _whatIncludedList,
        );
        await service.addTheaterScreen(newScreen);
      } else {
        // Update existing screen
        final updates = {
          'screen_name': _nameController.text.trim(),
          'screen_number': int.parse(_screenNumberController.text),
          'description': _descriptionController.text.trim(),
          'total_capacity': int.tryParse(_totalCapacityController.text) ?? 0,
          'allowed_capacity':
              int.tryParse(_allowedCapacityController.text) ?? 0,
          'charges_extra_per_person':
              double.tryParse(_chargesExtraController.text) ?? 0.0,
          'video_url': _uploadedVideoUrl,
          'images': _imageUrls,
          'amenities': _selectedAmenities,
          'category_id': _selectedCategoryId,
          'what_included': _whatIncludedList,
        };
        await service.updateTheaterScreen(widget.existingScreen!.id, updates);
      }

      // Refresh the screens list
      ref.invalidate(theaterScreensProvider(widget.theaterId));

      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.existingScreen == null
                ? 'Screen added successfully'
                : 'Screen updated successfully',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save screen: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildVideoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload a video to showcase your theater screen (max 2 minutes, 100MB)',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: _uploadedVideoUrl != null
              ? _buildVideoPreview()
              : _buildVideoUploadButton(),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppTheme.borderColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeroIcon(
                  HeroIcons.playCircle,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 8),
                Text(
                  'Video Uploaded',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Video successfully uploaded',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _removeVideo,
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoUploadButton() {
    return GestureDetector(
      onTap: _isUploadingMedia ? null : _uploadVideo,
      child: Column(
        children: [
          HeroIcon(
            HeroIcons.videoCamera,
            size: 48,
            color: _isUploadingMedia
                ? AppTheme.textSecondaryColor
                : AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            _isUploadingMedia ? 'Uploading...' : 'Upload Video',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isUploadingMedia
                  ? AppTheme.textSecondaryColor
                  : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to select and upload a video file',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          if (_isUploadingMedia) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload images to showcase your theater screen (max 6 images, 10MB each)',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildImagesGrid(),
      ],
    );
  }

  Widget _buildImagesGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: (_imageUrls.length < 6) ? _imageUrls.length + 1 : 6,
          itemBuilder: (context, index) {
            if (index < _imageUrls.length) {
              return _buildImageItem(_imageUrls[index], index);
            } else {
              return _buildAddImageButton();
            }
          },
        ),
        if (_isUploadingMedia)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Uploading images...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppTheme.borderColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.borderColor,
                  child: const HeroIcon(
                    HeroIcons.photo,
                    color: AppTheme.textSecondaryColor,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const HeroIcon(
                HeroIcons.xMark,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isUploadingMedia ? null : _uploadImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isUploadingMedia
                ? AppTheme.borderColor.withValues(alpha: 0.5)
                : AppTheme.borderColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              HeroIcons.plus,
              size: 32,
              color: _isUploadingMedia
                  ? AppTheme.textSecondaryColor
                  : AppTheme.primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: TextStyle(
                fontSize: 10,
                color: _isUploadingMedia
                    ? AppTheme.textSecondaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadVideo() async {
    if (_isUploadingMedia) return;

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final mediaService = ref.read(theaterMediaServiceProvider);
      final videoUrl = await mediaService.pickAndUploadVideo();

      if (videoUrl != null) {
        setState(() {
          _uploadedVideoUrl = videoUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<void> _removeVideo() async {
    if (_uploadedVideoUrl != null) {
      try {
        final mediaService = ref.read(theaterMediaServiceProvider);
        await mediaService.deleteMediaFile(_uploadedVideoUrl!);
        setState(() {
          _uploadedVideoUrl = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove video: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_isUploadingMedia) return;

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final mediaService = ref.read(theaterMediaServiceProvider);
      final newImages = await mediaService.pickAndUploadImages(
        maxImages: 6,
        existingImages: _imageUrls,
      );

      setState(() {
        _imageUrls = newImages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload images: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<void> _removeImage(int index) async {
    if (index >= 0 && index < _imageUrls.length) {
      try {
        final mediaService = ref.read(theaterMediaServiceProvider);
        final imageUrl = _imageUrls[index];
        await mediaService.deleteMediaFile(imageUrl);
        setState(() {
          _imageUrls.removeAt(index);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove image: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
