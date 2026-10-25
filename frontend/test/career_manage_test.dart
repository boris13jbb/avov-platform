import 'package:avov_frontend/features/careers/domain/career.dart';
import 'package:avov_frontend/features/careers/domain/career_repository.dart';
import 'package:avov_frontend/features/careers/presentation/providers/career_provider.dart';
import 'package:avov_frontend/features/careers/presentation/screens/career_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sample = Career(
    id: 7,
    name: 'Ingeniería en Sistemas',
    area: 'Tecnología',
    description: 'Carrera orientada al desarrollo de software.',
    riasecProfile: 'IRC',
    degreeType: 'INGENIERIA',
    institutionType: 'AMBAS',
    employmentField: 'Desarrollo de software',
    status: 'ACTIVE',
  );

  testWidgets('el listado de carreras muestra nombre y estado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careerRepositoryProvider.overrideWithValue(_MemoryRepo(items: const [sample])),
        ],
        child: const MaterialApp(home: CareerListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ingeniería en Sistemas'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
  });
}

class _MemoryRepo implements CareerRepository {
  _MemoryRepo({this.items = const []});

  final List<Career> items;

  @override
  Future<CareerPage> list({
    required int page,
    required int pageSize,
    String? search,
    String? area,
    String? status,
  }) async {
    return CareerPage(
      items: items,
      total: items.length,
      page: 1,
      pages: items.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<Career> getById(int id) => throw UnimplementedError();

  @override
  Future<Career> create(CareerDraft draft) => throw UnimplementedError();

  @override
  Future<Career> update(int id, CareerDraft draft) => throw UnimplementedError();

  @override
  Future<Career> deactivate(int id) => throw UnimplementedError();
}
