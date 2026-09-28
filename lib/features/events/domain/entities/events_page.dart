import 'package:equatable/equatable.dart';

import 'event_entity.dart';

/// One page of events plus enough pagination metadata for a "load more"
/// flow, without leaking Ticketmaster's `page.number` / `page.totalPages`
/// naming into callers.
class EventsPage extends Equatable {
  const EventsPage({
    required this.events,
    required this.pageNumber,
    required this.totalPages,
  });

  final List<EventEntity> events;
  final int pageNumber;
  final int totalPages;

  bool get hasMore => pageNumber + 1 < totalPages;

  @override
  List<Object?> get props => [events, pageNumber, totalPages];
}
