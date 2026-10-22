import 'package:avov_frontend/core/errors/app_exception.dart';
import 'package:avov_frontend/features/vocational/domain/report_history.dart';
import 'package:avov_frontend/features/vocational/domain/report_repository.dart';
import 'package:avov_frontend/features/vocational/presentation/providers/report_provider.dart';
import 'package:avov_frontend/features/vocational/presentation/widgets/student_reports_history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoryRepo implements ReportRepository {
  _FakeHistoryRepo({this.page, this.error});

  ReportHistoryPage? page;
  Object? error;
  final List<int> listedStudentIds = <int>[];
  final List<int> downloadedSessions = <int>[];

  @override
  Future<VocationalPdfFile> downloadSessionPdf(int sessionId) async {
    downloadedSessions.add(sessionId);
    return VocationalPdfFile(
      bytes: <int>[37, 80, 68, 70, 45, ...List<int>.filled(8, 32)],
      filename: 'informe-vocacional-$sessionId.pdf',
      reportCode: 'CODE-$sessionId',
    );
  }

  @override
  Future<ReportHistoryPage> listStudentReports(
    int studentId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    listedStudentIds.add(studentId);
    if (error != null) {
      throw error!;
    }
    return this.page!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final samplePage = ReportHistoryPage(
    items: [
      ReportHistoryItem(
        id: 2,
        studentId: 10,
        testSessionId: 55,
        reportCode: 'AVOV-S55-ABC',
        generatedBy: 1,
        createdAt: DateTime.utc(2026, 3, 15, 14, 30),
        updatedAt: DateTime.utc(2026, 3, 15, 14, 30),
      ),
      ReportHistoryItem(
        id: 1,
        studentId: 10,
        testSessionId: 44,
        reportCode: 'AVOV-S44-XYZ',
        generatedBy: 1,
        createdAt: DateTime.utc(2026, 3, 10, 9, 0),
        updatedAt: DateTime.utc(2026, 3, 10, 9, 0),
      ),
    ],
    total: 2,
    page: 1,
    pageSize: 20,
    pages: 1,
  );

  test('ReportHistoryPage.fromJson parsea metadatos sin rutas', () {
    final parsed = ReportHistoryPage.fromJson({
      'items': [
        {
          'id': 1,
          'student_id': 10,
          'test_session_id': 44,
          'report_code': 'AVOV-S44-XYZ',
          'generated_by': 3,
          'created_at': '2026-03-10T09:00:00',
          'updated_at': '2026-03-10T09:00:00',
        },
      ],
      'total': 1,
      'page': 1,
      'page_size': 20,
      'pages': 1,
    });
    expect(parsed.total, 1);
    expect(parsed.items.single.reportCode, 'AVOV-S44-XYZ');
    expect(parsed.items.single.testSessionId, 44);
  });

  testWidgets('muestra estado vacío', (tester) async {
    final repo = _FakeHistoryRepo(
      page: const ReportHistoryPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
        pages: 0,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentReportsHistorySection(studentId: 10),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reports-history-empty')), findsOneWidget);
    expect(find.byKey(StudentReportsHistorySection.historyIntroKey), findsOneWidget);
    expect(repo.listedStudentIds, [10]);
  });

  testWidgets(
    'AUD-01: claves únicas con dos informes de la misma sesión',
    (tester) async {
      const sharedSessionId = 77;
      final sameSessionPage = ReportHistoryPage(
        items: [
          ReportHistoryItem(
            id: 101,
            studentId: 10,
            testSessionId: sharedSessionId,
            reportCode: 'AVOV-S77-AAA',
            generatedBy: 1,
            createdAt: DateTime.utc(2026, 4, 2, 10, 0),
            updatedAt: DateTime.utc(2026, 4, 2, 10, 0),
          ),
          ReportHistoryItem(
            id: 100,
            studentId: 10,
            testSessionId: sharedSessionId,
            reportCode: 'AVOV-S77-BBB',
            generatedBy: 1,
            createdAt: DateTime.utc(2026, 4, 1, 9, 0),
            updatedAt: DateTime.utc(2026, 4, 1, 9, 0),
          ),
        ],
        total: 2,
        page: 1,
        pageSize: 20,
        pages: 1,
      );
      final repo = _FakeHistoryRepo(page: sameSessionPage);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudentReportsHistorySection(
                  studentId: 10,
                  saver: ({required bytes, required filename}) async => filename,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const keyA = ValueKey('download-pdf-report-101-session-77');
      const keyB = ValueKey('download-pdf-report-100-session-77');
      expect(find.byKey(keyA), findsOneWidget);
      expect(find.byKey(keyB), findsOneWidget);
      expect(keyA, isNot(equals(keyB)));
      // La clave por solo sessionId colisionaría; no debe usarse aquí.
      expect(
        find.byKey(const ValueKey('download-pdf-$sharedSessionId')),
        findsNothing,
      );

      // Rebuild del mismo árbol: claves estables y sin colisión.
      await tester.pump();
      expect(find.byKey(keyA), findsOneWidget);
      expect(find.byKey(keyB), findsOneWidget);
      expect(find.text('Descargar PDF vigente'), findsNWidgets(2));

      await tester.tap(find.byKey(keyA));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.downloadedSessions, [sharedSessionId]);
      expect(find.textContaining('CODE-$sharedSessionId'), findsOneWidget);
    },
  );

  testWidgets(
    'aclara PDF vigente de sesión y descarga con flujo existente',
    (tester) async {
      final repo = _FakeHistoryRepo(page: samplePage);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudentReportsHistorySection(
                  studentId: 10,
                  saver: ({required bytes, required filename}) async => filename,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AVOV-S55-ABC'), findsOneWidget);
      expect(find.text('AVOV-S44-XYZ'), findsOneWidget);
      expect(
        find.textContaining('PDF vigente de la sesión'),
        findsWidgets,
      );
      expect(
        find.text(StudentReportsHistorySection.sessionDownloadNote),
        findsNWidgets(2),
      );
      expect(find.text('Descargar PDF vigente'), findsNWidgets(2));
      expect(find.text('Descargar PDF'), findsNothing);

      await tester.tap(find.text('Descargar PDF vigente').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.downloadedSessions, [55]);
      expect(find.textContaining('CODE-55'), findsOneWidget);
    },
  );

  testWidgets('muestra error y permite reintentar', (tester) async {
    final repo = _FakeHistoryRepo(
      error: AppException('No tienes permisos para acceder a este recurso.'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentReportsHistorySection(studentId: 99),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('permisos'), findsOneWidget);

    repo
      ..error = null
      ..page = const ReportHistoryPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
        pages: 0,
      );
    await tester.tap(find.byKey(const ValueKey('reports-history-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reports-history-empty')), findsOneWidget);
    expect(repo.listedStudentIds.length, greaterThanOrEqualTo(2));
  });
}
