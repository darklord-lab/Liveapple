import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../batch/presentation/batch_controller.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(recordingsProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final canUpload = currentUser?.role == 'TEACHER' || currentUser?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorded Lectures', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (canUpload)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Upload / Add Recording',
              onPressed: () => _showUploadRecordingDialog(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(recordingsProvider),
          ),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.skyBlue,
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: const Text('Upload Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _showUploadRecordingDialog(context, ref),
            )
          : null,
      body: recordingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.liveRed, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load recordings: $err', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(recordingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (recordings) {
          if (recordings.isEmpty) {
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
                    child: const Icon(Icons.video_library_outlined, color: AppColors.slate400, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recordings yet',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Completed live classes with recordings will appear here.',
                    style: TextStyle(color: AppColors.slate400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recordings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = recordings[index];
              return _buildRecordingCard(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordingCard(BuildContext context, RecordingModel item) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Preview Box
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8), size: 32),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.batchName != null) ...[
                  Row(
                    children: [
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
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.batchName!}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(item.durationFormatted, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadRecordingDialog(BuildContext context, WidgetRef ref) {
    final batchState = ref.read(batchListProvider);
    final batches = batchState.batches;
    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a batch first before uploading recordings.')),
      );
      return;
    }

    String selectedBatchId = batches.first.id;
    final titleController = TextEditingController();
    final urlController = TextEditingController(text: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    final durationController = TextEditingController(text: '45');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Upload / Add Class Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

                const Text('Lecture Title', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Electromagnetic Induction - Session 1',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Video Stream URL (MP4 / WebM / Cloud Link)', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
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

                const Text('Duration (Minutes)', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
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
                if (titleController.text.trim().isEmpty || urlController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both title and video URL')),
                  );
                  return;
                }

                final durationMin = int.tryParse(durationController.text.trim()) ?? 45;
                try {
                  await ref.read(learningRepositoryProvider).saveRecording(
                    liveClassId: selectedBatchId,
                    videoUrl: urlController.text.trim(),
                    title: titleController.text.trim(),
                    durationSec: durationMin * 60,
                    fileSizeMb: 125.0,
                  );
                  ref.invalidate(recordingsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class recording published to batch students!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save recording: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Upload Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
