import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_entity.dart';
import 'category_style.dart';

class EventPreviewSheet extends StatelessWidget {
  const EventPreviewSheet({required this.event, super.key});

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorForCategory(event.category);
    final start = event.startDateTime;
    final dateLabel = start != null
        ? DateFormat('EEEE, d MMMM · HH:mm', 'ru').format(start)
        : 'Дата уточняется';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event.imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              ColoredBox(color: color.withAlpha(40)),
                          errorWidget: (_, __, ___) =>
                              ColoredBox(color: color.withAlpha(40)),
                        )
                      else
                        ColoredBox(
                          color: color.withAlpha(60),
                          child: Icon(
                            iconForCategory(event.category),
                            size: 64,
                            color: color,
                          ),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: _CategoryChip(category: event.category),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Text(
                          event.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.calendar_today_outlined, text: dateLabel),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.place_outlined,
                    text: '${event.venueName}, ${event.cityName}',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: event.ticketUrl == null
                          ? null
                          : () => launchUrl(
                                Uri.parse(event.ticketUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                      icon: const Icon(Icons.confirmation_number_outlined),
                      label: Text(
                        event.ticketUrl == null
                            ? 'Демо-событие'
                            : 'Билеты на Ticketmaster',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final EventCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorForCategory(category),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForCategory(category), size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
