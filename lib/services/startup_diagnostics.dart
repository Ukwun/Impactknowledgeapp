import 'package:get/get.dart';

class StartupDiagnosticsReport {
  final bool isValid;
  final List<String> missingRoutes;

  const StartupDiagnosticsReport({
    required this.isValid,
    required this.missingRoutes,
  });
}

class StartupDiagnostics {
  static const Map<String, List<String>> roleFlowRoutes = {
    'learner': ['/dashboard', '/courses', '/learner-classroom', '/assignments'],
    'facilitator': [
      '/dashboard',
      '/facilitator-classroom',
      '/events',
      '/notifications',
    ],
    'admin': [
      '/dashboard',
      '/admin-management',
      '/global-search',
      '/notifications',
    ],
  };

  static StartupDiagnosticsReport validateRoleFlows(
    List<GetPage<dynamic>> pages,
  ) {
    final registered = pages.map((page) => page.name).toSet();
    final missing = <String>[];

    for (final role in roleFlowRoutes.keys) {
      final routes = roleFlowRoutes[role] ?? const <String>[];
      for (final route in routes) {
        if (!_isRouteRegistered(route, registered)) {
          missing.add('$role:$route');
        }
      }
    }

    return StartupDiagnosticsReport(
      isValid: missing.isEmpty,
      missingRoutes: missing,
    );
  }

  static bool _isRouteRegistered(String route, Set<String> registered) {
    if (registered.contains(route)) return true;

    // Accept parameterized pages such as /assignments/:courseId when the
    // critical flow requires the base route /assignments.
    for (final registeredRoute in registered) {
      if (registeredRoute.startsWith('$route/')) {
        return true;
      }
    }

    return false;
  }
}
