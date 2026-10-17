import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/test_share_model.dart';
import '../widgets/test_score_share_card.dart';

/// Screen displayed when opening the /test-result deep link or reviewing a shared score.
class TestResultScreen extends ConsumerStatefulWidget {
  final String attemptId;
  final String? code;

  const TestResultScreen({
    super.key,
    required this.attemptId,
    this.code,
  });

  @override
  ConsumerState<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends ConsumerState<TestResultScreen> {
  TestShareModel? _share;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchScoreCard();
  }

  Future<void> _fetchScoreCard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.get(Endpoints.testShare(widget.attemptId));
      final data = res.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>? ?? data;

      if (mounted) {
        setState(() {
          _share = TestShareModel.fromJson(payload);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load score card. The link may be invalid or expired.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verified Test Score'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textLight,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.skyBlue),
            SizedBox(height: 16),
            Text(
              'Loading verified score card...',
              style: TextStyle(color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

    if (_error != null || _share == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Score card not found',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchScoreCard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TestScoreShareCard(share: _share!),
        ),
      ),
    );
  }
}
