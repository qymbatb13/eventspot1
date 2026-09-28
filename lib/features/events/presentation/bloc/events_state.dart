part of 'events_bloc.dart';

sealed class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

final class EventsInitial extends EventsState {
  const EventsInitial();
}

final class EventsLoading extends EventsState {
  const EventsLoading(this.filters);

  final EventFilters filters;

  @override
  List<Object?> get props => [filters];
}

final class EventsLoaded extends EventsState {
  const EventsLoaded({required this.events, required this.filters});

  final List<EventEntity> events;
  final EventFilters filters;

  @override
  List<Object?> get props => [events, filters];
}

final class EventsError extends EventsState {
  const EventsError({required this.message, required this.filters});

  final String message;
  final EventFilters filters;

  @override
  List<Object?> get props => [message, filters];
}
