import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final Order order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scaleController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToHome();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.successColor.withOpacity(0.1),
                AppTheme.backgroundColor,
                AppTheme.backgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.successColor.withOpacity(0.2),
                            AppTheme.successColor.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _scaleController,
                          builder: (context, child) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Success Content
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Success Title
                        const Text(
                          '🎉 Order Completed!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Success Message
                        Text(
                          'Congratulations! You have successfully completed the order for ${widget.order.serviceTitle}.',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Order Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Order ID
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Order ID',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  Text(
                                    '#${widget.order.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Amount
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Amount Earned',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final orderValuesAsync = ref.watch(
                                          orderValuesProvider(widget.order));
                                      return orderValuesAsync.when(
                                        data: (orderValues) => Text(
                                          '₹${orderValues['totalOrderValue']!.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.successColor,
                                          ),
                                        ),
                                        loading: () => const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.successColor,
                                          ),
                                        ),
                                        error: (_, __) => Text(
                                          '₹${widget.order.totalAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.successColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Completion Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: AppTheme.successColor,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Order Completed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Action Buttons
                        Column(
                          children: [
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _navigateToHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.home_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Back to Home',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // View Orders Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _navigateToOrders,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accentBlue,
                                  side: const BorderSide(color: AppTheme.accentBlue),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.list_alt_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'View All Orders',
                                      style: TextStyle(
                                        fontSize: 16,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome() {
    context.go('/home');
  }

  void _navigateToOrders() {
    context.go('/orders');
  }
}