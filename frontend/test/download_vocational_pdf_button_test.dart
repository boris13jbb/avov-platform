import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/features/vocational/domain/report_history.dart';
import 'package:avov_frontend/features/vocational/domain/report_repository.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/report_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/widgets/download_vocational_pdf_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReportRepo implements ReportRepository {
  _FakeReportRepo({
    this.file,
    this.error,
    this.delay = Duration.zero,
  });

  final VocationalPdfFile? file;
  final Object? error;
  final Duration delay;
  int calls = 0;

  @override
  Future<VocationalPdfFile> downloadSessionPdf(int sessionId) async {
    calls += 1;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) {
      throw error!;
    }
    return file!;
  }

  @override
  Future<ReportHistoryPage> listStudentReports(
    int studentId, {
    int page = 1,
    int pageSize = 20,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final validPdf = VocationalPdfFile(
    bytes: <int>[37, 80, 68, 70, 45, ...List<int>.filled(20, 32)],
    filename: 'informe-vocacional-AVOV-S1.pdf',
    reportCode: 'AVOV-S1-TEST',
  );

  testWidgets('muestra el botón y descarga con éxito', (tester) async {
    final repo = _FakeReportRepo(file: validPdf);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DownloadVocationalPdfButton(
              sessionId: 42,
              saver: ({required bytes, required filename}) async => filename,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Descargar PDF'), findsOneWidget);
    await tester.tap(find.text('Descargar PDF'));
    // Espera determinista: evita pumpAndSettle (animaciones del SnackBar).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));

    expect(repo.calls, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('AVOV-S1-TEST'), findsOneWidget);
  });

  testWidgets('bloquea doble pulsación mientras carga', (tester) async {
    final repo = _FakeReportRepo(
      file: validPdf,
      delay: const Duration(milliseconds: 200),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DownloadVocationalPdfButton(
              sessionId: 7,
              saver: ({required bytes, required filename}) async => filename,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Descargar PDF'));
    await tester.pump();
    expect(find.text('Preparando PDF…'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.calls, 1);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(repo.calls, 1);
  });

  testWidgets('muestra error HTTP comprensible', (tester) async {
    final repo = _FakeReportRepo(
      error: AppException('No tienes permisos para acceder a este recurso.'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DownloadVocationalPdfButton(
              sessionId: 3,
              saver: ({required bytes, required filename}) async => filename,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Descargar PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('permisos'), findsOneWidget);
  });

  testWidgets('rechaza bytes que no son PDF', (tester) async {
    final repo = _FakeReportRepo(
      error: AppException('El archivo recibido no es un PDF válido.'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DownloadVocationalPdfButton(
              sessionId: 9,
              saver: ({required bytes, required filename}) async => filename,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Descargar PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('PDF válido'), findsOneWidget);
  });
}
