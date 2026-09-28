part of 'events_bloc.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on first load and whenever the user taps "Search this area" /
/// pulls to refresh. Also remembers the location internally so filter
/// changes can re-run the same query.
final class EventsLoadForLocation extends EventsEvent {
  const EventsLoadForLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

final class EventsCategoryFilterChanged extends EventsEvent {
  const EventsCategoryFilterChanged(this.category);

  /// `null` clears the filter (shows all categories).
  final EventCategory? category;

  @override
  List<Object?> get props => [category];
}

final class EventsRadiusFilterChanged extends EventsEvent {
  const EventsRadiusFilterChanged(this.radiusKm);

  final double radiusKm;

  @override
  List<Object?> get props => [radiusKm];
}

final class EventsRetryRequested extends EventsEvent {
  const EventsRetryRequested();
}
