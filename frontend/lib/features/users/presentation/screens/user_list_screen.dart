import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/managed_user.dart';
import '../../../dashboard/presentation/widgets/dashboard_shell.dart';
import '../../domain/user_management_config.dart';
import '../providers/user_provider.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key, required this.config});

  final UserManagementConfig config;

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();
  late UserListQuery _query;
  String? _roleFilter;
  String? _statusFilter;
  int? _institutionFilter;

  @override
  void initState() {
    super.initState();
    _query = UserListQuery(role: widget.config.fixedRoleFilter);
    _roleFilter = widget.config.fixedRoleFilter;
  }

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
      );
    });
  }

  void _setRoleFilter(String? value) {
    setState(() {
      _roleFilter = value;
      _query = _query.copyWith(
        page: 1,
        role: value,
        clearRole: value == null,
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

  void _setInstitutionFilter(int? value) {
    setState(() {
      _institutionFilter = value;
      _query = _query.copyWith(
        page: 1,
        institutionId: value,
        clearInstitution: value == null,
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
    final listAsync = ref.watch(userListProvider(_query));
    final institutionsAsync = widget.config.showInstitutionFilter
        ? ref.watch(activeInstitutionsProvider)
        : null;

    return DashboardShell(
      title: widget.config.listTitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(widget.config.newRoute()),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo'),
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
                          hintText: 'Nombre, apellido o correo',
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
                if (widget.config.showRoleFilter)
                  DropdownButtonFormField<String?>(
                    initialValue: _roleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos los roles'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'SUPER_ADMIN',
                        child: Text('Super Admin'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'INSTITUTION_ADMIN',
                        child: Text('Admin institucional'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'COUNSELOR',
                        child: Text('Orientador'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'STUDENT',
                        child: Text('Estudiante'),
                      ),
                    ],
                    onChanged: _setRoleFilter,
                  ),
                if (widget.config.showRoleFilter) const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
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
                if (widget.config.showInstitutionFilter &&
                    institutionsAsync != null) ...[
                  const SizedBox(height: 8),
                  institutionsAsync.when(
                    data: (institutions) =>
                        DropdownButtonFormField<int?>(
                      initialValue: _institutionFilter,
                      decoration: const InputDecoration(
                        labelText: 'Institución',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ...institutions.map(
                          (institution) => DropdownMenuItem<int?>(
                            value: institution.id,
                            child: Text(institution.name),
                          ),
                        ),
                      ],
                      onChanged: _setInstitutionFilter,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userListProvider(_query));
                await ref.read(userListProvider(_query).future);
              },
              child: listAsync.when(
                data: (data) {
                  if (data.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No se encontraron usuarios')),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: data.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = data.items[index];
                      return _UserCard(
                        user: user,
                        onTap: () => context.push(
                          widget.config.detailRoute(user.id),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Column(
                        children: [
                          const Text('No se pudieron cargar los usuarios'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(userListProvider(_query)),
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

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final ManagedUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == UserAccountStatus.active;

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
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      user.role.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  user.status.label,
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
