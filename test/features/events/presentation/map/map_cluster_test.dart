import 'package:eventspot/features/events/domain/entities/event_category.dart';
import 'package:eventspot/features/events/domain/entities/event_entity.dart';
import 'package:eventspot/features/events/presentation/map/map_cluster.dart';
import 'package:flutter_test/flutter_test.dart';

EventEntity _event(String id, double lat, double lng) => EventEntity(
      id: id,
      name: 'Event $id',
      category: EventCategory.music,
      venueName: 'Venue',
      cityName: 'City',
      latitude: lat,
      longitude: lng,
    );

void main() {
  late ClusteringService service;

  setUp(() => service = ClusteringService());

  test('returns an empty list for no events', () {
    expect(service.cluster(const [], 10), isEmpty);
  });

  test('groups two nearby events into a single cluster at low zoom', () {
    final events = [
      _event('a', 43.2220, 76.8512),
      _event('b', 43.2221, 76.8513), // ~15m away
    ];

    final clusters = service.cluster(events, 10);

    expect(clusters, hasLength(1));
    expect(clusters.single.isCluster, isTrue);
    expect(clusters.single.events, hasLength(2));
  });

  test('keeps far-apart events as separate clusters at the same zoom', () {
    final events = [
      _event('almaty', 43.2220, 76.8512),
      _event('astana', 51.1694, 71.4491), // different city entirely
    ];

    final clusters = service.cluster(events, 10);

    expect(clusters, hasLength(2));
    expect(clusters.every((c) => !c.isCluster), isTrue);
  });

  test('never clusters above the no-cluster zoom threshold, even if identical', () {
    final events = [
      _event('a', 43.2220, 76.8512),
      _event('b', 43.2220, 76.8512),
    ];

    final clusters = service.cluster(events, ClusteringService.noClusterZoomThreshold);

    expect(clusters, hasLength(2));
    expect(clusters.every((c) => !c.isCluster), isTrue);
  });

  test('cluster centroid is the average position of its members', () {
    final events = [
      _event('a', 10.0, 20.0),
      _event('b', 10.002, 20.002),
    ];

    final clusters = service.cluster(events, 8);

    expect(clusters, hasLength(1));
    expect(clusters.single.latitude, closeTo(10.001, 0.0005));
    expect(clusters.single.longitude, closeTo(20.001, 0.0005));
  });
}
