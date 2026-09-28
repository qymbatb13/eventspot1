import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_filters.dart';
import '../../domain/usecases/get_events.dart';

part 'events_event.dart';
part 'events_state.dart';

/// Single BLoC shared by the map screen and (in a later iteration) a list
/// screen. It owns the last-known map location and the active
/// [EventFilters] internally so that a bare filter change can re-issue the
/// same geo query without the UI having to remember/re-pass coordinates.
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc({required GetEvents getEvents})
      : _getEvents = getEvents,
        super(const EventsInitial()) {
    on<EventsLoadForLocation>(_onLoadForLocation);
    on<EventsCategoryFilterChanged>(_onCategoryFilterChanged);
    on<EventsRadiusFilterChanged>(_onRadiusFilterChanged);
    on<EventsRetryRequested>(_onRetryRequested);
  }

  final GetEvents _getEvents;

  double? _lastLatitude;
  double? _lastLongitude;
  EventFilters _filters = const EventFilters();

  Future<void> _onLoadForLocation(
    EventsLoadForLocation event,
    Emitter<EventsState> emit,
  ) async {
    _lastLatitude = event.latitude;
    _lastLongitude = event.longitude;
    await _fetch(emit);
  }

  Future<void> _onCategoryFilterChanged(
    EventsCategoryFilterChanged event,
    Emitter<EventsState> emit,
  ) async {
    _filters = _filters.copyWith(
      category: event.category,
      clearCategory: event.category == null,
    );
    await _fetch(emit);
  }

  Future<void> _onRadiusFilterChanged(
    EventsRadiusFilterChanged event,
    Emitter<EventsState> emit,
  ) async {
    _filters = _filters.copyWith(radiusKm: event.radiusKm);
    await _fetch(emit);
  }

  Future<void> _onRetryRequested(
    EventsRetryRequested event,
    Emitter<EventsState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<EventsState> emit) async {
    final latitude = _lastLatitude;
    final longitude = _lastLongitude;
    if (latitude == null || longitude == null) {
      // No location resolved yet (e.g. a filter was changed before the
      // first location fix arrived) — nothing sensible to query yet.
      return;
    }

    emit(EventsLoading(_filters));

    final result = await _getEvents(
      GetEventsParams(latitude: latitude, longitude: longitude, filters: _filters),
    );

    result.match(
      (failure) => emit(EventsError(message: failure.message, filters: _filters)),
      (page) => emit(EventsLoaded(events: page.events, filters: _filters)),
    );
  }
}
