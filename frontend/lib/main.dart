import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Continuar evaluación usa context.push('/student/test/:id'). Por defecto
  // go_router no refleja push imperativo en la URL web; esas rutas sí son
  // deeplink-ables y deben verse en el hash (p. ej. #/student/test/138).
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(
    const ProviderScope(
      child: AvovApp(),
    ),
  );
}

class AvovApp extends ConsumerWidget {
  const AvovApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: AppConfig.development.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
