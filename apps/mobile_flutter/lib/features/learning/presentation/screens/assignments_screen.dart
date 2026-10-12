import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
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
        title: const Text('Assignments & Study Materials', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Upload / Create Assignment or Notes',
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
              label: const Text('Upload Notes / Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    bool isStudyNotes = false;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    final marksController = TextEditingController(text: '100');
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));
    String? pickedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              Icon(isStudyNotes ? Icons.menu_book_rounded : Icons.assignment_outlined, color: AppColors.skyBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                isStudyNotes ? 'Upload Study Material / Notes' : 'Create & Upload Assignment',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector: Assignment vs Notes/Material
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => isStudyNotes = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isStudyNotes ? AppColors.skyBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Assignment / HW',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !isStudyNotes ? Colors.white : AppColors.slate400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => isStudyNotes = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isStudyNotes ? AppColors.skyBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Notes & Materials',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isStudyNotes ? Colors.white : AppColors.slate400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

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

                Text(isStudyNotes ? 'Title / Chapter Name' : 'Assignment Title', style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isStudyNotes ? 'e.g., Electromagnetic Induction Chapter Notes' : 'e.g., Problem Set #2',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                Text(isStudyNotes ? 'Notes / Description (Text is sufficient)' : 'Instructions / Description', style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: isStudyNotes ? 'Key formulas, chapter summary, important tips...' : 'Detailed guidelines, submission criteria...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // File Attachment Section (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isStudyNotes ? 'Attach PDF / Doc (Optional)' : 'Attach Resource File (Optional)',
                      style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                    ),
                    const Text('Not Mandatory', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),

                // Device File Picker CTA
                InkWell(
                  onTap: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'jpg', 'png'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() {
                          pickedFileName = result.files.first.name;
                          urlController.text = result.files.first.name;
                        });
                      }
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pickedFileName != null ? AppColors.skyBlue : const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        Icon(pickedFileName != null ? Icons.check_circle : Icons.folder_open, color: pickedFileName != null ? Colors.greenAccent : AppColors.skyBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pickedFileName ?? 'Choose File From Device Storage',
                            style: TextStyle(
                              color: pickedFileName != null ? Colors.white : AppColors.slate400,
                              fontSize: 12,
                              fontWeight: pickedFileName != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pickedFileName != null)
                          GestureDetector(
                            onTap: () => setDialogState(() {
                              pickedFileName = null;
                              urlController.clear();
                            }),
                            child: const Icon(Icons.close, color: AppColors.slate400, size: 18),
                          )
                        else
                          const Icon(Icons.arrow_forward_ios, color: AppColors.slate500, size: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Web Link Input as secondary alternative
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Or Web / Drive Link (Optional)',
                    hintText: 'https://...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 14),

                if (!isStudyNotes) ...[
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
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                final chosenAttachment = pickedFileName ?? (urlController.text.trim().isNotEmpty ? urlController.text.trim() : null);

                try {
                  await ref.read(learningRepositoryProvider).createAssignment(
                    batchId: selectedBatchId,
                    title: isStudyNotes
                        ? '[Notes] ${titleController.text.trim()}'
                        : titleController.text.trim(),
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : (isStudyNotes ? 'Chapter Study Material' : 'Assignment details'),
                    dueDate: isStudyNotes ? DateTime.now().add(const Duration(days: 365)) : selectedDueDate,
                    attachmentUrl: chosenAttachment,
                    maxMarks: isStudyNotes ? 0 : (int.tryParse(marksController.text.trim()) ?? 100),
                  );
                  ref.invalidate(assignmentsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isStudyNotes ? 'Study Material & Notes published successfully!' : 'Assignment published successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to publish: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text(isStudyNotes ? 'Publish Notes / Material' : 'Publish Assignment'),
            ),
          ],
        ),
      ),
    );
  }
}
