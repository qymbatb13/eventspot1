import 'package:eventspot/features/events/data/datasources/mock_events_remote_data_source.dart';
import 'package:eventspot/features/events/data/models/events_page_model.dart';
import 'package:eventspot/features/events/domain/entities/event_category.dart';
import 'package:eventspot/features/events/domain/entities/event_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockEventsRemoteDataSource dataSource;

  setUp(() {
    dataSource = MockEventsRemoteDataSource(
      latency: Duration.zero,
      clock: () => DateTime(2026, 9, 28, 12),
    );
  });

  Future<EventsPageModel> fetch({
    EventFilters filters = const EventFilters(),
    int page = 0,
    int pageSize = 500,
  }) {
    return dataSource.fetchEvents(
      latitude: 43.22,
      longitude: 76.85,
      filters: filters,
      page: page,
      pageSize: pageSize,
    );
  }

  test('generates events around the requested location', () async {
    final result = await fetch();
    expect(result.events, isNotEmpty);
  });

  test('is deterministic: same area gives the same events', () async {
    final first = await fetch();
    final second = await fetch();
    expect(
      first.events.map((e) => e.id).toList(),
      second.events.map((e) => e.id).toList(),
    );
  });

  test('respects the category filter', () async {
    final result = await fetch(
      filters: const EventFilters(category: EventCategory.music),
    );
    expect(result.events, isNotEmpty);
    expect(result.events.every((e) => e.category == EventCategory.music), isTrue);
  });

  test('a smaller radius returns a subset of a larger radius', () async {
    final small = await fetch(filters: const EventFilters(radiusKm: 5));
    final large = await fetch(filters: const EventFilters(radiusKm: 50));

    final smallIds = small.events.map((e) => e.id).toSet();
    final largeIds = large.events.map((e) => e.id).toSet();

    expect(smallIds.difference(largeIds), isEmpty);
    expect(small.events.length, lessThan(large.events.length));
  });

  test('filters by keyword, case-insensitively', () async {
    final result = await fetch(filters: const EventFilters(keyword: 'ДЖАЗ'));
    expect(
      result.events.every((e) => e.name.toLowerCase().contains('джаз')),
      isTrue,
    );
  });

  test('paginates results', () async {
    final page0 = await fetch(pageSize: 5);
    expect(page0.events, hasLength(5));
    expect(page0.totalPages, greaterThan(1));

    final page1 = await fetch(pageSize: 5, page: 1);
    final overlap = page0.events.map((e) => e.id).toSet().intersection(
          page1.events.map((e) => e.id).toSet(),
        );
    expect(overlap, isEmpty);
  });
}
