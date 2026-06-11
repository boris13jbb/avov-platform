import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/institution.dart';
import '../../../../router/route_names.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../providers/institution_provider.dart';

class InstitutionListScreen extends ConsumerStatefulWidget {
  const InstitutionListScreen({super.key});

  @override
  ConsumerState<InstitutionListScreen> createState() =>
      _InstitutionListScreenState();
}

class _InstitutionListScreenState extends ConsumerState<InstitutionListScreen> {
  final _searchController = TextEditingController();
  InstitutionListQuery _query = const InstitutionListQuery();
  String? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
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
        status: _statusFilter,
        clearStatus: _statusFilter == null,
      );
    });
  }

  void _setStatusFilter(String? value) {
    setState(() {
      _statusFilter = value;
      _query = _query.copyWith(
        page: 1,
        status: value,
        clearStatus: value == null,
      );
    });
  }

  void _goToPage(int page) {
    setState(() {
      _query = _query.copyWith(page: page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(institutionListProvider(_query));

    return DashboardShell(
      title: 'Instituciones',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.adminInstitutionNew),
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
                          labelText: 'Buscar',
                          hintText: 'Nombre, código, ciudad...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applySearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Buscar',
                      onPressed: _applySearch,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'ACTIVE',
                            child: Text('Activas'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'INACTIVE',
                            child: Text('Inactivas'),
                          ),
                        ],
                        onChanged: _setStatusFilter,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(institutionListProvider(_query));
                await ref.read(institutionListProvider(_query).future);
              },
              child: listAsync.when(
                data: (data) {
                  if (data.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text('No se encontraron instituciones'),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: data.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final institution = data.items[index];
                      return _InstitutionCard(
                        institution: institution,
                        onTap: () => context.push(
                          RouteNames.adminInstitutionDetail(institution.id),
                        ),
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
                          const Text('No se pudieron cargar las instituciones'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(institutionListProvider(_query)),
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
              onPrevious: data.page > 1
                  ? () => _goToPage(data.page - 1)
                  : null,
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

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({
    required this.institution,
    required this.onTap,
  });

  final Institution institution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = institution.status == InstitutionStatus.active;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  institution.code.length >= 2
                      ? institution.code.substring(0, 2)
                      : institution.code,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institution.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${institution.city}, ${institution.province}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Código: ${institution.code}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  institution.status.label,
                  style: const TextStyle(fontSize: 12),
                ),
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
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
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
