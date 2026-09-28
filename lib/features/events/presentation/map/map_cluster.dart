import 'dart:math' as math;

import '../../domain/entities/event_entity.dart';

/// A group of one or more events that render as a single marker.
class MapCluster {
  const MapCluster({
    required this.latitude,
    required this.longitude,
    required this.events,
  });

  final double latitude;
  final double longitude;
  final List<EventEntity> events;

  bool get isCluster => events.length > 1;

  /// Only valid when [isCluster] is false.
  EventEntity get single => events.first;
}

/// Groups nearby events into [MapCluster]s using a simple, deterministic
/// grid-bucketing algorithm keyed by camera zoom.
///
/// Why hand-rolled instead of `google_maps_cluster_manager` / `fluster`:
/// - Zero extra native/plugin surface — one less thing that can break
///   across Flutter/Play-Services version bumps.
/// - The whole algorithm is ~20 lines of pure Dart, so it is trivially
///   unit-testable (see `map_cluster_test.dart`) without spinning up a
///   Google Maps widget or a device.
/// - It is "good enough" clustering for a demo-scale dataset (tens to a
///   few hundred markers). For a production app with tens of thousands of
///   markers, a quad-tree based approach would scale better — noted as a
///   deliberate trade-off in the README.
class ClusteringService {
  /// Above this zoom level every event gets its own marker — at that point
  /// pins are naturally spread out enough that clustering would just hide
  /// individual events the user zoomed in to see.
  static const double noClusterZoomThreshold = 15;

  List<MapCluster> cluster(List<EventEntity> events, double zoom) {
    if (events.isEmpty) return const [];

    if (zoom >= noClusterZoomThreshold) {
      return events
          .map((e) => MapCluster(latitude: e.latitude, longitude: e.longitude, events: [e]))
          .toList();
    }

    final cellSize = _cellSizeDegreesForZoom(zoom);
    final buckets = <String, List<EventEntity>>{};

    for (final event in events) {
      final cellX = (event.longitude / cellSize).floor();
      final cellY = (event.latitude / cellSize).floor();
      buckets.putIfAbsent('$cellX:$cellY', () => []).add(event);
    }

    return buckets.values.map((group) {
      final avgLat = group.map((e) => e.latitude).reduce((a, b) => a + b) / group.length;
      final avgLng = group.map((e) => e.longitude).reduce((a, b) => a + b) / group.length;
      return MapCluster(latitude: avgLat, longitude: avgLng, events: group);
    }).toList();
  }

  /// The world is 360° wide at zoom 0 and halves in visible span with
  /// every zoom level. Markers within ~8% of the visible span would
  /// visually overlap, so that's the bucket size we group them by.
  double _cellSizeDegreesForZoom(double zoom) {
    final visibleSpanDegrees = 360 / math.pow(2, zoom);
    return visibleSpanDegrees * 0.08;
  }
}
