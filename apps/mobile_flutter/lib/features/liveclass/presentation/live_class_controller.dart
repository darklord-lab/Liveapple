import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/live_class_repository.dart';
import '../domain/live_class_model.dart';
import '../../../core/errors/app_exception.dart';

class LiveClassState {
  final List<LiveClassModel> classes;
  final bool isLoading;
  final String? errorMessage;

  LiveClassState({
    this.classes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LiveClassState copyWith({
    List<LiveClassModel>? classes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LiveClassState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<LiveClassModel> get liveNow => classes.where((c) => c.isLive).toList();
  List<LiveClassModel> get upcoming => classes.where((c) => c.isScheduled).toList();
}

class LiveClassNotifier extends StateNotifier<LiveClassState> {
  final LiveClassRepository _repository;

  LiveClassNotifier({LiveClassRepository? repository})
      : _repository = repository ?? LiveClassRepository(),
        super(LiveClassState()) {
    loadClasses();
  }

  Future<void> loadClasses({String? batchId, String? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getClasses(batchId: batchId, status: status);
      state = state.copyWith(classes: list, isLoading: false);
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<Map<String, dynamic>> generateUpcoming({int daysAhead = 7}) async {
    final result = await _repository.generateUpcoming(daysAhead: daysAhead);
    await loadClasses();
    return result;
  }

  Future<LiveClassModel> createClass({
    required String batchId,
    required String title,
    required String scheduledAt,
  }) async {
    final newClass = await _repository.createClass(
      batchId: batchId,
      title: title,
      scheduledAt: scheduledAt,
    );
    state = state.copyWith(classes: [newClass, ...state.classes]);
    return newClass;
  }

  Future<LiveClassModel?> startClass(String id) async {
    try {
      final updated = await _repository.startClass(id);
      await loadClasses();
      return updated;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(errorMessage: msg);
      return null;
    }
  }
}

final liveClassRepositoryProvider = Provider<LiveClassRepository>((ref) {
  return LiveClassRepository();
});

final liveClassProvider = StateNotifierProvider<LiveClassNotifier, LiveClassState>((ref) {
  final repo = ref.watch(liveClassRepositoryProvider);
  return LiveClassNotifier(repository: repo);
});
