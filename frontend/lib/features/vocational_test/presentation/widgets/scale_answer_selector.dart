import 'package:flutter/material.dart';

class ScaleAnswerSelector extends StatelessWidget {
  const ScaleAnswerSelector({
    super.key,
    required this.selectedValue,
    required this.onSelected,
    this.enabled = true,
  });

  final int? selectedValue;
  final ValueChanged<int> onSelected;
  final bool enabled;

  static const labels = {
    1: 'No me gusta nada',
    2: 'Me gusta poco',
    3: 'Me es indiferente',
    4: 'Me gusta',
    5: 'Me gusta mucho',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final value = index + 1;
        final isSelected = selectedValue == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: enabled ? () => onSelected(value) : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      '$value',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      labels[value]!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
