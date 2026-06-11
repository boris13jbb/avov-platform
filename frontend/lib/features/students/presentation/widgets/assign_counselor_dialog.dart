import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/managed_user.dart';
import '../../../../core/models/user_role.dart';
import '../../../users/presentation/providers/user_provider.dart';

class AssignCounselorDialog extends ConsumerStatefulWidget {
  const AssignCounselorDialog({
    super.key,
    required this.studentName,
  });

  final String studentName;

  static Future<int?> show(
    BuildContext context, {
    required String studentName,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => AssignCounselorDialog(studentName: studentName),
    );
  }

  @override
  ConsumerState<AssignCounselorDialog> createState() =>
      _AssignCounselorDialogState();
}

class _AssignCounselorDialogState extends ConsumerState<AssignCounselorDialog> {
  static final _counselorQuery = UserListQuery(
    page: 1,
    role: UserRole.counselor.apiValue,
    status: UserAccountStatus.active.apiValue,
  );

  int? _selectedCounselorId;

  @override
  Widget build(BuildContext context) {
    final counselorsAsync = ref.watch(userListProvider(_counselorQuery));

    return AlertDialog(
      title: const Text('Asignar orientador'),
      content: SizedBox(
        width: double.maxFinite,
        child: counselorsAsync.when(
          data: (data) {
            if (data.items.isEmpty) {
              return const Text(
                'No hay orientadores activos en tu institución. '
                'Crea uno desde Gestionar orientadores.',
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el orientador para ${widget.studentName}:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final counselor = data.items[index];
                      final selected = _selectedCounselorId == counselor.id;
                      return ListTile(
                        selected: selected,
                        onTap: () {
                          setState(() => _selectedCounselorId = counselor.id);
                        },
                        title: Text(counselor.fullName),
                        subtitle: Text(counselor.email),
                        dense: true,
                        trailing: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Text(
            'No se pudieron cargar los orientadores. Verifica tu conexión.',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        counselorsAsync.maybeWhen(
          data: (data) => FilledButton(
            onPressed: data.items.isEmpty || _selectedCounselorId == null
                ? null
                : () => Navigator.of(context).pop(_selectedCounselorId),
            child: const Text('Asignar'),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
