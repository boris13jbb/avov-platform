import '../core/models/user_role.dart';
import 'route_names.dart';

class RoleRouteMapper {
  RoleRouteMapper._();

  static String routeFor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return RouteNames.adminDashboard;
      case UserRole.institutionAdmin:
        return RouteNames.institutionDashboard;
      case UserRole.counselor:
        return RouteNames.counselorDashboard;
      case UserRole.student:
        return RouteNames.studentDashboard;
    }
  }

  static String? routeForApiValue(String? apiValue) {
    final role = UserRole.fromApi(apiValue);
    return role == null ? null : routeFor(role);
  }

  static bool canAccess(UserRole role, String location) {
    return routeFor(role) == location;
  }

  static bool isDashboardRoute(String location) {
    return location == RouteNames.adminDashboard ||
        location == RouteNames.institutionDashboard ||
        location == RouteNames.counselorDashboard ||
        location == RouteNames.studentDashboard;
  }

  static bool isSuperAdminRoute(String location) {
    return location == RouteNames.adminDashboard ||
        location.startsWith(RouteNames.adminInstitutions) ||
        location.startsWith(RouteNames.adminUsers) ||
        location.startsWith(RouteNames.adminCareers) ||
        location.startsWith(RouteNames.adminQuestions) ||
        location.startsWith(RouteNames.adminVector) ||
        location.startsWith(RouteNames.adminAudit) ||
        location.startsWith(RouteNames.adminSettings);
  }

  static bool isAuthenticatedCommonRoute(String location) {
    return location == RouteNames.profile ||
        location == RouteNames.changePassword;
  }

  static bool isInstitutionAdminRoute(String location) {
    return location == RouteNames.institutionDashboard ||
        location.startsWith(RouteNames.institutionCounselors) ||
        location.startsWith(RouteNames.institutionStudents) ||
        location == RouteNames.institutionReports ||
        location == RouteNames.institutionExports ||
        location == RouteNames.institutionSettings;
  }

  static bool isStudentRoute(String location) {
    return location == RouteNames.studentDashboard ||
        location.startsWith('/student/');
  }

  static bool isCounselorRoute(String location) {
    return location == RouteNames.counselorDashboard ||
        location.startsWith(RouteNames.counselorStudents);
  }

  static bool canAccessRoute(UserRole role, String location) {
    if (isAuthenticatedCommonRoute(location)) {
      return true;
    }
    if (isSuperAdminRoute(location)) {
      return role == UserRole.superAdmin;
    }
    if (isInstitutionAdminRoute(location)) {
      return role == UserRole.institutionAdmin;
    }
    if (isCounselorRoute(location)) {
      return role == UserRole.counselor;
    }
    if (isStudentRoute(location)) {
      return role == UserRole.student;
    }
    if (isDashboardRoute(location)) {
      return canAccess(role, location);
    }
    if (location == RouteNames.home) {
      return true;
    }
    return false;
  }
}
