import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/add_service_controller.dart';

class PricingSectionNew extends StatefulWidget {
  final AddServiceController controller;

  const PricingSectionNew({
    super.key,
    required this.controller,
  });

  @override
  State<PricingSectionNew> createState() => _PricingSectionNewState();
}

class _PricingSectionNewState extends State<PricingSectionNew> {


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Pricing Section
          _buildSectionTitle('Service Pricing'),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Original Price *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: widget.controller.originalPriceController,
                      decoration: _buildPriceInputDecoration('Enter price'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: widget.controller.validatePrice,
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offer Price *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: widget.controller.offerPriceController,
                      decoration: _buildOfferPriceInputDecoration('Discounted price'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: widget.controller.validateOfferPrice,
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price Preview
          if (widget.controller.originalPriceController.text.isNotEmpty &&
              widget.controller.offerPriceController.text.isNotEmpty)
            _buildPricePreview(),
          
          const SizedBox(height: 24),
          
          // Promotional Tag
          _buildSectionTitle('Promotional Tag (Optional)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller.promotionalTagController,
            decoration: _buildInputDecoration(
              'e.g., "Best Deal", "Top Pick", "Limited Offer"',
              HeroIcons.bookmark,
            ),
            validator: (_) => null,
            maxLength: 50,
          ),
          
          const SizedBox(height: 24),
          
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

  InputDecoration _buildInputDecoration(String hint, HeroIcons icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: HeroIcon(icon, color: AppTheme.primaryColor),
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
    );
  }

  InputDecoration _buildPriceInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixText: '₹ ',
      prefixStyle: const TextStyle(
        color: AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w500,
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
    );
  }

  InputDecoration _buildOfferPriceInputDecoration(String hint) {
    final originalPrice = double.tryParse(widget.controller.originalPriceController.text);
    final offerPrice = double.tryParse(widget.controller.offerPriceController.text);
    final isPriceInvalid = originalPrice != null && offerPrice != null && offerPrice > originalPrice;

    return InputDecoration(
      hintText: hint,
      prefixText: '₹ ',
      prefixStyle: const TextStyle(
        color: AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: isPriceInvalid
          ? const Padding(
              padding: EdgeInsets.only(right: 8),
              child: HeroIcon(
                HeroIcons.exclamationCircle,
                size: 20,
                color: Colors.red,
              ),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isPriceInvalid ? Colors.red : AppTheme.borderColor,
          width: isPriceInvalid ? 2 : 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isPriceInvalid ? Colors.red : AppTheme.borderColor,
          width: isPriceInvalid ? 2 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isPriceInvalid ? Colors.red : AppTheme.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: isPriceInvalid
          ? Colors.red.withValues(alpha: 0.05)
          : AppTheme.surfaceColor,
    );
  }

  Widget _buildPricePreview() {
    final originalPrice = double.tryParse(widget.controller.originalPriceController.text);
    final offerPrice = double.tryParse(widget.controller.offerPriceController.text);

    if (originalPrice == null || offerPrice == null) return const SizedBox();

    // Check if offer price is greater than original price
    final isPriceInvalid = offerPrice > originalPrice;
    final discount = isPriceInvalid ? 0 : ((originalPrice - offerPrice) / originalPrice * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPriceInvalid
            ? Colors.red.withValues(alpha: 0.1)
            : AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPriceInvalid
              ? Colors.red.withValues(alpha: 0.5)
              : AppTheme.primaryColor.withValues(alpha: 0.2),
          width: isPriceInvalid ? 2 : 1,
        ),
      ),
      child: isPriceInvalid ? _buildPriceErrorMessage() : _buildValidPricePreview(originalPrice, offerPrice, discount),
    );
  }

  Widget _buildPriceErrorMessage() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const HeroIcon(
            HeroIcons.exclamationTriangle,
            size: 20,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invalid Pricing',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Offer price must be less than or equal to original price',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidPricePreview(double originalPrice, double offerPrice, int discount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Preview',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (discount > 0) ...[
                    Text(
                      '₹${originalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '₹${offerPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (discount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$discount% OFF',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }



  


}