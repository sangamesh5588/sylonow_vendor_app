import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:sylonow_vendor/core/theme/app_theme.dart';

import '../controllers/add_service_controller.dart';
import '../widgets/area_section.dart';
import '../widgets/basic_info_section.dart';
import '../widgets/details_section.dart';
import '../widgets/media_upload_section.dart';
import '../widgets/pricing_section_new.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _stepTitles = [
    'Basic Info',
    'Media Upload',
    'Pricing',
    'Details',
    'Area',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _setStatusBarColor();
  }

  void _setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(addServiceControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Step Indicator
                _buildStepIndicator(),

                // Content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BasicInfoSection(controller: controller),
                      MediaUploadSection(controller: controller),
                      PricingSectionNew(controller: controller),
                      DetailsSection(controller: controller),
                      AreaSection(controller: controller),
                    ],
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      floating: true,
      pinned: false,
      snap: true,
      centerTitle: true,
      leading: IconButton(
        icon: HeroIcon(HeroIcons.arrowLeft,
            size: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
        onPressed: () => _showExitDialog(),
      ),
      title: Text(
        'Add Service',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
      actions: [
        IconButton(
          icon: const HeroIcon(HeroIcons.questionMarkCircle,
              size: 20, color: AppTheme.primaryColor),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step Progress Bar
          Row(
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? AppTheme.primaryColor
                              : AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < _stepTitles.length - 1)
                      Container(
                        width: 6,
                        height: 3,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Step Title
          Text(
            _stepTitles[_currentStep],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Step ${_currentStep + 1} of ${_stepTitles.length}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AddServiceController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next/Submit Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _nextStep(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : Text(
                      _currentStep == _stepTitles.length - 1
                          ? 'Create Service'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _tabController.animateTo(_currentStep);
    }
  }

  void _nextStep(AddServiceController controller) async {
    if (_currentStep < _stepTitles.length - 1) {
      // Validate current step before proceeding
      if (_validateCurrentStep(controller)) {
        setState(() {
          _currentStep++;
        });
        _tabController.animateTo(_currentStep);
      }
    } else {
      // Submit form
      await _submitForm(controller);
    }
  }

  bool _validateCurrentStep(AddServiceController controller) {
    final missingFields = <String>[];

    switch (_currentStep) {
      case 0: // Basic Info
        if (controller.titleController.text.isEmpty) {
          missingFields.add('Service Title');
        } else {
          final titleError = controller.validateTitle(controller.titleController.text);
          if (titleError != null) {
            _showValidationErrorDialog('Title Error', titleError);
            return false;
          }
        }

        if (controller.selectedCategory == null) {
          missingFields.add('Category');
        }

        if (controller.selectedServiceEnvironments.isEmpty) {
          missingFields.add('Service Environment (Indoor/Outdoor)');
        }

        if (missingFields.isNotEmpty) {
          _showMissingFieldsDialog('Basic Info', missingFields);
          return false;
        }
        return true;

      case 1: // Media Upload
        if (controller.photos.isEmpty) {
          _showValidationErrorDialog(
            'Photos Required',
            'Please upload at least one photo of your service. Photos help customers understand what you offer.',
          );
          return false;
        }
        return true;

      case 2: // Pricing
        if (controller.originalPriceController.text.isEmpty) {
          missingFields.add('Original Price');
        } else {
          final priceError = controller.validatePrice(controller.originalPriceController.text);
          if (priceError != null) {
            _showValidationErrorDialog('Original Price Error', priceError);
            return false;
          }
        }

        if (controller.offerPriceController.text.isEmpty) {
          missingFields.add('Offer Price');
        } else {
          final offerPriceError = controller.validateOfferPrice(controller.offerPriceController.text);
          if (offerPriceError != null) {
            _showValidationErrorDialog('Offer Price Error', offerPriceError);
            return false;
          }
        }

        if (missingFields.isNotEmpty) {
          _showMissingFieldsDialog('Pricing', missingFields);
          return false;
        }

        if (!_validatePricing(controller)) {
          _showValidationErrorDialog(
            'Pricing Error',
            'Offer price cannot be greater than original price. Please adjust your pricing.',
          );
          return false;
        }
        return true;

      case 3: // Details
        if (controller.selectedSetupTime == null) {
          missingFields.add('Setup Time');
        }

        if (controller.selectedBookingNotice == null) {
          missingFields.add('Booking Notice Period');
        }

        if (controller.inclusions.isEmpty) {
          missingFields.add('Inclusions (Add at least one inclusion)');
        }

        if (missingFields.isNotEmpty) {
          _showMissingFieldsDialog('Details', missingFields);
          return false;
        }
        return true;

      case 4: // Area
        if (controller.pincodes.isEmpty && !controller.serviceAllOverBangalore) {
          _showValidationErrorDialog(
            'Service Area Required',
            'Please add at least one pincode or select "Service All Over Bangalore" to specify where you provide services.',
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  bool _validatePricing(AddServiceController controller) {
    final originalPrice =
        double.tryParse(controller.originalPriceController.text);
    final offerPrice = double.tryParse(controller.offerPriceController.text);

    if (originalPrice == null || offerPrice == null) return false;
    return offerPrice <= originalPrice;
  }

  Future<void> _submitForm(AddServiceController controller) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate all steps before submission
      final missingItems = <String, List<String>>{};

      // Check Basic Info (Step 0)
      final basicInfoIssues = <String>[];
      if (controller.titleController.text.isEmpty) {
        basicInfoIssues.add('Service Title');
      }
      if (controller.selectedCategory == null) {
        basicInfoIssues.add('Category');
      }
      if (controller.selectedServiceEnvironments.isEmpty) {
        basicInfoIssues.add('Service Environment');
      }
      if (basicInfoIssues.isNotEmpty) {
        missingItems['Basic Info (Step 1)'] = basicInfoIssues;
      }

      // Check Media Upload (Step 1)
      final mediaIssues = <String>[];
      if (controller.photos.isEmpty) {
        mediaIssues.add('At least one Photo');
      }
      if (mediaIssues.isNotEmpty) {
        missingItems['Media Upload (Step 2)'] = mediaIssues;
      }

      // Check Pricing (Step 2)
      final pricingIssues = <String>[];
      if (controller.originalPriceController.text.isEmpty) {
        pricingIssues.add('Original Price');
      }
      if (controller.offerPriceController.text.isEmpty) {
        pricingIssues.add('Offer Price');
      } else if (controller.validateOfferPrice(controller.offerPriceController.text) != null) {
        pricingIssues.add('Valid Offer Price (must be ≤ Original Price)');
      }
      if (pricingIssues.isNotEmpty) {
        missingItems['Pricing (Step 3)'] = pricingIssues;
      }

      // Check Details (Step 3)
      final detailsIssues = <String>[];
      if (controller.selectedSetupTime == null) {
        detailsIssues.add('Setup Time');
      }
      if (controller.selectedBookingNotice == null) {
        detailsIssues.add('Booking Notice');
      }
      if (controller.inclusions.isEmpty) {
        detailsIssues.add('At least one Inclusion');
      }
      if (detailsIssues.isNotEmpty) {
        missingItems['Details (Step 4)'] = detailsIssues;
      }

      // Check Area (Step 4)
      final areaIssues = <String>[];
      if (controller.pincodes.isEmpty && !controller.serviceAllOverBangalore) {
        areaIssues.add('Service Area (Pincodes or All Bangalore)');
      }
      if (areaIssues.isNotEmpty) {
        missingItems['Area (Step 5)'] = areaIssues;
      }

      // If there are any missing items, show comprehensive error
      if (missingItems.isNotEmpty) {
        _showComprehensiveValidationDialog(missingItems);
        return;
      }

      // All validation passed, create the listing
      final success = await controller.createListing();

      if (success) {
        // Reset/clear all form fields after successful creation
        controller.resetForm();
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to create service listing. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while creating the service: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Exit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to exit? All unsaved changes will be lost.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text(
              'Exit',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Help',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Follow these steps to create your service listing:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Basic Info: Add title, category, and theme tags',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 4),
              Text(
                '2. Media Upload: Add at least 1 photo (required)',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 4),
              Text(
                '3. Pricing: Set original and offer prices',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 4),
              Text(
                '4. Details: Add inclusions, setup time, etc.',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 4),
              Text(
                '5. Area: Specify service pincodes and venues',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
    
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const HeroIcon(
                HeroIcons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Service Created!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your service listing has been created successfully and is now live.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pushReplacement('/service-listings');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Listings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Error',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMissingFieldsDialog(String stepName, List<String> missingFields) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HeroIcon(
                HeroIcons.exclamationTriangle,
                size: 24,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Incomplete $stepName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please fill in the following required fields:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            ...missingFields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HeroIcon(
                HeroIcons.xCircle,
                size: 24,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComprehensiveValidationDialog(Map<String, List<String>> missingItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HeroIcon(
                HeroIcons.clipboardDocumentList,
                size: 24,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Incomplete Form',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please complete all required fields before submitting:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              ...missingItems.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...entry.value.map((field) => Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                field,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
