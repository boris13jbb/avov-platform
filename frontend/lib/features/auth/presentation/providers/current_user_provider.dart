import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_profile.dart';
import 'auth_provider.dart';

final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  if (!await repository.isAuthenticated()) {
    return null;
  }
  return repository.getCurrentUser();
});
