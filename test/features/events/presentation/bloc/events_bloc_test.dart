import 'package:bloc_test/bloc_test.dart';
import 'package:eventspot/core/error/failures.dart';
import 'package:eventspot/features/events/domain/entities/event_category.dart';
import 'package:eventspot/features/events/domain/entities/events_page.dart';
import 'package:eventspot/features/events/domain/usecases/get_events.dart';
import 'package:eventspot/features/events/presentation/bloc/events_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetEvents extends Mock implements GetEvents {}

void main() {
  late MockGetEvents getEvents;

  const tPage = EventsPage(events: [], pageNumber: 0, totalPages: 1);

  setUpAll(() {
    registerFallbackValue(
      const GetEventsParams(latitude: 0, longitude: 0),
    );
  });

  setUp(() {
    getEvents = MockGetEvents();
  });

  blocTest<EventsBloc, EventsState>(
    'emits [Loading, Loaded] when EventsLoadForLocation succeeds',
    setUp: () {
      when(() => getEvents(any())).thenAnswer((_) async => const Right(tPage));
    },
    build: () => EventsBloc(getEvents: getEvents),
    act: (bloc) => bloc.add(const EventsLoadForLocation(latitude: 43.22, longitude: 76.85)),
    expect: () => [
      isA<EventsLoading>(),
      isA<EventsLoaded>().having((s) => s.events, 'events', isEmpty),
    ],
  );

  blocTest<EventsBloc, EventsState>(
    'emits [Loading, Error] when the use case returns a Failure',
    setUp: () {
      when(() => getEvents(any())).thenAnswer((_) async => const Left(NetworkFailure()));
    },
    build: () => EventsBloc(getEvents: getEvents),
    act: (bloc) => bloc.add(const EventsLoadForLocation(latitude: 43.22, longitude: 76.85)),
    expect: () => [
      isA<EventsLoading>(),
      isA<EventsError>().having((s) => s.message, 'message', const NetworkFailure().message),
    ],
  );

  blocTest<EventsBloc, EventsState>(
    'a category filter change re-queries using the last known location',
    setUp: () {
      when(() => getEvents(any())).thenAnswer((_) async => const Right(tPage));
    },
    build: () => EventsBloc(getEvents: getEvents),
    act: (bloc) async {
      bloc.add(const EventsLoadForLocation(latitude: 43.22, longitude: 76.85));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const EventsCategoryFilterChanged(EventCategory.music));
    },
    verify: (_) {
      final captured = verify(() => getEvents(captureAny())).captured;
      final lastParams = captured.last as GetEventsParams;
      expect(lastParams.latitude, 43.22);
      expect(lastParams.longitude, 76.85);
      expect(lastParams.filters.category, EventCategory.music);
    },
  );

  blocTest<EventsBloc, EventsState>(
    'a filter change before any location is resolved does nothing',
    build: () => EventsBloc(getEvents: getEvents),
    act: (bloc) => bloc.add(const EventsCategoryFilterChanged(EventCategory.sports)),
    expect: () => <EventsState>[],
    verify: (_) => verifyNever(() => getEvents(any())),
  );
}
