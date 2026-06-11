import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/public_settings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/providers/public_settings_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../router/role_route_mapper.dart';
import '../../../../router/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_navigate());
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    PublicSettings? settings;
    try {
      settings = await ref.read(publicSettingsProvider.future);
    } catch (_) {
      settings = null;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final isAuthenticated = await authRepository.isAuthenticated();
    UserRole? userRole;

    if (isAuthenticated) {
      final roleValue = await authRepository.getStoredRole();
      userRole = UserRole.fromApi(roleValue);
      if (userRole == null) {
        try {
          final profile = await authRepository.getCurrentUser();
          userRole = profile.role;
        } catch (_) {
          userRole = null;
        }
      }
    }

    if (!mounted) {
      return;
    }

    final maintenance = settings?.maintenanceMode ?? false;
    final isSuperAdmin = userRole == UserRole.superAdmin;

    if (maintenance && !isSuperAdmin) {
      context.go(RouteNames.maintenance);
      return;
    }

    if (isAuthenticated && userRole != null) {
      context.go(RoleRouteMapper.routeFor(userRole));
      return;
    }

    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(publicSettingsProvider);
    final appName = settingsAsync.when(
      data: (settings) => settings.appDisplayName,
      loading: () => 'AVOV',
      error: (_, __) => 'AVOV',
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asistente Virtual de Orientación Vocacional',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
