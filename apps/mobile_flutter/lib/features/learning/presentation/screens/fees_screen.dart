import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(studentDuesProvider);

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.skyBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Fee Management & Dues',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => ref.invalidate(studentDuesProvider),
            ),
          ],
        ),
        body: duesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
          error: (err, _) => Center(
            child: Text('Error loading fee details: $err', style: const TextStyle(color: AppColors.error)),
          ),
          data: (dues) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn('Total Due', '₹${dues.totalDue.toStringAsFixed(0)}', AppColors.slate700),
                            _buildStatColumn('Total Paid', '₹${dues.totalPaid.toStringAsFixed(0)}', AppColors.success),
                            _buildStatColumn(
                              'Outstanding',
                              '₹${dues.outstandingBalance.toStringAsFixed(0)}',
                              dues.outstandingBalance > 0 ? AppColors.liveRed : AppColors.success,
                            ),
                          ],
                        ),
                        if (dues.outstandingBalance > 0) ...[
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.borderLight),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showPayFeeDialog(context, ref, dues.outstandingBalance),
                              icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                              label: const Text('Pay Dues (Demo Gateway)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.skyBlue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment History Section
                  const Text(
                    'Payment History & Receipts',
                    style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (dues.paymentHistory.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No payment records yet',
                      subtitle: 'Receipts and transaction details will appear here once payment is processed.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dues.paymentHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = dues.paymentHistory[index];
                        return _buildPaymentTile(item);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentTile(PaymentReceiptModel item) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.paidAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.receiptNo,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.paymentMethod} • $dateStr',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.amount.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.success, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showPayFeeDialog(BuildContext context, WidgetRef ref, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Payment', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
        content: Text(
          'Amount to pay: ₹${amount.toStringAsFixed(0)} via Classora Test Mode Gateway',
          style: const TextStyle(color: AppColors.textMutedLight, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await ref.read(learningRepositoryProvider).payFee(
                    amount: amount,
                    paymentMethod: 'UPI (Test)',
                  );
              ref.invalidate(studentDuesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
