import 'package:flutter_test/flutter_test.dart';
import 'package:impactknowledge_app/config/routes.dart';
import 'package:impactknowledge_app/services/startup_diagnostics.dart';

void main() {
  test('startup role flow diagnostics passes for registered routes', () {
    final report = StartupDiagnostics.validateRoleFlows(AppPages.pages);

    expect(
      report.isValid,
      isTrue,
      reason: 'All critical role routes must be registered at startup.',
    );
    expect(report.missingRoutes, isEmpty);
  });
}
