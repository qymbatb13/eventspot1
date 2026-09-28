import '../../domain/entities/events_page.dart';
import 'event_model.dart';

class EventsPageModel {
  const EventsPageModel({
    required this.events,
    required this.pageNumber,
    required this.totalPages,
  });

  factory EventsPageModel.fromJson(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final rawEvents = (embedded?['events'] as List<dynamic>?) ?? const [];
    final page = json['page'] as Map<String, dynamic>? ?? const {};

    final parsedEvents = rawEvents
        .cast<Map<String, dynamic>>()
        .map(EventModel.tryParse)
        .whereType<EventModel>() // drop events without usable coordinates
        .toList();

    return EventsPageModel(
      events: parsedEvents,
      pageNumber: (page['number'] as num?)?.toInt() ?? 0,
      totalPages: (page['totalPages'] as num?)?.toInt() ?? (parsedEvents.isEmpty ? 0 : 1),
    );
  }

  final List<EventModel> events;
  final int pageNumber;
  final int totalPages;

  EventsPage toEntity() => EventsPage(
        events: events.map((e) => e.toEntity()).toList(),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}
