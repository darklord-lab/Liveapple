import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../timetable/domain/timetable_model.dart';
import '../../timetable/presentation/add_timetable_slot_dialog.dart';
import '../../timetable/presentation/timetable_controller.dart';
import '../data/batch_repository.dart';
import '../domain/batch_model.dart';
import 'batch_students_dialog.dart';
import '../../learning/presentation/screens/study_material_tab_view.dart';

class BatchDetailScreen extends ConsumerStatefulWidget {
  final BatchModel batch;

  const BatchDetailScreen({super.key, required this.batch});

  @override
  ConsumerState<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends ConsumerState<BatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BatchRepository _batchRepository = BatchRepository();

  List<EnrolledStudentModel> _students = [];
  bool _isLoadingStudents = true;
  String? _studentsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudents();
    Future.microtask(() {
      ref.read(timetableProvider.notifier).loadSlots(batchId: widget.batch.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final list = await _batchRepository.getStudents(widget.batch.id);
      if (mounted) {
        setState(() {
          _students = list;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentsError = e.toString();
          _isLoadingStudents = false;
        });
      }
    }
  }

  void _showAddStudentModal() {
    showDialog(
      context: context,
      builder: (ctx) => AddStudentDirectDialog(
        batchId: widget.batch.id,
        onSuccess: _loadStudents,
      ),
    );
  }

  void _showBulkEnrollModal() {
    showDialog(
      context: context,
      builder: (ctx) => BulkEnrollDialog(
        batchId: widget.batch.id,
        onSuccess: _loadStudents,
      ),
    );
  }

  void _showAddSlotModal() {
    showDialog(
      context: context,
      builder: (ctx) => AddTimetableSlotDialog(
        preselectedBatchId: widget.batch.id,
      ),
    );
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Batch Join QR Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 2),
                ),
                child: CustomPaint(
                  painter: _QrMatrixPainter(code: widget.batch.joinCode),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CODE: ${widget.batch.joinCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.skyBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.batch.joinCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Join code ${widget.batch.joinCode} copied!')),
                        );
                      },
                      child: const Icon(Icons.copy, size: 16, color: AppColors.skyBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Students can scan or enter this code in Classora to enroll into "${widget.batch.name}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);
    final batchSlots = timetableState.slots.where((s) => s.batchId == widget.batch.id).toList();

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
          title: Text(
            widget.batch.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_2, color: Colors.white),
              tooltip: 'QR Code',
              onPressed: _showQrDialog,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share Join Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'Join my batch ${widget.batch.name} on Classora! Use code: ${widget.batch.joinCode}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch invite message copied to clipboard!')),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Top Summary Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tileBatches.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: AppColors.tileBatches, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.batch.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Subject: ${widget.batch.subject}',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlueLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${_students.length} Enrolled',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.skyBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Join Code Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key_outlined, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 8),
                        Text(
                          'Join Code: ${widget.batch.joinCode}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.batch.joinCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Join code ${widget.batch.joinCode} copied!')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 14, color: AppColors.skyBlue),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showQrDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code, size: 14, color: AppColors.skyBlue),
                                SizedBox(width: 4),
                                Text('QR', style: TextStyle(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.skyBlue,
                indicatorWeight: 3,
                labelColor: AppColors.skyBlue,
                unselectedLabelColor: AppColors.slate500,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Students (${_students.length})'),
                  Tab(text: 'Timetable (${batchSlots.length})'),
                  const Tab(text: 'Study Material'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentsTab(),
                  _buildTimetableTab(batchSlots),
                  _buildStudyMaterialTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. STUDENTS TAB
  Widget _buildStudentsTab() {
    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddStudentModal,
                  icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                  label: const Text('+ Add Student', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showBulkEnrollModal,
                  icon: const Icon(Icons.upload_file, size: 16, color: AppColors.skyBlue),
                  label: const Text('Bulk CSV Import', style: TextStyle(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.skyBlue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: _isLoadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _studentsError != null
                  ? Center(child: Text(_studentsError!, style: const TextStyle(color: AppColors.error)))
                  : _students.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: 'No students enrolled yet',
                          subtitle: 'Share code "${widget.batch.joinCode}" or add students manually',
                          buttonText: '+ Add Student',
                          onAction: _showAddStudentModal,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _students.length,
                          itemBuilder: (context, idx) {
                            final s = _students[idx];
                            final isInvited = s.status == 'INVITED';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isInvited ? AppColors.warningLight : AppColors.skyBlueLight,
                                    child: Text(
                                      s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        color: isInvited ? AppColors.warning : AppColors.skyBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          s.email,
                                          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isInvited ? AppColors.warningLight : AppColors.successLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isInvited ? AppColors.warning : AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  // 2. TIMETABLE TAB
  Widget _buildTimetableTab(List<TimetableSlotModel> slots) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Schedule (${slots.length} slots)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
              ),
              ElevatedButton.icon(
                onPressed: _showAddSlotModal,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add Slot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: slots.isEmpty
              ? EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No timetable slots scheduled',
                  subtitle: 'Add recurring slots to broadcast live classes automatically',
                  buttonText: 'Add First Slot',
                  onAction: _showAddSlotModal,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: slots.length,
                  itemBuilder: (context, idx) {
                    final slot = slots[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.skyBlueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  slot.dayName.substring(0, 3).toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.skyBlue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  TimetableSlotModel.formatMinutes(slot.startMin),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.skyBlue),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.subject ?? widget.batch.subject,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                ),
                                Text(
                                  '${TimetableSlotModel.formatMinutes(slot.startMin)} - ${TimetableSlotModel.formatMinutes(slot.endMin)} • ${slot.durationString}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.liveRed, size: 20),
                            onPressed: () async {
                              final confirmed = await ConfirmDialog.show(
                                context,
                                title: 'Delete Timetable Slot',
                                message: 'Remove this scheduled slot from ${slot.dayName}?',
                                confirmText: 'Delete',
                                isDestructive: true,
                              );
                              if (confirmed == true) {
                                await ref.read(timetableProvider.notifier).deleteSlot(slot.id);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 3. STUDY MATERIAL TAB
  Widget _buildStudyMaterialTab() {
    return StudyMaterialTabView(
      batchId: widget.batch.id,
      isTeacher: true,
      batchName: widget.batch.name,
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String code;

  _QrMatrixPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFF0F172A);
    final paintCorner = Paint()..color = AppColors.skyBlue;

    const gridSize = 15;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    // Draw finder patterns (top-left, top-right, bottom-left)
    void drawFinder(double x, double y) {
      final rect = Rect.fromLTWH(x, y, cellWidth * 4, cellHeight * 4);
      canvas.drawRect(rect, paintCorner);
      final innerWhite = Rect.fromLTWH(x + cellWidth, y + cellHeight, cellWidth * 2, cellHeight * 2);
      canvas.drawRect(innerWhite, Paint()..color = Colors.white);
      final centerDot = Rect.fromLTWH(x + cellWidth * 1.3, y + cellHeight * 1.3, cellWidth * 1.4, cellHeight * 1.4);
      canvas.drawRect(centerDot, paintCorner);
    }

    drawFinder(cellWidth, cellHeight);
    drawFinder(size.width - cellWidth * 5, cellHeight);
    drawFinder(cellWidth, size.height - cellHeight * 5);

    // Draw pseudo-random data matrix derived from hash of the join code
    final codeHash = code.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip corner finder pattern regions
        if ((r < 5 && c < 5) || (r < 5 && c >= gridSize - 5) || (r >= gridSize - 5 && c < 5)) {
          continue;
        }
        if ((r * 7 + c * 11 + codeHash) % 3 == 0) {
          final rect = Rect.fromLTWH(c * cellWidth + 1, r * cellHeight + 1, cellWidth - 2, cellHeight - 2);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paintDark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
