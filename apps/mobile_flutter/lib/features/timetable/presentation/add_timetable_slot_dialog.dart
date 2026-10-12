import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../batch/presentation/batch_controller.dart';
import '../../liveclass/presentation/live_class_controller.dart';
import 'timetable_controller.dart';
import '../../../core/errors/app_exception.dart';

class AddTimetableSlotDialog extends ConsumerStatefulWidget {
  final String? preselectedBatchId;
  final int? preselectedDay;

  const AddTimetableSlotDialog({
    super.key,
    this.preselectedBatchId,
    this.preselectedDay,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? preselectedBatchId,
    int? preselectedDay,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AddTimetableSlotDialog(
        preselectedBatchId: preselectedBatchId,
        preselectedDay: preselectedDay,
      ),
    );
  }

  @override
  ConsumerState<AddTimetableSlotDialog> createState() => _AddTimetableSlotDialogState();
}

class _AddTimetableSlotDialogState extends ConsumerState<AddTimetableSlotDialog> {
  String? _selectedBatchId;
  int _selectedDay = 1; // Monday default
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _recurring = true;

  bool _isLoading = false;
  String? _conflictError;

  final List<String> _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBatchId = widget.preselectedBatchId;
    if (widget.preselectedDay != null) {
      _selectedDay = widget.preselectedDay!;
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Default end time 1 hr later
        _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedBatchId == null) {
      setState(() => _conflictError = 'Please select a batch');
      return;
    }

    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;

    if (endMin <= startMin) {
      setState(() => _conflictError = 'End time must be strictly after start time');
      return;
    }

    if (endMin - startMin < 15) {
      setState(() => _conflictError = 'Slot duration must be at least 15 minutes');
      return;
    }

    setState(() {
      _isLoading = true;
      _conflictError = null;
    });

    try {
      await ref.read(timetableProvider.notifier).createSlot(
            batchId: _selectedBatchId!,
            dayOfWeek: _selectedDay,
            startMin: startMin,
            endMin: endMin,
            recurring: _recurring,
          );

      // Immediately refresh upcoming classes so home dashboard notify meter updates in real-time
      ref.invalidate(liveClassProvider);
      try {
        await ref.read(liveClassProvider.notifier).generateUpcoming(daysAhead: 7);
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable slot added & live schedule synced!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      setState(() {
        _isLoading = false;
        _conflictError = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesState = ref.watch(batchListProvider);
    final batches = batchesState.batches;

    if (_selectedBatchId == null && batches.isNotEmpty) {
      _selectedBatchId = batches.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
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
                  child: const Icon(Icons.alarm_add_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Timetable Slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Select Batch Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBatchId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Batch *',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              selectedItemBuilder: (context) {
                return batches.map((b) {
                  return Text(
                    '${b.name} (${b.subject})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: batches.map((b) {
                return DropdownMenuItem(
                  value: b.id,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        b.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBatchId = val),
            ),
            const SizedBox(height: 16),

            // Day of Week Dropdown
            DropdownButtonFormField<int>(
              value: _selectedDay,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Day of Week *',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: List.generate(7, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(_days[index], overflow: TextOverflow.ellipsis),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDay = val);
              },
            ),
            const SizedBox(height: 16),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      child: Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recurring Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Weekly Recurring Slot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Automatically schedule live classes every week', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
              value: _recurring,
              onChanged: (val) => setState(() => _recurring = val),
            ),

            // Conflict Error Banner
            if (_conflictError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _conflictError!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Slot', style: TextStyle(fontWeight: FontWeight.bold)),
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
