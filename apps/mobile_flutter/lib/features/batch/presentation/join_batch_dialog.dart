import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'batch_controller.dart';
import '../../../core/errors/app_exception.dart';

class JoinBatchDialog extends ConsumerStatefulWidget {
  const JoinBatchDialog({super.key});

  @override
  ConsumerState<JoinBatchDialog> createState() => _JoinBatchDialogState();
}

class _JoinBatchDialogState extends ConsumerState<JoinBatchDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 3) {
      setState(() => _errorMessage = 'Please enter a valid join code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(batchListProvider.notifier).joinBatch(code);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined batch with code "$code"!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group_add_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Join Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the 6-character batch code provided by your teacher to enroll.',
              style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. PHY782',
                hintStyle: const TextStyle(letterSpacing: 2, fontSize: 16, color: AppColors.slate400),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Join Batch', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
