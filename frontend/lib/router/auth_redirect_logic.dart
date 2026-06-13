import '../core/models/user_role.dart';
import 'role_route_mapper.dart';
import 'route_names.dart';

/// Estado de autenticación resuelto para decidir redirecciones del router.
class AuthRedirectInput {
  const AuthRedirectInput({
    required this.location,
    required this.isAuthenticated,
    required this.userRole,
    required this.maintenanceMode,
  });

  final String location;
  final bool isAuthenticated;
  final UserRole? userRole;
  final bool maintenanceMode;
}

/// Lógica pura de redirección usada por [AuthGuard] (testeable sin red ni storage).
class AuthRedirectLogic {
  AuthRedirectLogic._();

  static const publicRoutes = {
    RouteNames.splash,
    RouteNames.login,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
    RouteNames.notFound,
    RouteNames.unauthorized,
    RouteNames.maintenance,
  };

  static const maintenancePublicRoutes = {
    RouteNames.maintenance,
    RouteNames.login,
    RouteNames.splash,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
  };

  static const roleRecoveryRoutes = {
    RouteNames.login,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
    RouteNames.unauthorized,
  };

  /// Retorna la ruta destino o `null` si no hay redirección.
  static String? resolve(AuthRedirectInput input) {
    final location = input.location;

    if (location == RouteNames.splash) {
      return null;
    }

    final isPublic = publicRoutes.contains(location);
    final isSuperAdmin = input.userRole == UserRole.superAdmin;

    if (input.maintenanceMode && !isSuperAdmin) {
      if (!maintenancePublicRoutes.contains(location)) {
        return RouteNames.maintenance;
      }
    }

    if (!input.isAuthenticated && !isPublic) {
      return RouteNames.login;
    }

    if (!input.isAuthenticated) {
      return null;
    }

    if (input.userRole == null) {
      if (!roleRecoveryRoutes.contains(location)) {
        return RouteNames.login;
      }
      return null;
    }

    final dashboardRoute = RoleRouteMapper.routeFor(input.userRole!);

    if (location == RouteNames.login) {
      return dashboardRoute;
    }

    if (location == RouteNames.home) {
      return dashboardRoute;
    }

    if (location == RouteNames.unauthorized) {
      return null;
    }

    if (!RoleRouteMapper.canAccessRoute(input.userRole!, location)) {
      return RouteNames.unauthorized;
    }

    return null;
  }

  /// Indica si la sesión debe limpiarse por rol inválido en ruta protegida.
  static bool shouldClearTokensOnRedirect(AuthRedirectInput input) {
    return input.isAuthenticated &&
        input.userRole == null &&
        !roleRecoveryRoutes.contains(input.location) &&
        input.location != RouteNames.splash;
  }
}
