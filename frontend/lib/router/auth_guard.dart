import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/data/public_settings_remote_datasource.dart';
import '../core/models/user_profile.dart';
import '../core/models/user_role.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_token_storage.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import 'role_route_mapper.dart';
import 'route_names.dart';

class AuthGuard {
  AuthGuard({SecureTokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final SecureTokenStorage _tokenStorage;

  static const _publicRoutes = {
    RouteNames.splash,
    RouteNames.login,
    RouteNames.forgotPassword,
    RouteNames.resetPassword,
    RouteNames.notFound,
    RouteNames.unauthorized,
    RouteNames.maintenance,
  };

  static const _networkTimeout = Duration(seconds: 5);

  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;

    // No bloquear el primer frame: el splash gestiona su propia navegación.
    if (location == RouteNames.splash) {
      return null;
    }

    final isPublic = _publicRoutes.contains(location);
    final token = await _tokenStorage.getAccessToken();
    final isAuthenticated = token != null && token.isNotEmpty;
    final maintenanceMode = await _isMaintenanceMode();
    final userRole =
        isAuthenticated ? await _resolveUserRole() : null;
    final isSuperAdmin = userRole == UserRole.superAdmin;

    if (maintenanceMode && !isSuperAdmin) {
      const maintenancePublicRoutes = {
        RouteNames.maintenance,
        RouteNames.login,
        RouteNames.splash,
        RouteNames.forgotPassword,
        RouteNames.resetPassword,
      };
      if (!maintenancePublicRoutes.contains(location)) {
        return RouteNames.maintenance;
      }
    }

    if (!isAuthenticated && !isPublic) {
      return RouteNames.login;
    }

    if (!isAuthenticated) {
      return null;
    }
    final dashboardRoute =
        userRole == null ? null : RoleRouteMapper.routeFor(userRole);

    if (location == RouteNames.login) {
      return dashboardRoute ?? RouteNames.home;
    }

    if (location == RouteNames.home && dashboardRoute != null) {
      return dashboardRoute;
    }

    if (userRole != null && !RoleRouteMapper.canAccessRoute(userRole, location)) {
      return dashboardRoute ?? RouteNames.unauthorized;
    }

    return null;
  }

  Future<bool> _isMaintenanceMode() async {
    try {
      final dioClient = DioClient(tokenStorage: _tokenStorage);
      final datasource = PublicSettingsRemoteDatasource(dioClient.dio);
      final settings = await datasource
          .fetchPublicSettings()
          .timeout(_networkTimeout);
      return settings.maintenanceMode;
    } catch (_) {
      return false;
    }
  }

  Future<UserRole?> _resolveUserRole() async {
    final storedRole = await _tokenStorage.getUserRole();
    final parsedRole = UserRole.fromApi(storedRole);
    if (parsedRole != null) {
      return parsedRole;
    }

    try {
      final dioClient = DioClient(tokenStorage: _tokenStorage);
      final datasource = AuthRemoteDatasource(dioClient.dio);
      final data = await datasource.getMe().timeout(_networkTimeout);
      final profile = UserProfile.fromJson(data);
      await _tokenStorage.saveUserRole(profile.role.apiValue);
      return profile.role;
    } catch (_) {
      return null;
    }
  }
}
