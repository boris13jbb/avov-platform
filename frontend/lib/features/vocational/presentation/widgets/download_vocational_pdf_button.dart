import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/download/save_bytes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../providers/report_provider.dart';

typedef VocationalPdfSaver = Future<String> Function({
  required List<int> bytes,
  required String filename,
});

/// Descarga el PDF de una sesión COMPLETED sin alterar evaluaciones ni recomendaciones.
class DownloadVocationalPdfButton extends ConsumerStatefulWidget {
  const DownloadVocationalPdfButton({
    super.key,
    required this.sessionId,
    this.saver,
  });

  final int sessionId;

  /// Inyectable en pruebas; por defecto usa el guardado de plataforma.
  final VocationalPdfSaver? saver;

  @override
  ConsumerState<DownloadVocationalPdfButton> createState() =>
      _DownloadVocationalPdfButtonState();
}

class _DownloadVocationalPdfButtonState
    extends ConsumerState<DownloadVocationalPdfButton> {
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await ref
          .read(reportRepositoryProvider)
          .downloadSessionPdf(widget.sessionId);
      final save = widget.saver ?? saveBytesToUser;
      final saved = await save(
        bytes: file.bytes,
        filename: file.filename,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            file.reportCode == null
                ? 'Informe descargado ($saved).'
                : 'Informe ${file.reportCode} descargado.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AppException
          ? error.message
          : FailureMapper.unexpectedMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: ValueKey('download-pdf-${widget.sessionId}'),
      onPressed: _busy ? null : _download,
      icon: Icon(
        _busy ? Icons.hourglass_top : Icons.picture_as_pdf_outlined,
      ),
      label: Text(_busy ? 'Preparando PDF…' : 'Descargar PDF'),
    );
  }
}
