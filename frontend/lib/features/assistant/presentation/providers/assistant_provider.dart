import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/api_assistant_repository.dart';
import '../../domain/assistant_repository.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return ApiAssistantRepository(ref.watch(dioClientProvider).dio);
});
