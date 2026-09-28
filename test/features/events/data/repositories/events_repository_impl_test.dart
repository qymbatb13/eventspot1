import 'package:eventspot/core/error/exceptions.dart';
import 'package:eventspot/core/error/failures.dart';
import 'package:eventspot/features/events/data/datasources/events_remote_data_source.dart';
import 'package:eventspot/features/events/data/models/events_page_model.dart';
import 'package:eventspot/features/events/data/repositories/events_repository_impl.dart';
import 'package:eventspot/features/events/domain/entities/event_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventsRemoteDataSource extends Mock implements EventsRemoteDataSource {}

void main() {
  late MockEventsRemoteDataSource remoteDataSource;
  late EventsRepositoryImpl repository;

  const tFilters = EventFilters();

  setUp(() {
    remoteDataSource = MockEventsRemoteDataSource();
    repository = EventsRepositoryImpl(remoteDataSource: remoteDataSource);

    registerFallbackValue(tFilters);
  });

  void stubFetch(Future<EventsPageModel> Function() answer) {
    when(
      () => remoteDataSource.fetchEvents(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) => answer());
  }

  test('returns Right(EventsPage) when the data source succeeds', () async {
    stubFetch(
      () async => EventsPageModel.fromJson({
        '_embedded': {'events': <dynamic>[]},
        'page': {'number': 0, 'totalPages': 1},
      }),
    );

    final result = await repository.getEvents(latitude: 1, longitude: 1, filters: tFilters);

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected Right'),
      (page) => expect(page.pageNumber, 0),
    );
  });

  test('maps NetworkException to NetworkFailure', () async {
    stubFetch(() async => throw NetworkException());

    final result = await repository.getEvents(latitude: 1, longitude: 1, filters: tFilters);

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps ServerException to ServerFailure preserving the message', () async {
    stubFetch(() async => throw ServerException('Rate limit exceeded'));

    final result = await repository.getEvents(latitude: 1, longitude: 1, filters: tFilters);

    result.match(
      (failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Rate limit exceeded');
      },
      (_) => fail('expected Left'),
    );
  });

  test('maps unexpected exceptions to UnknownFailure instead of crashing', () async {
    stubFetch(() async => throw StateError('boom'));

    final result = await repository.getEvents(latitude: 1, longitude: 1, filters: tFilters);

    result.match(
      (failure) => expect(failure, isA<UnknownFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
