import 'package:flutter_test/flutter_test.dart';

import 'package:avov_frontend/core/models/user_role.dart';
import 'package:avov_frontend/router/role_route_mapper.dart';
import 'package:avov_frontend/router/route_names.dart';

void main() {
  group('RoleRouteMapper', () {
    test('super admin accede a rutas admin', () {
      expect(
        RoleRouteMapper.canAccessRoute(
          UserRole.superAdmin,
          RouteNames.adminSettings,
        ),
        isTrue,
      );
    });

    test('estudiante no accede a rutas admin', () {
      expect(
        RoleRouteMapper.canAccessRoute(
          UserRole.student,
          RouteNames.adminSettings,
        ),
        isFalse,
      );
    });

    test('estudiante accede a su dashboard y perfil', () {
      expect(
        RoleRouteMapper.canAccessRoute(
          UserRole.student,
          RouteNames.studentDashboard,
        ),
        isTrue,
      );
      expect(
        RoleRouteMapper.canAccessRoute(
          UserRole.student,
          RouteNames.studentProfile,
        ),
        isTrue,
      );
    });

    test('ruta desconocida deniega acceso', () {
      expect(
        RoleRouteMapper.canAccessRoute(
          UserRole.counselor,
          '/ruta-inexistente',
        ),
        isFalse,
      );
    });

    test('ruta home solo es legacy', () {
      expect(
        RoleRouteMapper.canAccessRoute(
          UserRole.student,
          RouteNames.home,
        ),
        isTrue,
      );
    });
  });
}
