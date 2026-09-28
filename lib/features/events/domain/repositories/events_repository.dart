import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/event_filters.dart';
import '../entities/events_page.dart';

/// Domain-facing contract. The presentation layer (via use cases) only
/// ever talks to this interface — never to Dio, Ticketmaster JSON shapes,
/// or anything else concrete. Swapping Ticketmaster for a different
/// provider means writing a new implementation of this interface only.
abstract class EventsRepository {
  Future<Either<Failure, EventsPage>> getEvents({
    required double latitude,
    required double longitude,
    required EventFilters filters,
    int page = 0,
    int pageSize = 50,
  });
}
