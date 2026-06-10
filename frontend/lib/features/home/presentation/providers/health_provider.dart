import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/datasources/health_remote_datasource.dart';

final healthDatasourceProvider = Provider<HealthRemoteDatasource>((ref) {
  return HealthRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final apiHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(healthDatasourceProvider);
  return datasource.checkHealth();
});
