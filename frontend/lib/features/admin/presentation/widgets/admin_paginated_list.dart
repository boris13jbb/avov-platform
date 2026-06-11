import 'package:flutter/material.dart';

class AdminPaginatedList<T> extends StatelessWidget {
  const AdminPaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.page,
    required this.pages,
    required this.onPageChanged,
    this.emptyMessage = 'No hay registros para mostrar.',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int page;
  final int pages;
  final ValueChanged<int> onPageChanged;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index]);
            },
          ),
        ),
        if (pages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Página $page de $pages'),
                IconButton(
                  onPressed:
                      page < pages ? () => onPageChanged(page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
