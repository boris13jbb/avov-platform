import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/widgets/session_menu_button.dart';
import '../../domain/vector_admin_repository.dart';
import '../providers/vector_admin_provider.dart';

class VectorRebuildScreen extends ConsumerStatefulWidget {
  const VectorRebuildScreen({super.key});

  @override
  ConsumerState<VectorRebuildScreen> createState() => _VectorRebuildScreenState();
}

class _VectorRebuildScreenState extends ConsumerState<VectorRebuildScreen> {
  bool _busy = false;
  RebuildCareersResult? _lastResult;
  String? _errorMessage;

  Future<void> _rebuild() async {
    if (_busy) {
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reconstruir índice vectorial',
      message:
          'Se volverán a indexar las carreras activas en Qdrant desde MySQL. '
          'Puede tardar unos segundos.',
      confirmLabel: 'Reconstruir',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final result =
          await ref.read(vectorAdminRepositoryProvider).rebuildCareersIndex();
      if (mounted) {
        setState(() => _lastResult = result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Índice vectorial reconstruido correctamente'),
          ),
        );
      }
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = FailureMapper.unexpectedMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Índice vectorial'),
        actions: const [SessionMenuButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reconstrucción de carreras en Qdrant',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta operación regenera el índice semántico de carreras '
                    'a partir de los datos vigentes en MySQL. Solo el '
                    'superadministrador puede ejecutarla.',
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_lastResult != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Última reconstrucción',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Colección: ${_lastResult!.collection}'),
                            Text('Carreras indexadas: ${_lastResult!.indexed}'),
                            Text('Dimensión del vector: ${_lastResult!.vectorSize}'),
                            Text('Origen: ${_lastResult!.source}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _busy ? null : _rebuild,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_busy ? 'Reconstruyendo…' : 'Reconstruir índice'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
