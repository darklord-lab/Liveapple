import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(studentDuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management & Dues', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentDuesProvider),
          ),
        ],
      ),
      body: duesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Text('Error loading fee details: $err', style: const TextStyle(color: Colors.white70)),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatColumn('Total Due', '₹${dues.totalDue.toStringAsFixed(0)}', const Color(0xFF94A3B8)),
                          _buildStatColumn('Total Paid', '₹${dues.totalPaid.toStringAsFixed(0)}', const Color(0xFF10B981)),
                          _buildStatColumn(
                            'Outstanding',
                            '₹${dues.outstandingBalance.toStringAsFixed(0)}',
                            dues.outstandingBalance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      if (dues.outstandingBalance > 0) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF334155)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showPayFeeDialog(context, ref, dues.outstandingBalance),
                            icon: const Icon(Icons.payment, size: 16),
                            label: const Text('Pay Dues via UPI / Card', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (dues.paymentHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No payment history recorded yet.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                    ),
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
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.receiptNo,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.paymentMethod} • $dateStr',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.amount.toStringAsFixed(0)}',
            style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showPayFeeDialog(BuildContext context, WidgetRef ref, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
        content: Text('Amount to pay: ₹${amount.toStringAsFixed(0)} via UPI/Card Gateway',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              await ref.read(learningRepositoryProvider).payFee(
                    amount: amount,
                    paymentMethod: 'UPI',
                  );
              ref.invalidate(studentDuesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}
