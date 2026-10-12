import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'batch_controller.dart';
import '../domain/batch_model.dart';

class CreateBatchDialog extends ConsumerStatefulWidget {
  const CreateBatchDialog({super.key});

  @override
  ConsumerState<CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends ConsumerState<CreateBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();

  bool _isLoading = false;
  BatchModel? _createdBatch;

  final List<String> _suggestedSubjects = [
    'Physics',
    'Mathematics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'English',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final batch = await ref.read(batchListProvider.notifier).createBatch(
            name: _nameController.text.trim(),
            subject: _subjectController.text.trim(),
          );

      setState(() {
        _isLoading = false;
        _createdBatch = batch;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: _createdBatch != null ? _buildSuccessView() : _buildFormView(isDark),
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create New Batch',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a cohort to organize students, weekly timetable slots, and live classes.',
            style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
          ),
          const SizedBox(height: 20),

          // Batch Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Batch Name *',
              hintText: 'e.g. Class 12th JEE Elite',
              prefixIcon: Icon(Icons.class_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Please enter a valid batch name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Subject Field
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject *',
              hintText: 'e.g. Physics',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Please enter subject name';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Subject quick chips
          Wrap(
            spacing: 6,
            children: _suggestedSubjects.map((sub) {
              return ChoiceChip(
                label: Text(sub, style: const TextStyle(fontSize: 11)),
                selected: _subjectController.text == sub,
                onSelected: (selected) {
                  setState(() {
                    _subjectController.text = selected ? sub : '';
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Batch & Generate Code', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final batch = _createdBatch!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
        ),
        const SizedBox(height: 16),
        const Text(
          'Batch Created Successfully!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${batch.name} (${batch.subject})',
          style: const TextStyle(fontSize: 14, color: AppColors.textMutedLight),
        ),
        const SizedBox(height: 20),

        // Join Code Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'STUDENT JOIN CODE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              SelectableText(
                batch.joinCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share this 6-character code with students to self-enroll',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: batch.joinCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Join code copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Code'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(batch),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
