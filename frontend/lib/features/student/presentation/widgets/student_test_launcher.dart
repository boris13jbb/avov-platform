import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../router/route_names.dart';
import '../../../vocational/presentation/providers/vocational_provider.dart';
import 'open_vocational_session_tile.dart';

/// Inicia una evaluación solo con acción explícita del estudiante.
///
/// Si ya hay varias abiertas, no llama a start: muestra guía contextual.
/// Ante HTTP 422 por ambigüedad, refresca el historial una vez.
class StudentTestLauncher extends ConsumerStatefulWidget {
  const StudentTestLauncher({
    super.key,
    this.openCount = 0,
  });

  /// Cantidad de sesiones STARTED o IN_PROGRESS ya conocidas en la UI.
  final int openCount;

  @override
  ConsumerState<StudentTestLauncher> createState() => _StudentTestLauncherState();
}

class _StudentTestLauncherState extends ConsumerState<StudentTestLauncher> {
  bool _starting = false;
  String? _error;

  static const _multipleOpenServerHint = 'más de una evaluación';

  @override
  Widget build(BuildContext context) {
    if (widget.openCount > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MultipleOpenSessionsNotice(),
          Text(
            'No puedes iniciar otra evaluación hasta elegir una de las pendientes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.openCount == 0)
          FilledButton(
            onPressed: _starting ? null : _start,
            child: _starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Iniciar evaluación'),
          ),
      ],
    );
  }

  Future<void> _start() async {
    if (_starting || widget.openCount > 0) {
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final session = await ref.read(vocationalRepositoryProvider).start();
      if (!mounted) {
        return;
      }
      context.push(RouteNames.studentTest(session.id));
    } on ValidationException catch (error) {
      await _handleStartValidation(error);
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = FailureMapper.unexpectedMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _handleStartValidation(ValidationException error) async {
    final isMultipleOpen =
        error.message.toLowerCase().contains(_multipleOpenServerHint);
    if (mounted) {
      setState(() {
        _error = isMultipleOpen
            ? MultipleOpenSessionsNotice.message
            : error.message;
      });
    }
    // Reinicia desde la página 1; el padre muestra carga/error/reintento.
    try {
      await ref.read(vocationalHistoryProvider.notifier).refresh();
    } catch (_) {
      // El error queda en vocationalHistoryProvider (mensaje + Reintentar).
    }
  }
}
