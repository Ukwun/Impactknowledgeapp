import 'package:flutter_test/flutter_test.dart';
import 'package:impactknowledge_app/config/service_locator.dart';
import 'package:impactknowledge_app/main.dart';

void main() {
  testWidgets('App boots to splash then landing', (WidgetTester tester) async {
    setupServiceLocator();

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Learning. Building. Leading.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pumpAndSettle();

    expect(find.text('From Knowledge to Opportunity'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
