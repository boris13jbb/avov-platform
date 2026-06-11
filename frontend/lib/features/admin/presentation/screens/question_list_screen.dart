import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/question.dart';
import '../../../../router/route_names.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_paginated_list.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() =>
      _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  final _searchController = TextEditingController();
  AdminListQuery _query = const AdminListQuery();
  String? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _query = _query.copyWith(
        page: 1,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        clearSearch: _searchController.text.trim().isEmpty,
        filter: _statusFilter,
        clearFilter: _statusFilter == null,
      );
    });
  }

  void _setStatusFilter(String? value) {
    setState(() {
      _statusFilter = value;
      _query = _query.copyWith(
        page: 1,
        filter: value,
        clearFilter: value == null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(questionListProvider(_query));

    return DashboardShell(
      title: 'Preguntas RIASEC',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.adminQuestionNew),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
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
                          labelText: 'Buscar pregunta',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: _statusFilter == null,
                      onSelected: (_) => _setStatusFilter(null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Activas'),
                      selected: _statusFilter == 'ACTIVE',
                      onSelected: (_) => _setStatusFilter('ACTIVE'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Inactivas'),
                      selected: _statusFilter == 'INACTIVE',
                      onSelected: (_) => _setStatusFilter('INACTIVE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              data: (data) {
                return AdminPaginatedList<Question>(
                  items: data.items,
                  page: data.page,
                  pages: data.pages,
                  onPageChanged: (page) =>
                      setState(() => _query = _query.copyWith(page: page)),
                  emptyMessage: 'No hay preguntas registradas.',
                  itemBuilder: (context, question) => Card(
                    child: ListTile(
                      title: Text(question.text),
                      subtitle: Text(
                        'Categoría ${question.category.code} · Orden ${question.orderNumber}',
                      ),
                      trailing: Chip(label: Text(question.status.label)),
                      onTap: () => context.push(
                        RouteNames.adminQuestionDetail(question.id),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(questionListProvider(_query)),
                  child: const Text('Reintentar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
