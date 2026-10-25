import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_vector_admin_repository.dart';
import '../../domain/vector_admin_repository.dart';

final vectorAdminRepositoryProvider = Provider<VectorAdminRepository>((ref) {
  return ApiVectorAdminRepository(ref.watch(dioClientProvider).dio);
});
