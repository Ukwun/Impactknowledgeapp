import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:impactknowledge_app/screens/dashboard/roles/role_dashboard_widgets.dart';

void main() {
  testWidgets('RoleDashboardScaffold renders title and role chip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoleDashboardScaffold(
            title: 'Parent Dashboard',
            subtitle: 'Monitor progress',
            roleLabel: 'Parent',
            firstName: 'Ada',
            children: [],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Parent Dashboard'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
  });
}
