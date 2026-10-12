import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/batch_model.dart';
import '../data/batch_repository.dart';

class BatchStudentsDialog extends ConsumerStatefulWidget {
  final BatchModel batch;

  const BatchStudentsDialog({super.key, required this.batch});

  @override
  ConsumerState<BatchStudentsDialog> createState() => _BatchStudentsDialogState();
}

class _BatchStudentsDialogState extends ConsumerState<BatchStudentsDialog> {
  final BatchRepository _repository = BatchRepository();
  List<EnrolledStudentModel> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getStudents(widget.batch.id);
      if (mounted) {
        setState(() {
          _students = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showAddStudentModal() {
    showDialog(
      context: context,
      builder: (ctx) => _AddStudentDirectDialog(
        batchId: widget.batch.id,
        onSuccess: () => _loadStudents(),
      ),
    );
  }

  void _showBulkEnrollModal() {
    showDialog(
      context: context,
      builder: (ctx) => _BulkEnrollDialog(
        batchId: widget.batch.id,
        onSuccess: () => _loadStudents(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                            child: const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${widget.batch.name} • Students',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join Code: ${widget.batch.joinCode}  •  ${_students.length} Enrolled',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddStudentModal,
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('+ Add Student'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _showBulkEnrollModal,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Bulk CSV Import'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                      : _students.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.school_outlined, size: 48, color: AppColors.slate400),
                                  const SizedBox(height: 12),
                                  const Text('No students enrolled yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Share join code "${widget.batch.joinCode}" or add students manually',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final isInvited = student.status == 'INVITED';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : AppColors.slate50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isInvited ? AppColors.warningLight : AppColors.primaryLight,
                                        child: Text(
                                          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                                          style: TextStyle(
                                            color: isInvited ? AppColors.warning : AppColors.primary,
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
                                              student.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              student.email,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
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
                                          student.status,
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
        ),
      ),
    );
  }
}

class _AddStudentDirectDialog extends StatefulWidget {
  final String batchId;
  final VoidCallback onSuccess;

  const _AddStudentDirectDialog({required this.batchId, required this.onSuccess});

  @override
  State<_AddStudentDirectDialog> createState() => _AddStudentDirectDialogState();
}

class _AddStudentDirectDialogState extends State<_AddStudentDirectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = BatchRepository();
      final res = await repo.addStudent(
        batchId: widget.batchId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _result = res;
      });
      widget.onSuccess();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      final inviteCode = _result!['inviteCode'] as String?;
      final inviteUrl = _result!['inviteUrl'] as String?;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              const Text('Student Enrolled!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (inviteCode != null) ...[
                const Text(
                  'A new account was created. Share this activation code:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inviteCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteUrl ?? inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Activation link copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ] else
                const Text(
                  'Existing student has been enrolled into this batch.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Student to Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Student Name *', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.trim().length < 2 ? 'Enter student name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Student'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkEnrollDialog extends StatefulWidget {
  final String batchId;
  final VoidCallback onSuccess;

  const _BulkEnrollDialog({required this.batchId, required this.onSuccess});

  @override
  State<_BulkEnrollDialog> createState() => _BulkEnrollDialogState();
}

class _BulkEnrollDialogState extends State<_BulkEnrollDialog> {
  final _csvController = TextEditingController();
  bool _isLoading = false;
  BulkEnrollResultModel? _report;

  @override
  void initState() {
    super.initState();
    _csvController.text = 'Name, Email, Phone\nAarav Sharma, aarav@apex.edu, +919876543201\nDiya Patel, diya@apex.edu, +919876543202';
  }

  Future<void> _submit() async {
    if (_csvController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = BatchRepository();
      final report = await repo.bulkEnroll(
        batchId: widget.batchId,
        csvText: _csvController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _report = report;
      });
      widget.onSuccess();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
        child: _report != null ? _buildReportView() : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bulk Enroll Students (CSV)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Paste student details in CSV format: Name, Email, Phone',
          style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TextField(
            controller: _csvController,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Name, Email, Phone\nStudent Name, student@example.com, +91...',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Process Import'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportView() {
    final report = _report!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Import Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatChip('Total', report.total.toString(), AppColors.slate700),
            _buildStatChip('Enrolled', report.enrolled.toString(), AppColors.success),
            _buildStatChip('Already Enrolled', report.alreadyEnrolled.toString(), AppColors.info),
            _buildStatChip('Failed', report.failed.toString(), AppColors.error),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: report.rows.length,
            itemBuilder: (context, i) {
              final row = report.rows[i];
              final isSuccess = row.status == 'ENROLLED' || row.status == 'INVITED';

              return ListTile(
                dense: true,
                title: Text(row.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(row.email, style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSuccess ? AppColors.successLight : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    row.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
      ],
    );
  }
}
