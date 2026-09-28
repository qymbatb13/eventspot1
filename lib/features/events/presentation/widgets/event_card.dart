import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event_entity.dart';
import 'category_style.dart';

class EventCard extends StatelessWidget {
  const EventCard({required this.event, this.onTap, super.key});

  final EventEntity event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorForCategory(event.category);
    final start = event.startDateTime;
    final dateLabel = start != null
        ? DateFormat('d MMM, HH:mm', 'ru').format(start)
        : 'Дата уточняется';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              Container(width: 4, color: color),
              SizedBox(
                width: 96,
                height: 112,
                child: event.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            ColoredBox(color: color.withAlpha(40)),
                        errorWidget: (_, __, ___) => const Icon(Icons.event),
                      )
                    : ColoredBox(
                        color: color.withAlpha(40),
                        child: const Icon(Icons.event),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$dateLabel · ${event.venueName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(event.cityName, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
