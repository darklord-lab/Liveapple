import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/store_models.dart';
import '../controllers/store_controller.dart';

class CheckoutModalSheet extends ConsumerStatefulWidget {
  final CourseOfferingModel offering;
  final VoidCallback? onEnrollmentSuccess;

  const CheckoutModalSheet({
    super.key,
    required this.offering,
    this.onEnrollmentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required CourseOfferingModel offering,
    VoidCallback? onEnrollmentSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CheckoutModalSheet(
        offering: offering,
        onEnrollmentSuccess: onEnrollmentSuccess,
      ),
    );
  }

  @override
  ConsumerState<CheckoutModalSheet> createState() => _CheckoutModalSheetState();
}

class _CheckoutModalSheetState extends ConsumerState<CheckoutModalSheet> {
  final TextEditingController _couponController = TextEditingController();
  bool _isValidatingCoupon = false;
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  String? _couponError;
  final String _selectedPaymentMethod = 'MOCK'; // 'MOCK' | 'RAZORPAY'

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _finalAmount =>
      (widget.offering.price - _couponDiscount).clamp(0.0, double.infinity);

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final res = await ref
          .read(storeControllerProvider.notifier)
          .validateCoupon(code, widget.offering.id);

      setState(() {
        _isValidatingCoupon = false;
        _appliedCouponCode = res.code;
        _couponDiscount = res.discountAmount;
        _couponError = null;
      });
    } catch (e) {
      setState(() {
        _isValidatingCoupon = false;
        _appliedCouponCode = null;
        _couponDiscount = 0.0;
        _couponError = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _appliedCouponCode = null;
      _couponDiscount = 0.0;
      _couponError = null;
    });
  }

  Future<void> _processCheckout() async {
    try {
      final res = await ref.read(storeControllerProvider.notifier).checkoutCourse(
            widget.offering.id,
            couponCode: _appliedCouponCode,
            paymentMethod: _selectedPaymentMethod,
          );

      if (!mounted) return;
      Navigator.pop(context); // close sheet

      widget.onEnrollmentSuccess?.call();

      // Show success dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enrollment Successful!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You are now enrolled in "${widget.offering.batchName ?? widget.offering.title}". All classes, recordings, and study materials are unlocked!',
                style: const TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (res['invoiceNo'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Invoice: ${res['invoiceNo']}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Start Learning'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Close
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Course Checkout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.slate500, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 8),

              // Course Card Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.skyBlueLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: AppColors.skyBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.offering.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Batch: ${widget.offering.batchName ?? "Class"} • ${widget.offering.batchSubject ?? ""}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Coupon Code Section
              const Text(
                'Have a Coupon Code?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              if (_appliedCouponCode == null)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. SAVE20',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isValidatingCoupon ? null : _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.skyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isValidatingCoupon
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Apply'),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Coupon "$_appliedCouponCode" applied! (-₹${_couponDiscount.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.slate600),
                        onPressed: _removeCoupon,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
                ),

              if (_couponError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _couponError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],

              const SizedBox(height: 16),

              // Price Breakdown
              const Text(
                'Price Summary',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              _buildPriceRow('Original MRP', '₹${widget.offering.mrp.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              _buildPriceRow('Course Fee', '₹${widget.offering.price.toStringAsFixed(0)}'),
              if (_couponDiscount > 0) ...[
                const SizedBox(height: 4),
                _buildPriceRow(
                  'Coupon Discount',
                  '- ₹${_couponDiscount.toStringAsFixed(0)}',
                  color: AppColors.success,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppColors.borderLight, height: 1),
              ),
              _buildPriceRow(
                'Total Payable',
                '₹${_finalAmount.toStringAsFixed(0)}',
                isBold: true,
                fontSize: 16,
                color: AppColors.skyBlue,
              ),

              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isCheckingOut ? null : _processCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isCheckingOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Pay ₹${_finalAmount.toStringAsFixed(0)} & Enroll Now',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textLight : AppColors.textMutedLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
