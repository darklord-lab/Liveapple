import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/timetable_repository.dart';
import '../domain/timetable_model.dart';
import '../../../core/errors/app_exception.dart';

class TimetableState {
  final List<TimetableSlotModel> slots;
  final bool isLoading;
  final String? errorMessage;
  final int selectedDay; // 0..6 (0=Sun, 1=Mon, ..., 6=Sat)

  TimetableState({
    this.slots = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDay = 1, // Default to Monday
  });

  TimetableState copyWith({
    List<TimetableSlotModel>? slots,
    bool? isLoading,
    String? errorMessage,
    int? selectedDay,
  }) {
    return TimetableState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }

  List<TimetableSlotModel> get currentDaySlots {
    return slots.where((s) => s.dayOfWeek == selectedDay).toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
  }
}

class TimetableNotifier extends StateNotifier<TimetableState> {
  final TimetableRepository _repository;

  TimetableNotifier({TimetableRepository? repository})
      : _repository = repository ?? TimetableRepository(),
        super(TimetableState(selectedDay: DateTime.now().weekday % 7)) {
    loadSlots();
  }

  void selectDay(int day) {
    state = state.copyWith(selectedDay: day);
  }

  Future<void> loadSlots({String? batchId, String? teacherId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getSlots(batchId: batchId, teacherId: teacherId);
      state = state.copyWith(slots: list, isLoading: false);
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<TimetableSlotModel> createSlot({
    required String batchId,
    required int dayOfWeek,
    required int startMin,
    required int endMin,
    bool recurring = true,
  }) async {
    final slot = await _repository.createSlot(
      batchId: batchId,
      dayOfWeek: dayOfWeek,
      startMin: startMin,
      endMin: endMin,
      recurring: recurring,
    );

    state = state.copyWith(
      slots: [...state.slots, slot],
    );
    return slot;
  }

  Future<void> deleteSlot(String slotId) async {
    await _repository.deleteSlot(slotId);
    state = state.copyWith(
      slots: state.slots.where((s) => s.id != slotId).toList(),
    );
  }
}

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository();
});

final timetableProvider = StateNotifierProvider<TimetableNotifier, TimetableState>((ref) {
  final repo = ref.watch(timetableRepositoryProvider);
  return TimetableNotifier(repository: repo);
});
