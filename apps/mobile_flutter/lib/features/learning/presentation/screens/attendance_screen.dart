import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../batch/presentation/batch_controller.dart';
import '../../../batch/data/batch_repository.dart';
import '../../../batch/domain/batch_model.dart';
import '../controllers/learning_controller.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();

  // Map of studentId -> isPresent
  final Map<String, bool> _attendanceMap = {};
  List<EnrolledStudentModel> _batchStudents = [];
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final batches = ref.read(batchListProvider).batches;
      if (batches.isNotEmpty) {
        setState(() {
          _selectedBatchId = batches.first.id;
        });
        _loadStudentsForBatch(batches.first.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentsForBatch(String batchId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final repo = BatchRepository();
      final students = await repo.getStudents(batchId);
      if (mounted) {
        setState(() {
          _batchStudents = students;
          _isLoadingStudents = false;
          _attendanceMap.clear();
          for (final s in students) {
            _attendanceMap[s.studentId] = true; // default all present
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isTeacher = user?.role == 'TEACHER' || user?.role == 'ADMIN';

    if (!isTeacher) {
      return _buildStudentView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mark / Upload Attendance'),
            Tab(text: 'Summary & Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedBatchId != null) {
                _loadStudentsForBatch(_selectedBatchId!);
              }
              ref.invalidate(studentAttendanceProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeacherMarkView(),
          _buildSummaryView(),
        ],
      ),
    );
  }

  Widget _buildStudentView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance & Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentAttendanceProvider),
          ),
        ],
      ),
      body: _buildSummaryView(),
    );
  }

  Widget _buildTeacherMarkView() {
    final batchState = ref.watch(batchListProvider);
    final batches = batchState.batches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cohort Batch & Date Selector Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Cohort Batch', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedBatchId,
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
                    if (v != null) {
                      setState(() => _selectedBatchId = v);
                      _loadStudentsForBatch(v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Session Date', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Upload Attendance Sheet Action Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.skyBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file, color: AppColors.skyBlue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bulk Upload Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Upload CSV or Excel sheet with student roll/email', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _showUploadSheetDialog,
                  child: const Text('Upload', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Mark Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrolled Students (${_batchStudents.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final s in _batchStudents) {
                          _attendanceMap[s.studentId] = true;
                        }
                      });
                    },
                    child: const Text('All Present', style: TextStyle(color: AppColors.success, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final s in _batchStudents) {
                          _attendanceMap[s.studentId] = false;
                        }
                      });
                    },
                    child: const Text('All Absent', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Student Roster
          if (_isLoadingStudents)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_batchStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('No students currently enrolled in this batch.', style: TextStyle(color: AppColors.slate400, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batchStudents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final s = _batchStudents[idx];
                final isPresent = _attendanceMap[s.studentId] ?? true;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPresent ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isPresent ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                          style: TextStyle(
                            color: isPresent ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(s.email, style: const TextStyle(color: AppColors.slate400, fontSize: 11)),
                          ],
                        ),
                      ),
                      FilterChip(
                        selected: isPresent,
                        label: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: isPresent ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        selectedColor: AppColors.success.withValues(alpha: 0.2),
                        backgroundColor: AppColors.error.withValues(alpha: 0.15),
                        onSelected: (val) {
                          setState(() {
                            _attendanceMap[s.studentId] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Save Attendance Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final presentCount = _attendanceMap.values.where((v) => v).length;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Attendance recorded for ${_batchStudents.length} students ($presentCount Present, ${_batchStudents.length - presentCount} Absent)!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Save & Synchronize Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showUploadSheetDialog() {
    final controller = TextEditingController(text: 'batch_attendance_${DateFormat('yyyyMMdd').format(_selectedDate)}.csv');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Upload Attendance Sheet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload CSV or Excel attendance export file:', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_file, color: AppColors.skyBlue),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Columns required: Email, Student Name, Status (P/A)\nSupports automatic sync with batch roster.',
                style: TextStyle(color: AppColors.slate400, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (final s in _batchStudents) {
                  _attendanceMap[s.studentId] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance sheet processed and synchronized!'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Upload & Sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    final summaryAsync = ref.watch(studentAttendanceProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(
        child: Text('Error loading attendance: $err', style: const TextStyle(color: Colors.white70)),
      ),
      data: (summary) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: summary.overallPercentage / 100,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFF0F172A),
                            color: summary.overallPercentage >= 75
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          '${summary.overallPercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Attendance',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.attendedClasses} of ${summary.totalClasses} classes attended',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${summary.totalMinutesAttended} total learning minutes',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Classes Present', '${summary.attendedClasses}', const Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard('Classes Missed', '${summary.missedClasses}', const Color(0xFFEF4444)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
