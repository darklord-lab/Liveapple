import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/main.dart';

void main() {
  testWidgets('Classora smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ClassoraApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Classora'), findsOneWidget);
  });
}
