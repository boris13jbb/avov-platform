import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/managed_user.dart';
import '../../../../core/models/student.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../domain/student_management_config.dart';
import '../providers/student_provider.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key, required this.config});

  final StudentManagementConfig config;

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _searchController = TextEditingController();
  final _gradeController = TextEditingController();
  StudentListQuery _query = const StudentListQuery();
  String? _statusFilter;
  String? _genderFilter;

  @override
  void dispose() {
    _searchController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {
      _query = _query.copyWith(
        page: 1,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        clearSearch: _searchController.text.trim().isEmpty,
        grade: _gradeController.text.trim().isEmpty
            ? null
            : _gradeController.text.trim(),
        clearGrade: _gradeController.text.trim().isEmpty,
      );
    });
  }

  void _setStatusFilter(String? value) {
    setState(() {
      _statusFilter = value;
      _query = _query.copyWith(page: 1, status: value, clearStatus: value == null);
    });
  }

  void _setGenderFilter(String? value) {
    setState(() {
      _genderFilter = value;
      _query = _query.copyWith(page: 1, gender: value, clearGender: value == null);
    });
  }

  void _goToPage(int page) {
    setState(() => _query = _query.copyWith(page: page));
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(studentListProvider(_query));

    return DashboardShell(
      title: widget.config.listTitle,
      floatingActionButton: widget.config.canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push(widget.config.newRoute()),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Nuevo'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar',
                          hintText: 'Nombre, email o identificación',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applySearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _applySearch,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _gradeController,
                  decoration: const InputDecoration(
                    labelText: 'Grado / curso',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applySearch(),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    DropdownMenuItem<String?>(
                      value: 'ACTIVE',
                      child: Text('Activos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'INACTIVE',
                      child: Text('Inactivos'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'BLOCKED',
                      child: Text('Bloqueados'),
                    ),
                  ],
                  onChanged: _setStatusFilter,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _genderFilter,
                  decoration: const InputDecoration(
                    labelText: 'Género',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...StudentGender.values.map(
                      (gender) => DropdownMenuItem<String?>(
                        value: gender.apiValue,
                        child: Text(gender.label),
                      ),
                    ),
                  ],
                  onChanged: _setGenderFilter,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentListProvider(_query));
                await ref.read(studentListProvider(_query).future);
              },
              child: listAsync.when(
                data: (data) {
                  if (data.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No se encontraron estudiantes')),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: data.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = data.items[index];
                      return _StudentCard(
                        student: student,
                        onTap: () =>
                            context.push(widget.config.detailRoute(student.id)),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Column(
                        children: [
                          const Text('No se pudieron cargar los estudiantes'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(studentListProvider(_query)),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          listAsync.maybeWhen(
            data: (data) => _PaginationBar(
              page: data.page,
              totalPages: data.pages,
              total: data.total,
              onPrevious:
                  data.page > 1 ? () => _goToPage(data.page - 1) : null,
              onNext: data.page < data.pages
                  ? () => _goToPage(data.page + 1)
                  : null,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onTap});

  final ManagedStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = student.user.status == UserAccountStatus.active;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  student.user.firstName.isNotEmpty
                      ? student.user.firstName[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'ID: ${student.identification} · ${student.grade}${student.parallel != null ? " ${student.parallel}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(student.user.status.label),
                backgroundColor: isActive
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.2),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: $total'),
            Text('Página $page de ${totalPages == 0 ? 1 : totalPages}'),
            Row(
              children: [
                IconButton(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
