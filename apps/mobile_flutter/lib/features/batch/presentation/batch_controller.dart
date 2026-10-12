import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/batch_repository.dart';
import '../domain/batch_model.dart';
import '../../../core/errors/app_exception.dart';

class BatchState {
  final List<BatchModel> batches;
  final bool isLoading;
  final String? errorMessage;
  final String? searchQuery;

  BatchState({
    this.batches = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery,
  });

  BatchState copyWith({
    List<BatchModel>? batches,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return BatchState(
      batches: batches ?? this.batches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BatchNotifier extends StateNotifier<BatchState> {
  final BatchRepository _repository;

  BatchNotifier({BatchRepository? repository})
      : _repository = repository ?? BatchRepository(),
        super(BatchState()) {
    loadBatches();
  }

  Future<void> loadBatches({String? search, String? teacherId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getBatches(search: search, teacherId: teacherId);
      state = state.copyWith(batches: list, isLoading: false, searchQuery: search);
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<BatchModel> createBatch({required String name, required String subject}) async {
    final batch = await _repository.createBatch(name: name, subject: subject);
    state = state.copyWith(batches: [batch, ...state.batches]);
    return batch;
  }

  Future<void> deleteBatch(String batchId) async {
    await _repository.deleteBatch(batchId);
    state = state.copyWith(
      batches: state.batches.where((b) => b.id != batchId).toList(),
    );
  }

  Future<BatchModel> regenerateCode(String batchId) async {
    final updated = await _repository.regenerateCode(batchId);
    state = state.copyWith(
      batches: state.batches.map((b) => b.id == batchId ? updated : b).toList(),
    );
    return updated;
  }

  Future<void> joinBatch(String joinCode) async {
    await _repository.joinBatch(joinCode: joinCode);
    await loadBatches();
  }
}

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository();
});

final batchListProvider = StateNotifierProvider<BatchNotifier, BatchState>((ref) {
  final repo = ref.watch(batchRepositoryProvider);
  return BatchNotifier(repository: repo);
});
