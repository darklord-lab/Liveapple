import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../controllers/learning_controller.dart';
import '../../domain/models/learning_models.dart';

class CbtTestsScreen extends ConsumerWidget {
  const CbtTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(cbtTestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests & Quizzes (CBT)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cbtTestsProvider),
          ),
        ],
      ),
      body: testsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Text('Error loading tests: $err', style: const TextStyle(color: Colors.white70)),
        ),
        data: (tests) {
          if (tests.isEmpty) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No online tests scheduled',
              subtitle: 'Computer-based timed tests and quizzes will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = tests[index];
              return _buildTestCard(context, ref, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, WidgetRef ref, CbtTestModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAttempted
              ? AppColors.success.withValues(alpha: 0.5)
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
              Text('${item.durationMin} mins • ${item.totalMarks} marks',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
              const Spacer(),
              if (item.isAttempted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Score: ${item.myScore}/${item.totalMarks}',
                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Ready to Start',
                    style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (item.description != null) ...[
            const SizedBox(height: 4),
            Text(item.description!, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.format_list_numbered, size: 14, color: AppColors.slate500),
              const SizedBox(width: 4),
              Text('${item.questionsCount} Questions', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
              const Spacer(),
              if (!item.isAttempted)
                ElevatedButton.icon(
                  onPressed: () => _startCbtQuiz(context, ref, item.id),
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Start Test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _startCbtQuiz(BuildContext context, WidgetRef ref, String testId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CbtQuizRunnerDialog(testId: testId),
    );
  }
}

class _CbtQuizRunnerDialog extends ConsumerStatefulWidget {
  final String testId;

  const _CbtQuizRunnerDialog({required this.testId});

  @override
  ConsumerState<_CbtQuizRunnerDialog> createState() => _CbtQuizRunnerDialogState();
}

class _CbtQuizRunnerDialogState extends ConsumerState<_CbtQuizRunnerDialog> {
  bool _loading = true;
  CbtTestModel? _test;
  final Map<String, String> _answers = {};
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  Future<void> _loadTest() async {
    final repo = ref.read(learningRepositoryProvider);
    await repo.startTest(widget.testId);
    final details = await repo.getTestDetails(widget.testId);
    setState(() {
      _test = details;
      _loading = false;
    });
  }

  void _submitTest() async {
    setState(() => _loading = true);
    final repo = ref.read(learningRepositoryProvider);
    final result = await repo.submitTestAnswers(testId: widget.testId, answers: _answers);
    ref.invalidate(cbtTestsProvider);

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Test Completed! 🎉', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Score: ${result['score']} / ${result['totalMarks']}',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Percentage: ${result['percentage']}%', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _test == null) {
      return const Dialog(
        backgroundColor: Color(0xFF0F172A),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF38BDF8)),
              SizedBox(height: 16),
              Text('Loading test questions...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    final questions = _test!.questions;
    if (questions.isEmpty) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('No Questions', style: TextStyle(color: Colors.white)),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back'))],
      );
    }

    final currentQ = questions[_currentQuestionIndex];
    final selectedOption = _answers[currentQ.id];

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${currentQ.marks} Marks', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              currentQ.text,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Options A-D
            _buildOptionTile('A', currentQ.optionA, selectedOption == 'A', (val) {
              setState(() => _answers[currentQ.id] = val);
            }),
            _buildOptionTile('B', currentQ.optionB, selectedOption == 'B', (val) {
              setState(() => _answers[currentQ.id] = val);
            }),
            _buildOptionTile('C', currentQ.optionC, selectedOption == 'C', (val) {
              setState(() => _answers[currentQ.id] = val);
            }),
            _buildOptionTile('D', currentQ.optionD, selectedOption == 'D', (val) {
              setState(() => _answers[currentQ.id] = val);
            }),

            const SizedBox(height: 20),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentQuestionIndex--),
                    child: const Text('Previous'),
                  ),
                const Spacer(),
                if (_currentQuestionIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => _currentQuestionIndex++),
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    onPressed: _submitTest,
                    child: const Text('Submit Test'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    String key,
    String text,
    bool isSelected,
    ValueChanged<String> onSelect,
  ) {
    return InkWell(
      onTap: () => onSelect(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  key,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
