import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/event_filters.dart';
import '../entities/events_page.dart';
import '../repositories/events_repository.dart';

class GetEventsParams extends Equatable {
  const GetEventsParams({
    required this.latitude,
    required this.longitude,
    this.filters = const EventFilters(),
    this.page = 0,
    this.pageSize = 50,
  });

  final double latitude;
  final double longitude;
  final EventFilters filters;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [latitude, longitude, filters, page, pageSize];
}

/// Fetches one page of events near a location, respecting the active
/// [EventFilters]. This is the only entry point the presentation layer
/// uses to read events — it never talks to [EventsRepository] directly.
class GetEvents implements UseCase<EventsPage, GetEventsParams> {
  GetEvents(this._repository);

  final EventsRepository _repository;

  @override
  Future<Either<Failure, EventsPage>> call(GetEventsParams params) {
    return _repository.getEvents(
      latitude: params.latitude,
      longitude: params.longitude,
      filters: params.filters,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
