import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/core/widgets/filter_sort_sheet.dart';
import 'package:classora_mobile/features/learning/presentation/controllers/learning_controller.dart';
import 'package:classora_mobile/features/learning/domain/models/learning_models.dart';
import 'package:classora_mobile/features/learning/presentation/screens/recordings_screen.dart';
import 'package:classora_mobile/features/learning/presentation/screens/assignments_screen.dart';
import 'package:classora_mobile/features/learning/presentation/screens/cbt_tests_screen.dart';

void main() {
  group('Phase 4.8 — FilterSortSheet Models & Logic', () {
    test('FilterConfig and SortConfig models initialize correctly', () {
      const filter = FilterConfig<String>(
        id: 'batch',
        title: 'Batch',
        options: [
          FilterItem(value: 'ALL', label: 'All Batches', count: 10),
          FilterItem(value: 'b1', label: 'Batch A', count: 4),
          FilterItem(value: 'b2', label: 'Batch B', count: 6),
        ],
        initialValue: 'ALL',
        defaultValue: 'ALL',
      );

      expect(filter.id, 'batch');
      expect(filter.title, 'Batch');
      expect(filter.options.length, 3);
      expect(filter.options[1].count, 4);
      expect(filter.initialValue, 'ALL');
      expect(filter.defaultValue, 'ALL');

      const sort = SortConfig<String>(
        title: 'Sort Order',
        options: [
          SortOptionItem(value: 'newest', label: 'Newest First', icon: Icons.schedule),
          SortOptionItem(value: 'oldest', label: 'Oldest First', icon: Icons.history),
        ],
        initialValue: 'newest',
        defaultValue: 'newest',
      );

      expect(sort.options.length, 2);
      expect(sort.initialValue, 'newest');
    });

    test('FilterSortSelection returns values with fallback', () {
      const selection = FilterSortSelection<String>(
        filterValues: {
          'batch': 'batch_123',
          'status': 'PENDING',
        },
        sortValue: 'due_soonest',
      );

      expect(selection.getFilter('batch', 'ALL'), 'batch_123');
      expect(selection.getFilter('status', 'ALL'), 'PENDING');
      expect(selection.getFilter('subject', 'ALL'), 'ALL');
      expect(selection.sortValue, 'due_soonest');
    });
  });

  group('Phase 4.8 — FilterBadgeButton Widget Tests', () {
    testWidgets('Renders clean icon without badge when activeCount is 0', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                FilterBadgeButton(
                  activeCount: 0,
                  onPressed: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('0'), findsNothing);

      await tester.tap(find.byType(FilterBadgeButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Renders badge with active filter count when activeCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                FilterBadgeButton(
                  activeCount: 3,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('Phase 4.8 — ActiveFiltersBar Widget Tests', () {
    testWidgets('Renders nothing when chip list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActiveFiltersBar(
              chips: [],
              onClearAll: _dummyClear,
            ),
          ),
        ),
      );

      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets('Renders active chips and triggers removal and clear-all callbacks', (tester) async {
      var removedFirst = false;
      var clearedAll = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveFiltersBar(
              chips: [
                ActiveFilterChipData(
                  label: 'Batch: Class 10',
                  onRemoved: () => removedFirst = true,
                ),
                ActiveFilterChipData(
                  label: 'Status: Pending',
                  onRemoved: () {},
                ),
              ],
              onClearAll: () => clearedAll = true,
            ),
          ),
        ),
      );

      expect(find.text('Batch: Class 10'), findsOneWidget);
      expect(find.text('Status: Pending'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      expect(removedFirst, isTrue);

      await tester.tap(find.text('Clear all'));
      await tester.pump();
      expect(clearedAll, isTrue);
    });
  });

  group('Phase 4.8 — FilterSortSheet Interactive Modal Tests', () {
    testWidgets('Displays options, allows selection, resets, and returns selection on Apply', (tester) async {
      FilterSortSelection<String>? returnedSelection;

      const filters = [
        FilterConfig<String>(
          id: 'batch',
          title: 'Batch',
          options: [
            FilterItem(value: 'ALL', label: 'All Batches'),
            FilterItem(value: 'b1', label: 'Maths 2026'),
            FilterItem(value: 'b2', label: 'Science 2026'),
          ],
          initialValue: 'ALL',
          defaultValue: 'ALL',
        ),
        FilterConfig<String>(
          id: 'status',
          title: 'Status',
          options: [
            FilterItem(value: 'ALL', label: 'All Statuses'),
            FilterItem(value: 'PENDING', label: 'Pending'),
            FilterItem(value: 'COMPLETED', label: 'Completed'),
          ],
          initialValue: 'ALL',
          defaultValue: 'ALL',
        ),
      ];

      const sort = SortConfig<String>(
        title: 'Sort Order',
        options: [
          SortOptionItem(value: 'newest', label: 'Newest First', icon: Icons.schedule),
          SortOptionItem(value: 'oldest', label: 'Oldest First', icon: Icons.history),
        ],
        initialValue: 'newest',
        defaultValue: 'newest',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedSelection = await showFilterSortSheet<String>(
                    context: context,
                    title: 'Filter Recordings',
                    filters: filters,
                    sort: sort,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Recordings'), findsOneWidget);
      expect(find.text('BATCH'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('SORT ORDER'), findsOneWidget);
      expect(find.text('Maths 2026'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Newest First'), findsOneWidget);
      expect(find.text('Oldest First'), findsOneWidget);

      await tester.tap(find.text('Maths 2026'));
      await tester.pumpAndSettle();
      expect(find.text('1 active'), findsOneWidget);

      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
      expect(find.text('2 active'), findsOneWidget);

      await tester.tap(find.text('Oldest First'));
      await tester.pumpAndSettle();
      expect(find.text('3 active'), findsOneWidget);

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(returnedSelection, isNotNull);
      expect(returnedSelection!.getFilter('batch', 'ALL'), 'b1');
      expect(returnedSelection!.getFilter('status', 'ALL'), 'PENDING');
      expect(returnedSelection!.sortValue, 'oldest');
    });

    testWidgets('Reset All resets selections back to default values', (tester) async {
      FilterSortSelection<String>? returnedSelection;

      const filters = [
        FilterConfig<String>(
          id: 'category',
          title: 'Category',
          options: [
            FilterItem(value: 'ALL', label: 'All'),
            FilterItem(value: 'c1', label: 'Category 1'),
          ],
          initialValue: 'c1',
          defaultValue: 'ALL',
        ),
      ];

      const sort = SortConfig<String>(
        title: 'Sort',
        options: [
          SortOptionItem(value: 'newest', label: 'Newest'),
          SortOptionItem(value: 'oldest', label: 'Oldest'),
        ],
        initialValue: 'oldest',
        defaultValue: 'newest',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedSelection = await showFilterSortSheet<String>(
                    context: context,
                    filters: filters,
                    sort: sort,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('2 active'), findsOneWidget);

      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(find.text('2 active'), findsNothing);

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(returnedSelection, isNotNull);
      expect(returnedSelection!.getFilter('category', 'fallback'), 'ALL');
      expect(returnedSelection!.sortValue, 'newest');
    });

    testWidgets('Renders without overflow at 320dp width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const filters = [
        FilterConfig<String>(
          id: 'batch',
          title: 'Cohort Batch',
          options: [
            FilterItem(value: 'ALL', label: 'All Batches'),
            FilterItem(value: 'b1', label: 'Advanced JEE Physics 2026 Batch'),
          ],
          initialValue: 'b1',
          defaultValue: 'ALL',
        ),
      ];

      const sort = SortConfig<String>(
        title: 'Sort Order',
        options: [
          SortOptionItem(value: 'newest', label: 'Newest First'),
        ],
        initialValue: 'newest',
        defaultValue: 'newest',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showFilterSortSheet<String>(
                    context: context,
                    title: 'Filter Recordings',
                    filters: filters,
                    sort: sort,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Recordings'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'No layout overflow must occur at 320dp width');
    });
  });

  group('Phase 4.8 — List Screens Integration Tests', () {
    testWidgets('RecordingsScreen renders FilterBadgeButton and filter sheet', (tester) async {
      final mockRecordings = [
        RecordingModel(
          id: 'rec-1',
          title: 'Thermodynamics Lecture 01',
          videoUrl: 'https://example.com/rec1.mp4',
          durationSec: 3600,
          fileSizeMb: 450.0,
          batchName: 'Physics 101',
          subject: 'Physics',
          createdAt: DateTime(2026, 10, 1),
        ),
        RecordingModel(
          id: 'rec-2',
          title: 'Calculus Intro',
          videoUrl: 'https://example.com/rec2.mp4',
          durationSec: 2400,
          fileSizeMb: 300.0,
          batchName: 'Maths 202',
          subject: 'Mathematics',
          createdAt: DateTime(2026, 10, 2),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordingsProvider.overrideWith((ref) => Future.value(mockRecordings)),
          ],
          child: const MaterialApp(
            home: RecordingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilterBadgeButton), findsOneWidget);
      expect(find.text('Thermodynamics Lecture 01'), findsOneWidget);
      expect(find.text('Calculus Intro'), findsOneWidget);

      // Open filter sheet
      await tester.tap(find.byType(FilterBadgeButton));
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort Recordings'), findsOneWidget);
      expect(find.text('Physics 101'), findsOneWidget);
      expect(find.text('Maths 202'), findsOneWidget);

      // Filter by Physics 101
      await tester.tap(find.text('Physics 101'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Only Physics 101 shown
      expect(find.text('Thermodynamics Lecture 01'), findsOneWidget);
      expect(find.text('Calculus Intro'), findsNothing);
      expect(find.text('Batch: Physics 101'), findsOneWidget);
    });

    testWidgets('AssignmentsScreen renders FilterBadgeButton and filters by status', (tester) async {
      final mockAssignments = [
        AssignmentModel(
          id: 'ass-1',
          title: 'Kinematics DPP 01',
          description: 'Solve all questions',
          dueDate: DateTime(2026, 10, 20),
          maxMarks: 50,
          batchName: 'Physics 101',
          subject: 'Physics',
          isSubmitted: false,
        ),
        AssignmentModel(
          id: 'ass-2',
          title: 'Differential Equations HW',
          description: 'Complete exercise 3.2',
          dueDate: DateTime(2026, 10, 25),
          maxMarks: 100,
          batchName: 'Maths 202',
          subject: 'Mathematics',
          isSubmitted: true,
          submissionStatus: 'GRADED',
          marksObtained: 95,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsProvider.overrideWith((ref) => Future.value(mockAssignments)),
          ],
          child: const MaterialApp(
            home: AssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilterBadgeButton), findsOneWidget);
      expect(find.text('Kinematics DPP 01'), findsOneWidget);
      expect(find.text('Differential Equations HW'), findsOneWidget);

      // Open filter sheet
      await tester.tap(find.byType(FilterBadgeButton));
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort Assignments'), findsOneWidget);
      expect(find.text('Pending Submission'), findsOneWidget);

      // Select Pending Submission
      await tester.tap(find.text('Pending Submission'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Kinematics DPP 01'), findsOneWidget);
      expect(find.text('Differential Equations HW'), findsNothing);
      expect(find.text('Status: Pending'), findsOneWidget);
    });

    testWidgets('CbtTestsScreen renders FilterBadgeButton and filters by attempt status', (tester) async {
      final mockTests = [
        CbtTestModel(
          id: 'test-1',
          title: 'Physics Mid-Term Exam',
          durationMin: 60,
          totalMarks: 100,
          questionsCount: 25,
          isAttempted: false,
          batchName: 'Physics 101',
          subject: 'Physics',
        ),
        CbtTestModel(
          id: 'test-2',
          title: 'Maths Weekly Quiz',
          durationMin: 30,
          totalMarks: 50,
          questionsCount: 15,
          isAttempted: true,
          myScore: 48,
          batchName: 'Maths 202',
          subject: 'Mathematics',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cbtTestsProvider.overrideWith((ref) => Future.value(mockTests)),
          ],
          child: const MaterialApp(
            home: CbtTestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilterBadgeButton), findsOneWidget);
      expect(find.text('Physics Mid-Term Exam'), findsOneWidget);
      expect(find.text('Maths Weekly Quiz'), findsOneWidget);

      // Open filter sheet
      await tester.tap(find.byType(FilterBadgeButton));
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort Tests'), findsOneWidget);
      expect(find.text('Attempted (Completed)'), findsOneWidget);

      // Select Attempted
      await tester.tap(find.text('Attempted (Completed)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Maths Weekly Quiz'), findsOneWidget);
      expect(find.text('Physics Mid-Term Exam'), findsNothing);
      expect(find.text('Status: Attempted'), findsOneWidget);
    });
  });
}

void _dummyClear() {}
