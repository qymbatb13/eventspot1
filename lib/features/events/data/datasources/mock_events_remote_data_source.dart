import 'dart:math' as math;

import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_filters.dart';
import '../models/event_model.dart';
import '../models/events_page_model.dart';
import 'events_remote_data_source.dart';

/// Demo data source: generates plausible events around any point in the
/// world with no network and no API keys.
///
/// The world is split into ~20 km cells. Each cell deterministically
/// produces its own set of events (the seed depends only on the cell
/// coordinates), so events don't "jump" when the map is moved, and
/// searching the same area always gives the same result.
class MockEventsRemoteDataSource implements EventsRemoteDataSource {
  MockEventsRemoteDataSource({
    this.latency = const Duration(milliseconds: 500),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Simulated network latency so loading states are visible.
  final Duration latency;
  final DateTime Function() _clock;

  static const double _cellSizeDegrees = 0.2;

  static const Map<EventCategory, List<String>> _names = {
    EventCategory.music: [
      'Летний рок-фестиваль',
      'Вечер живого джаза',
      'Симфонический оркестр',
      'Электронная ночь',
      'Концерт инди-групп',
      'Акустический вечер',
      'Хип-хоп батл',
      'Оперный гала-концерт',
    ],
    EventCategory.sports: [
      'Городской футбольный дерби',
      'Баскетбольный турнир',
      'Забег на 10 км',
      'Хоккейный матч',
      'Турнир по теннису',
      'Кубок по боксу',
      'Марафон выходного дня',
      'Соревнования по борьбе',
    ],
    EventCategory.artsAndTheatre: [
      'Балет «Лебединое озеро»',
      'Спектакль «Ревизор»',
      'Стендап-вечер',
      'Мюзикл для всей семьи',
      'Выставка современного искусства',
      'Театр кукол',
      'Опера «Кармен»',
      'Вечер поэзии и музыки',
    ],
    EventCategory.film: [
      'Ночь короткометражек',
      'Фестиваль документального кино',
      'Кинопоказ под открытым небом',
      'Ретроспектива классики',
      'Премьера авторского кино',
      'Мультфильмы для детей',
    ],
    EventCategory.miscellaneous: [
      'Ярмарка ремесленников',
      'Гастрономический фестиваль',
      'Фестиваль настольных игр',
      'Мастер-класс по керамике',
      'Ночной рынок',
      'Технологическая встреча',
      'Фестиваль уличной еды',
      'Книжный фестиваль',
    ],
  };

  static const Map<EventCategory, List<String>> _venues = {
    EventCategory.music: [
      'Клуб «Ритм»',
      'Концертный зал',
      'Открытая сцена в парке',
      'Дом культуры',
    ],
    EventCategory.sports: [
      'Центральный стадион',
      'Спорткомплекс «Арена»',
      'Ледовый дворец',
      'Городской парк',
    ],
    EventCategory.artsAndTheatre: [
      'Драматический театр',
      'Театр оперы и балета',
      'Дом художников',
      'Театр кукол',
    ],
    EventCategory.film: [
      'Кинотеатр «Мир»',
      'Арт-хаус кинотеатр',
      'Летний кинотеатр',
    ],
    EventCategory.miscellaneous: [
      'Парк культуры',
      'Выставочный центр',
      'Коворкинг-холл',
      'Городская площадь',
    ],
  };

  @override
  Future<EventsPageModel> fetchEvents({
    required double latitude,
    required double longitude,
    required EventFilters filters,
    required int page,
    required int pageSize,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }

    final radiusKm = math.min(math.max(filters.radiusKm, 1.0), 100.0);
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);

    // Cells intersected by the square around the search point.
    final latDelta = radiusKm / 111.0;
    final lngDelta =
        radiusKm / (111.0 * math.max(math.cos(_rad(latitude)), 0.01));
    final minCellY = ((latitude - latDelta) / _cellSizeDegrees).floor();
    final maxCellY = ((latitude + latDelta) / _cellSizeDegrees).floor();
    final minCellX = ((longitude - lngDelta) / _cellSizeDegrees).floor();
    final maxCellX = ((longitude + lngDelta) / _cellSizeDegrees).floor();

    final all = <EventModel>[];
    for (var cy = minCellY; cy <= maxCellY; cy++) {
      for (var cx = minCellX; cx <= maxCellX; cx++) {
        all.addAll(_eventsForCell(cx, cy, today));
      }
    }

    final keyword = filters.keyword?.trim().toLowerCase();
    final filtered = all.where((event) {
      if (filters.category != null && event.category != filters.category) {
        return false;
      }
      if (keyword != null &&
          keyword.isNotEmpty &&
          !event.name.toLowerCase().contains(keyword)) {
        return false;
      }
      final start = event.startDateTime;
      if (start != null) {
        if (filters.startDate != null && start.isBefore(filters.startDate!)) {
          return false;
        }
        if (filters.endDate != null && start.isAfter(filters.endDate!)) {
          return false;
        }
      }
      return _distanceKm(latitude, longitude, event.latitude, event.longitude) <=
          radiusKm;
    }).toList()
      ..sort(
        (a, b) => (a.startDateTime ?? today).compareTo(b.startDateTime ?? today),
      );

    final totalPages = filtered.isEmpty ? 0 : (filtered.length / pageSize).ceil();
    final from = page * pageSize;
    final pageItems = from >= filtered.length
        ? <EventModel>[]
        : filtered.sublist(from, math.min(from + pageSize, filtered.length));

    return EventsPageModel(
      events: pageItems,
      pageNumber: page,
      totalPages: totalPages,
    );
  }

  List<EventModel> _eventsForCell(int cx, int cy, DateTime today) {
    final random = math.Random(_seedFor(cx, cy));
    final events = <EventModel>[];
    var index = 0;

    // "Hotspots": several events at one venue — they form natural
    // clusters on the map.
    final hotspotCount = 1 + random.nextInt(2);
    for (var h = 0; h < hotspotCount; h++) {
      final centerLat = (cy + random.nextDouble()) * _cellSizeDegrees;
      final centerLng = (cx + random.nextDouble()) * _cellSizeDegrees;
      final venueCategory = _randomCategory(random);
      final venueName = _pick(random, _venues[venueCategory]!);

      final eventsHere = 2 + random.nextInt(4);
      for (var i = 0; i < eventsHere; i++) {
        final category =
            random.nextDouble() < 0.7 ? venueCategory : _randomCategory(random);
        events.add(
          _buildEvent(
            random: random,
            id: 'mock-$cx-$cy-${index++}',
            category: category,
            venueName: venueName,
            // Small spread (~100 m) so markers don't overlap at max zoom.
            latitude: centerLat + (random.nextDouble() - 0.5) * 0.002,
            longitude: centerLng + (random.nextDouble() - 0.5) * 0.002,
            today: today,
          ),
        );
      }
    }

    // Single events scattered across the cell.
    final scatteredCount = 1 + random.nextInt(3);
    for (var i = 0; i < scatteredCount; i++) {
      final category = _randomCategory(random);
      events.add(
        _buildEvent(
          random: random,
          id: 'mock-$cx-$cy-${index++}',
          category: category,
          venueName: _pick(random, _venues[category]!),
          latitude: (cy + random.nextDouble()) * _cellSizeDegrees,
          longitude: (cx + random.nextDouble()) * _cellSizeDegrees,
          today: today,
        ),
      );
    }

    return events;
  }

  EventModel _buildEvent({
    required math.Random random,
    required String id,
    required EventCategory category,
    required String venueName,
    required double latitude,
    required double longitude,
    required DateTime today,
  }) {
    final dayOffset = random.nextInt(30);
    final hour = 10 + random.nextInt(12);
    final minute = random.nextBool() ? 0 : 30;

    return EventModel(
      id: id,
      name: _pick(random, _names[category]!),
      category: category,
      venueName: venueName,
      cityName: 'Рядом с вами',
      latitude: latitude,
      longitude: longitude,
      // Random photos from picsum.photos (free, no key). If an image
      // fails to load, the card shows a placeholder.
      imageUrl: 'https://picsum.photos/seed/$id/600/400',
      startDateTime: today.add(
        Duration(days: dayOffset, hours: hour, minutes: minute),
      ),
    );
  }

  int _seedFor(int cx, int cy) => ((cx * 73856093) ^ (cy * 19349663)) & 0x7fffffff;

  EventCategory _randomCategory(math.Random random) =>
      EventCategory.values[random.nextInt(EventCategory.values.length)];

  T _pick<T>(math.Random random, List<T> items) =>
      items[random.nextInt(items.length)];

  double _rad(double degrees) => degrees * math.pi / 180;

  /// Great-circle distance between two points (haversine), km.
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final a = sinLat * sinLat +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * sinLng * sinLng;
    return 2 * earthRadiusKm * math.asin(math.min(1.0, math.sqrt(a)));
  }
}
