import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

class DoubtsView extends StatefulWidget {
  final List<DoubtItem> initialDoubts;
  final UserSession currentUser;
  final VoidCallback onClose;

  const DoubtsView({
    super.key,
    required this.initialDoubts,
    required this.currentUser,
    required this.onClose,
  });

  @override
  State<DoubtsView> createState() => _DoubtsViewState();
}

class _DoubtsViewState extends State<DoubtsView> {
  late List<DoubtItem> _doubts;
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _doubts = List.from(widget.initialDoubts);
  }

  void _submitDoubt() {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;

    final newDoubt = DoubtItem(
      id: 'dbt-${DateTime.now().millisecondsSinceEpoch}',
      studentName: widget.currentUser.name,
      studentId: widget.currentUser.id,
      question: text,
      timestamp: 'Just now',
      isResolved: false,
    );

    setState(() {
      _doubts.insert(0, newDoubt);
      _questionController.clear();
    });
  }

  void _toggleResolve(String id) {
    setState(() {
      final idx = _doubts.indexWhere((d) => d.id == id);
      if (idx != -1) {
        _doubts[idx] = _doubts[idx].copyWith(
          isResolved: !_doubts[idx].isResolved,
        );
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.currentUser.role == 'teacher';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onClose();
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            widget.onClose();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.slate900,
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.slate850,
                    border: Border(bottom: BorderSide(color: AppColors.slate700)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        onPressed: widget.onClose,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Doubt Resolution Queue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Priority faculty Q&A channel during lecture',
                              style: TextStyle(
                                color: AppColors.slate400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ask a doubt input (for students or quick add)
                Container(
                  padding: const EdgeInsets.all(14),
                  color: AppColors.slate800,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Type your physics question or concept doubt...',
                            hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.slate850,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.slate700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.slate700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.indigo500),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _submitDoubt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigo600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Ask', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),

                // Doubts List
                Expanded(
                  child: _doubts.isEmpty
                      ? const Center(
                          child: Text('No active doubts right now', style: TextStyle(color: AppColors.slate400)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _doubts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final dbt = _doubts[index];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.slate800,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: dbt.isResolved
                                      ? AppColors.emerald500.withOpacity(0.3)
                                      : AppColors.slate700,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: AppColors.indigo600,
                                            child: Text(
                                              dbt.studentName.isNotEmpty ? dbt.studentName[0] : 'S',
                                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            dbt.studentName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            dbt.timestamp,
                                            style: const TextStyle(color: AppColors.slate400, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: dbt.isResolved
                                              ? AppColors.emerald900.withOpacity(0.5)
                                              : AppColors.amber900.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: dbt.isResolved ? AppColors.emerald500 : AppColors.amber500,
                                          ),
                                        ),
                                        child: Text(
                                          dbt.isResolved ? 'RESOLVED' : 'PENDING REVIEW',
                                          style: TextStyle(
                                            color: dbt.isResolved ? AppColors.emerald300 : AppColors.amber300,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    dbt.question,
                                    style: const TextStyle(
                                      color: AppColors.slate100,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (isTeacher) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _toggleResolve(dbt.id),
                                        icon: Icon(
                                          dbt.isResolved ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: dbt.isResolved ? AppColors.slate400 : AppColors.emerald400,
                                        ),
                                        label: Text(
                                          dbt.isResolved ? 'Re-open Doubt' : 'Mark as Answered',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: dbt.isResolved ? AppColors.slate400 : AppColors.emerald400,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: dbt.isResolved ? AppColors.slate600 : AppColors.emerald600,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
