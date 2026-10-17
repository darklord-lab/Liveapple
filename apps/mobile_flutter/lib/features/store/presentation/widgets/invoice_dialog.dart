import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/store_models.dart';

class InvoiceDialog extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDialog({super.key, required this.invoice});

  static Future<void> show(BuildContext context, InvoiceModel invoice) {
    return showDialog(
      context: context,
      builder: (ctx) => InvoiceDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(invoice.purchasedAt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.skyBlueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.skyBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.instituteName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        if (invoice.instituteCode != null)
                          Text(
                            'Code: ${invoice.instituteCode}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.slate500, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Invoice No', invoice.invoiceNo, isBold: true),
                    const SizedBox(height: 6),
                    _buildInfoRow('Transaction ID', invoice.transactionId),
                    const SizedBox(height: 6),
                    _buildInfoRow('Date', dateStr),
                    const SizedBox(height: 6),
                    _buildInfoRow('Payment Method', invoice.paymentMethod),
                    const SizedBox(height: 6),
                    _buildInfoRow('Status', invoice.status, statusColor: AppColors.success),
                    const SizedBox(height: 6),
                    _buildInfoRow('Billed To', invoice.studentName),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Course Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.courseTitle,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Batch: ${invoice.batchName} (${invoice.subject})',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Price Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              _buildPriceRow('Original MRP', '₹${invoice.mrp.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _buildPriceRow('Course Fee', '₹${invoice.basePrice.toStringAsFixed(0)}'),
              if (invoice.discount > 0) ...[
                const SizedBox(height: 6),
                _buildPriceRow(
                  'Coupon Discount${invoice.couponCode != null ? " (${invoice.couponCode})" : ""}',
                  '- ₹${invoice.discount.toStringAsFixed(0)}',
                  color: AppColors.success,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppColors.borderLight, height: 1),
              ),
              _buildPriceRow(
                'Total Paid',
                '₹${invoice.netPaid.toStringAsFixed(0)}',
                isBold: true,
                fontSize: 16,
                color: AppColors.skyBlue,
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Close Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: statusColor ?? AppColors.textLight,
            ),
          ),
        ),
      ],
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
