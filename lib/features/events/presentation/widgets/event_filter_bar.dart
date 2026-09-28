import 'package:flutter/material.dart';

import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_filters.dart';

class EventFilterBar extends StatelessWidget {
  const EventFilterBar({
    required this.filters,
    required this.onCategoryChanged,
    super.key,
  });

  final EventFilters filters;
  final ValueChanged<EventCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            _CategoryChip(
              label: 'Все',
              selected: filters.category == null,
              onTap: () => onCategoryChanged(null),
            ),
            for (final category in EventCategory.values)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _CategoryChip(
                  label: category.label,
                  selected: filters.category == category,
                  onTap: () => onCategoryChanged(category),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
