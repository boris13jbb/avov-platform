import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/storage/secure_token_storage.dart';
import 'role_destination.dart';
import 'route_names.dart';

class AuthGuard {
  AuthGuard({SecureTokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final SecureTokenStorage _tokenStorage;

  static const _publicRoutes = {
    RouteNames.splash,
    RouteNames.login,
    RouteNames.notFound,
  };

  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;
    final isPublic = _publicRoutes.contains(location);
    final token = await _tokenStorage.getAccessToken();
    final isAuthenticated = token != null && token.isNotEmpty;
    final role = isAuthenticated ? await _tokenStorage.getUserRole() : null;

    if (!isAuthenticated && !isPublic) {
      return RouteNames.login;
    }

    if (isAuthenticated &&
        (location == RouteNames.login || location == RouteNames.splash)) {
      return destinationForRole(role);
    }

    if (isAuthenticated && !routeMatchesRole(location, role)) {
      return RouteNames.unauthorized;
    }

    return null;
  }
}
