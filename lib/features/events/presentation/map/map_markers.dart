import 'package:flutter/material.dart';

import '../../domain/entities/event_category.dart';
import '../widgets/category_style.dart';

/// Circle with the number of events inside — a cluster marker.
class ClusterBubble extends StatelessWidget {
  const ClusterBubble({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PopIn(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: count > 99 ? 13 : 16,
          ),
        ),
      ),
    );
  }
}

/// Single-event marker: color and icon depend on the category.
class EventPin extends StatelessWidget {
  const EventPin({
    required this.category,
    this.selected = false,
    super.key,
  });

  final EventCategory category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _PopIn(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 46 : 36,
          height: selected ? 46 : 36,
          decoration: BoxDecoration(
            color: colorForCategory(category),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 4 : 3),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
          ),
          child: Icon(
            iconForCategory(category),
            color: Colors.white,
            size: selected ? 24 : 19,
          ),
        ),
      ),
    );
  }
}

/// Small "pop in" animation for markers.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
