import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/core/models/user_role.dart';
import 'package:avov_frontend/router/auth_redirect_logic.dart';
import 'package:avov_frontend/router/route_names.dart';

AuthRedirectInput _input({
  required String location,
  bool isAuthenticated = false,
  UserRole? userRole,
  bool maintenanceMode = false,
}) {
  return AuthRedirectInput(
    location: location,
    isAuthenticated: isAuthenticated,
    userRole: userRole,
    maintenanceMode: maintenanceMode,
  );
}

void main() {
  group('AuthRedirectLogic', () {
    test('splash no redirige', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(location: RouteNames.splash, isAuthenticated: false),
        ),
        isNull,
      );
    });

    test('ruta privada sin sesión va a login', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(location: RouteNames.studentDashboard),
        ),
        RouteNames.login,
      );
    });

    test('login público sin sesión no redirige', () {
      expect(
        AuthRedirectLogic.resolve(_input(location: RouteNames.login)),
        isNull,
      );
    });

    test('estudiante autenticado en login va a su dashboard', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.login,
            isAuthenticated: true,
            userRole: UserRole.student,
          ),
        ),
        RouteNames.studentDashboard,
      );
    });

    test('estudiante en ruta admin va a unauthorized', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.adminSettings,
            isAuthenticated: true,
            userRole: UserRole.student,
          ),
        ),
        RouteNames.unauthorized,
      );
    });

    test('super admin accede a rutas admin', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.adminCareers,
            isAuthenticated: true,
            userRole: UserRole.superAdmin,
          ),
        ),
        isNull,
      );
    });

    test('orientador no accede a dashboard estudiante', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.studentDashboard,
            isAuthenticated: true,
            userRole: UserRole.counselor,
          ),
        ),
        RouteNames.unauthorized,
      );
    });

    test('mantenimiento redirige a pantalla de mantenimiento', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.studentDashboard,
            isAuthenticated: true,
            userRole: UserRole.student,
            maintenanceMode: true,
          ),
        ),
        RouteNames.maintenance,
      );
    });

    test('super admin puede navegar durante mantenimiento', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.adminDashboard,
            isAuthenticated: true,
            userRole: UserRole.superAdmin,
            maintenanceMode: true,
          ),
        ),
        isNull,
      );
    });

    test('token con rol nulo en ruta protegida va a login', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.profile,
            isAuthenticated: true,
            userRole: null,
          ),
        ),
        RouteNames.login,
      );
    });

    test('shouldClearTokens cuando rol es nulo en ruta protegida', () {
      expect(
        AuthRedirectLogic.shouldClearTokensOnRedirect(
          _input(
            location: RouteNames.profile,
            isAuthenticated: true,
            userRole: null,
          ),
        ),
        isTrue,
      );
    });

    test('unauthorized es accesible cuando está autenticado', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.unauthorized,
            isAuthenticated: true,
            userRole: UserRole.student,
          ),
        ),
        isNull,
      );
    });

    test('home redirige al dashboard del rol', () {
      expect(
        AuthRedirectLogic.resolve(
          _input(
            location: RouteNames.home,
            isAuthenticated: true,
            userRole: UserRole.institutionAdmin,
          ),
        ),
        RouteNames.institutionDashboard,
      );
    });
  });
}
