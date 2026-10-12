import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/features/timetable/presentation/add_timetable_slot_dialog.dart';
import 'package:classora_mobile/features/batch/domain/batch_model.dart';
import 'package:classora_mobile/features/batch/presentation/batch_controller.dart';

void main() {
  testWidgets('C1: Render 90-character batch name at 320dp width without overflow', (WidgetTester tester) async {
    const longBatchName = 'Comprehensive Advanced JEE Physics Mastery & Quantum Mechanics Batch For Class 12 Toppers';
    final testBatch = BatchModel(
      id: 'batch-test-90',
      name: longBatchName,
      subject: 'Physics',
      joinCode: 'JEE90C',
      teacherId: 'usr-teacher-01',
      createdAt: DateTime.now(),
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          batchListProvider.overrideWith((ref) => BatchNotifierMock(
                BatchState(
                  batches: [testBatch],
                  isLoading: false,
                ),
              )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: AddTimetableSlotDialog(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'No layout overflow exception must occur at 320dp width');
  });
}

class BatchNotifierMock extends BatchNotifier {
  final BatchState initialState;
  BatchNotifierMock(this.initialState) : super() {
    state = initialState;
  }

  @override
  Future<void> loadBatches({String? search, String? teacherId}) async {
    state = initialState;
  }
}
