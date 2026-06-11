import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/public_settings_remote_datasource.dart';
import '../models/public_settings.dart';
import 'providers.dart';

final publicSettingsRemoteDatasourceProvider =
    Provider<PublicSettingsRemoteDatasource>((ref) {
  return PublicSettingsRemoteDatasource(ref.watch(dioClientProvider).dio);
});

final publicSettingsProvider = FutureProvider<PublicSettings>((ref) async {
  final datasource = ref.watch(publicSettingsRemoteDatasourceProvider);
  return datasource.fetchPublicSettings();
});
