import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../batch/presentation/batch_controller.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';

import '../../../../core/widgets/filter_sort_sheet.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  final bool isTeacher;

  const AssignmentsScreen({super.key, this.isTeacher = false});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  String _selectedBatch = 'ALL';
  String _selectedSubject = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedSort = 'due_soonest';

  int get _activeCount =>
      (_selectedBatch != 'ALL' ? 1 : 0) +
      (_selectedSubject != 'ALL' ? 1 : 0) +
      (_selectedStatus != 'ALL' ? 1 : 0) +
      (_selectedSort != 'due_soonest' ? 1 : 0);

  void _resetFilters() {
    setState(() {
      _selectedBatch = 'ALL';
      _selectedSubject = 'ALL';
      _selectedStatus = 'ALL';
      _selectedSort = 'due_soonest';
    });
  }

  Future<void> _openFilterSortSheet(List<AssignmentModel> assignments) async {
    final batches = {'ALL', ...assignments.map((a) => a.batchName).where((b) => b != null && b.isNotEmpty).cast<String>()}.toList();
    final subjects = {'ALL', ...assignments.map((a) => a.subject).where((s) => s != null && s.isNotEmpty).cast<String>()}.toList();

    final result = await showFilterSortSheet<String>(
      context: context,
      title: 'Filter & Sort Assignments',
      filters: [
        FilterConfig<String>(
          id: 'batch',
          title: 'Batch',
          options: batches.map((b) => FilterItem(value: b, label: b == 'ALL' ? 'All Batches' : b)).toList(),
          initialValue: _selectedBatch,
          defaultValue: 'ALL',
        ),
        if (subjects.length > 1)
          FilterConfig<String>(
            id: 'subject',
            title: 'Subject',
            options: subjects.map((s) => FilterItem(value: s, label: s == 'ALL' ? 'All Subjects' : s)).toList(),
            initialValue: _selectedSubject,
            defaultValue: 'ALL',
          ),
        const FilterConfig<String>(
          id: 'status',
          title: 'Submission Status',
          options: [
            FilterItem(value: 'ALL', label: 'All Statuses', icon: Icons.all_inclusive),
            FilterItem(value: 'PENDING', label: 'Pending Submission', icon: Icons.pending_actions),
            FilterItem(value: 'SUBMITTED', label: 'Submitted (Pending Review)', icon: Icons.upload_file),
            FilterItem(value: 'GRADED', label: 'Graded & Reviewed', icon: Icons.check_circle_outline),
          ],
          initialValue: 'ALL',
          defaultValue: 'ALL',
        ),
      ],
      sort: SortConfig<String>(
        title: 'Sort Order',
        options: const [
          SortOptionItem(value: 'due_soonest', label: 'Due Date: Soonest First', icon: Icons.alarm),
          SortOptionItem(value: 'due_latest', label: 'Due Date: Latest First', icon: Icons.event_available),
          SortOptionItem(value: 'marks_desc', label: 'Total Marks: Highest First', icon: Icons.grade),
        ],
        initialValue: _selectedSort,
        defaultValue: 'due_soonest',
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBatch = result.getFilter('batch', 'ALL');
        _selectedSubject = result.getFilter('subject', 'ALL');
        _selectedStatus = result.getFilter('status', 'ALL');
        _selectedSort = result.sortValue ?? 'due_soonest';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final canCreate = widget.isTeacher || currentUser?.role == 'TEACHER' || currentUser?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments & Homework', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          FilterBadgeButton(
            activeCount: _activeCount,
            tooltip: 'Filter & Sort Assignments',
            onPressed: () {
              final assignments = assignmentsAsync.valueOrNull ?? [];
              _openFilterSortSheet(assignments);
            },
          ),
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Assignment',
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
              Text('Error loading assignments: $err', style: const TextStyle(color: AppColors.slate500)),
            ],
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'No assignments yet',
              subtitle: 'Homework, DPPs, and practice sheets will appear here.',
            );
          }

          var filtered = assignments.where((item) {
            if (_selectedBatch != 'ALL' && (item.batchName ?? '') != _selectedBatch) return false;
            if (_selectedSubject != 'ALL' && (item.subject ?? '') != _selectedSubject) return false;
            if (_selectedStatus == 'PENDING' && item.isSubmitted) return false;
            if (_selectedStatus == 'SUBMITTED' && (!item.isSubmitted || item.isGraded)) return false;
            if (_selectedStatus == 'GRADED' && !item.isGraded) return false;
            return true;
          }).toList();

          if (_selectedSort == 'due_soonest') {
            filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          } else if (_selectedSort == 'due_latest') {
            filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
          } else if (_selectedSort == 'marks_desc') {
            filtered.sort((a, b) => b.maxMarks.compareTo(a.maxMarks));
          }

          return Column(
            children: [
              if (_activeCount > 0)
                ActiveFiltersBar(
                  chips: [
                    if (_selectedBatch != 'ALL')
                      ActiveFilterChipData(
                        label: 'Batch: $_selectedBatch',
                        onRemoved: () => setState(() => _selectedBatch = 'ALL'),
                      ),
                    if (_selectedSubject != 'ALL')
                      ActiveFilterChipData(
                        label: 'Subject: $_selectedSubject',
                        onRemoved: () => setState(() => _selectedSubject = 'ALL'),
                      ),
                    if (_selectedStatus != 'ALL')
                      ActiveFilterChipData(
                        label: 'Status: ${_selectedStatus == 'PENDING' ? 'Pending' : _selectedStatus == 'SUBMITTED' ? 'Submitted' : 'Graded'}',
                        onRemoved: () => setState(() => _selectedStatus = 'ALL'),
                      ),
                    if (_selectedSort != 'due_soonest')
                      ActiveFilterChipData(
                        label: _selectedSort == 'due_latest' ? 'Due latest' : 'Highest marks',
                        onRemoved: () => setState(() => _selectedSort = 'due_soonest'),
                      ),
                  ],
                  onClearAll: _resetFilters,
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.filter_list_off,
                          title: 'No matching assignments',
                          subtitle: 'No assignments match the selected filter criteria.',
                          buttonText: 'Reset Filters',
                          onAction: _resetFilters,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildAssignmentCard(context, ref, item);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, WidgetRef ref, AssignmentModel item) {
    final dueStr = DateFormat('dd MMM, hh:mm a').format(item.dueDate);

    return InkWell(
      onTap: () => _showAssignmentDetailModal(context, ref, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isGraded
                ? AppColors.success.withValues(alpha: 0.5)
                : item.isSubmitted
                    ? AppColors.skyBlue.withValues(alpha: 0.5)
                    : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
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
                      color: AppColors.skyBlueLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.subject ?? item.batchName!,
                      style: const TextStyle(color: AppColors.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text('Max Marks: ${item.maxMarks}', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                const Spacer(),
                _buildStatusBadge(item),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.slate500, fontSize: 13),
            ),
            if (item.attachmentUrl != null && item.attachmentUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 14, color: AppColors.skyBlue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.attachmentUrl!.split('/').last,
                      style: const TextStyle(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text('Due: $dueStr', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Text(
                  'Tap to view details →',
                  style: TextStyle(color: AppColors.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentDetailModal(BuildContext context, WidgetRef ref, AssignmentModel item) {
    final dueStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.dueDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject / Batch Tag & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.batchName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.subject ?? 'Subject'} • ${item.batchName!}',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  _buildStatusBadge(item),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Due Date Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text('Due Date: $dueStr', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Max Marks: ${item.maxMarks}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description / Study Notes Content
              const Text(
                'Notes & Guidelines:',
                style: TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SelectableText(
                  item.description.isNotEmpty ? item.description : 'No additional description provided.',
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 18),

              // Attached Material
              if (item.attachmentUrl != null && item.attachmentUrl!.isNotEmpty) ...[
                const Text(
                  'Attached Study File / Document:',
                  style: TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.attachmentUrl!.split('/').last,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('Attached Document', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.skyBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Open / View', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _openDocumentViewer(context, item.title, item.attachmentUrl!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Actions
              if (!widget.isTeacher && !item.isSubmitted) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Submit Assignment Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSubmitDialog(context, ref, item.id);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDocumentViewer(BuildContext context, String title, String attachmentUrl) {
    final file = File(attachmentUrl);
    final existsLocally = file.existsSync();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int totalPages = 0;
        int currentPage = 0;
        bool isReady = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (totalPages > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${currentPage + 1} / $totalPages',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF334155)),

                  // Document Content Stage
                  Expanded(
                    child: existsLocally && attachmentUrl.toLowerCase().endsWith('.pdf')
                        ? Stack(
                            children: [
                              PDFView(
                                filePath: attachmentUrl,
                                enableSwipe: true,
                                swipeHorizontal: false,
                                autoSpacing: true,
                                pageFling: true,
                                fitPolicy: FitPolicy.BOTH,
                                onRender: (pages) {
                                  setModalState(() {
                                    totalPages = pages ?? 0;
                                    isReady = true;
                                  });
                                },
                                onPageChanged: (page, total) {
                                  setModalState(() {
                                    currentPage = page ?? 0;
                                    totalPages = total ?? 0;
                                  });
                                },
                              ),
                              if (!isReady)
                                const Center(
                                  child: CircularProgressIndicator(color: AppColors.skyBlue),
                                ),
                            ],
                          )
                        : Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.menu_book_rounded, color: AppColors.skyBlue, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFF334155)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Document Reference: ${attachmentUrl.split('/').last}',
                                    style: const TextStyle(color: AppColors.skyBlue, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'This study material has been registered and verified by your faculty. You can review all formulas, notes, and concept summaries directly inside this workspace.',
                                    style: TextStyle(color: AppColors.slate200, fontSize: 14, height: 1.6),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF334155)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Verified Institute Study Resource',
                                            style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                          urlController.text = result.files.first.path ?? result.files.first.name;
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
