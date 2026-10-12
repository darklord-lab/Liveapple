import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_controller.dart';
import '../domain/teacher_model.dart';

class BulkOnboardDialog extends ConsumerStatefulWidget {
  const BulkOnboardDialog({super.key});

  @override
  ConsumerState<BulkOnboardDialog> createState() => _BulkOnboardDialogState();
}

class _BulkOnboardDialogState extends ConsumerState<BulkOnboardDialog> {
  final _csvController = TextEditingController();
  BulkOnboardReport? _report;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _insertSampleTemplate() {
    setState(() {
      _csvController.text =
          '''Name,Email,Phone
Prof. Anand Kumar,anand@apex.edu,+91 98765 11223
Dr. Homi Bhabha,homi@apex.edu,+91 98765 44556
Dr. C. V. Raman,raman@apex.edu,+91 98765 77889''';
    });
  }

  void _submit() async {
    final text = _csvController.text.trim();
    if (text.isEmpty) return;

    final report = await ref.read(adminTeachersProvider.notifier).bulkOnboard(text);
    if (report != null && mounted) {
      setState(() {
        _report = report;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTeachersProvider);
    final isSubmitting = state.isSubmitting;

    if (_report != null) {
      // Detailed Report View
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _report!.failedCount == 0 ? Icons.check_circle : Icons.info_outline,
              color: _report!.failedCount == 0 ? AppColors.success : AppColors.warning,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text('Bulk Onboarding Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Metrics bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricChip('Total', _report!.total.toString(), AppColors.textLight),
                      _metricChip('Invited', _report!.successfulCount.toString(), AppColors.success),
                      _metricChip('Failed', _report!.failedCount.toString(), AppColors.liveRed),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_report!.successful.isNotEmpty) ...[
                  const Text('✅ Successfully Invited Teachers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...(_report!.successful.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(item.email, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                                  Text('Code: ${item.inviteCode}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                              tooltip: 'Copy Code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied invite code for ${item.name}!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ))),
                ],

                if (_report!.failed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('⚠️ Skipped / Failed Rows:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.liveRed)),
                  const SizedBox(height: 8),
                  ...(_report!.failed.map((fail) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.liveRedLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.liveRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: AppColors.liveRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Row ${fail.rowNumber} (${fail.email ?? fail.name ?? 'Row'}): ${fail.reason}',
                                style: const TextStyle(fontSize: 12, color: AppColors.liveRed),
                              ),
                            ),
                          ],
                        ),
                      ))),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Bulk CSV Onboard', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton.icon(
            onPressed: _insertSampleTemplate,
            icon: const Icon(Icons.paste, size: 16),
            label: const Text('Sample Template', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste CSV data in format: Name,Email,Phone (one teacher per line)',
                style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _csvController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Prof. Anand Kumar,anand@apex.edu,+91 98765 11223\nDr. Homi Bhabha,homi@apex.edu,+91 98765 44556',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Process Bulk Onboard'),
        ),
      ],
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
      ],
    );
  }
}
