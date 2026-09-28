import 'package:eventspot/core/error/failures.dart';
import 'package:eventspot/features/events/domain/entities/event_filters.dart';
import 'package:eventspot/features/events/domain/entities/events_page.dart';
import 'package:eventspot/features/events/domain/repositories/events_repository.dart';
import 'package:eventspot/features/events/domain/usecases/get_events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  late MockEventsRepository repository;
  late GetEvents usecase;

  setUp(() {
    repository = MockEventsRepository();
    usecase = GetEvents(repository);
  });

  const tFilters = EventFilters(radiusKm: 25);
  const tParams = GetEventsParams(latitude: 43.22, longitude: 76.85, filters: tFilters);
  const tPage = EventsPage(events: [], pageNumber: 0, totalPages: 1);

  test('delegates to the repository with the exact params it was given', () async {
    when(
      () => repository.getEvents(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => const Right(tPage));

    final result = await usecase(tParams);

    expect(result, const Right<Failure, EventsPage>(tPage));
    verify(
      () => repository.getEvents(
        latitude: 43.22,
        longitude: 76.85,
        filters: tFilters,
        page: 0,
        pageSize: 50,
      ),
    ).called(1);
  });

  test('propagates a Failure from the repository unchanged', () async {
    when(
      () => repository.getEvents(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await usecase(tParams);

    expect(result, const Left<Failure, EventsPage>(NetworkFailure()));
  });
}
