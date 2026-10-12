import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../batch/presentation/batch_controller.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';

class AssignmentsScreen extends ConsumerWidget {
  final bool isTeacher;

  const AssignmentsScreen({super.key, this.isTeacher = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final canCreate = isTeacher || currentUser?.role == 'TEACHER' || currentUser?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments & Homework', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Upload / Create Assignment',
              onPressed: () => _showCreateAssignmentDialog(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(assignmentsProvider),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.skyBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _showCreateAssignmentDialog(context, ref),
            )
          : null,
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.liveRed, size: 40),
              const SizedBox(height: 12),
              Text('Error loading assignments: $err', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.assignment_outlined, color: AppColors.slate400, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No assignments yet',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Active coursework and homework will appear here.',
                    style: TextStyle(color: AppColors.slate400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = assignments[index];
              return _buildAssignmentCard(context, ref, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, WidgetRef ref, AssignmentModel item) {
    final dueStr = DateFormat('dd MMM, hh:mm a').format(item.dueDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isGraded
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : item.isSubmitted
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                  : const Color(0xFF334155),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.batchName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.subject ?? item.batchName!,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text('Max Marks: ${item.maxMarks}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const Spacer(),
              _buildStatusBadge(item),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('Due: $dueStr', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!isTeacher && !item.isSubmitted)
                ElevatedButton.icon(
                  onPressed: () => _showSubmitDialog(context, ref, item.id),
                  icon: const Icon(Icons.upload_file, size: 14),
                  label: const Text('Submit Work', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AssignmentModel item) {
    if (item.isGraded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Graded: ${item.marksObtained}/${item.maxMarks}',
          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else if (item.isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Submitted',
          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  void _showSubmitDialog(BuildContext context, WidgetRef ref, String assignmentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Submit Assignment', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File / Document URL',
            hintText: 'https://docs.google.com/... or CDN link',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref.read(learningRepositoryProvider).submitAssignment(
                      assignmentId: assignmentId,
                      fileUrl: controller.text.trim(),
                    );
                ref.invalidate(assignmentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog(BuildContext context, WidgetRef ref) {
    final batchState = ref.read(batchListProvider);
    final batches = batchState.batches;
    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a batch first before publishing assignments.')),
      );
      return;
    }

    String selectedBatchId = batches.first.id;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController(text: 'https://classora.edu/docs/jee-assignment-01.pdf');
    final marksController = TextEditingController(text: '100');
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Create & Upload Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Cohort Batch', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedBatchId,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: batches.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text('${b.name} (${b.subject})', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedBatchId = v);
                  },
                ),
                const SizedBox(height: 12),

                const Text('Assignment Title', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Electromagnetic Induction Problem Set #2',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Instructions / Description', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Detailed guidelines, submission criteria...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('PDF / Document Resource Link', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Max Marks', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: marksController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF334155)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDueDate = picked);
                              }
                            },
                            child: Text(
                              DateFormat('dd MMM yyyy').format(selectedDueDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both title and description')),
                  );
                  return;
                }

                try {
                  await ref.read(learningRepositoryProvider).createAssignment(
                    batchId: selectedBatchId,
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    dueDate: selectedDueDate,
                    attachmentUrl: urlController.text.trim().isNotEmpty ? urlController.text.trim() : null,
                    maxMarks: int.tryParse(marksController.text.trim()) ?? 100,
                  );
                  ref.invalidate(assignmentsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment uploaded and assigned successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create assignment: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Publish Assignment'),
            ),
          ],
        ),
      ),
    );
  }
}
