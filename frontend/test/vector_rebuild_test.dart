import 'package:avov_frontend/features/admin/domain/vector_admin_repository.dart';
import 'package:avov_frontend/features/admin/presentation/providers/vector_admin_provider.dart';
import 'package:avov_frontend/features/admin/presentation/screens/vector_rebuild_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la pantalla de reconstrucción muestra la acción principal',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vectorAdminRepositoryProvider.overrideWithValue(_VectorRepo()),
        ],
        child: const MaterialApp(home: VectorRebuildScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Reconstruir índice'), findsOneWidget);
    expect(find.textContaining('Qdrant'), findsWidgets);
  });
}

class _VectorRepo implements VectorAdminRepository {
  @override
  Future<RebuildCareersResult> rebuildCareersIndex() async {
    return const RebuildCareersResult(
      collection: 'careers',
      indexed: 5,
      vectorSize: 384,
      source: 'mysql',
    );
  }
}
