import 'package:avov_frontend/router/app_navigation.dart';
import 'package:avov_frontend/router/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNavigation.fallbackFor', () {
    test('el área admin vuelve al panel del superadministrador', () {
      expect(
        AppNavigation.fallbackFor(RouteNames.adminInstitutions),
        RouteNames.adminDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.adminInstitutionNew),
        RouteNames.adminDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.adminUsers),
        RouteNames.adminDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.adminStudents),
        RouteNames.adminDashboard,
      );
    });

    test('el área institucional vuelve a su panel', () {
      expect(
        AppNavigation.fallbackFor(RouteNames.institutionStudents),
        RouteNames.institutionDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.institutionCounselors),
        RouteNames.institutionDashboard,
      );
    });

    test('el orientador y el estudiante vuelven a su panel', () {
      expect(
        AppNavigation.fallbackFor(RouteNames.counselorStudents),
        RouteNames.counselorDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.studentProfile),
        RouteNames.studentDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.studentAssistant),
        RouteNames.studentDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.studentResults),
        RouteNames.studentDashboard,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.studentTest(12)),
        RouteNames.studentTestHome,
      );
      expect(
        AppNavigation.fallbackFor(RouteNames.studentTestResult(12)),
        RouteNames.studentResults,
      );
    });
  });

  group('AppNavigation.isRootLocation', () {
    test('solo marca los paneles raíz', () {
      expect(AppNavigation.isRootLocation(RouteNames.adminDashboard), isTrue);
      expect(
        AppNavigation.isRootLocation(RouteNames.institutionDashboard),
        isTrue,
      );
      expect(
        AppNavigation.isRootLocation(RouteNames.counselorDashboard),
        isTrue,
      );
      expect(AppNavigation.isRootLocation(RouteNames.studentDashboard), isTrue);
      expect(
        AppNavigation.isRootLocation(RouteNames.adminInstitutions),
        isFalse,
      );
      expect(AppNavigation.isRootLocation(RouteNames.login), isFalse);
    });
  });
}
