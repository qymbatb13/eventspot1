import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_entity.dart';

/// Data-layer representation of a single Ticketmaster event.
///
/// Deliberately hand-written instead of `json_serializable`: Ticketmaster's
/// payload is deeply nested (`_embedded.venues[0].location.latitude` as a
/// *string*, optional `dates.start.dateTime` vs. `localDate`+`localTime`,
/// image arrays with no guaranteed "best" entry...) and defensive, per-field
/// fallbacks are easier to read and unit-test as plain code than to express
/// through codegen annotations. See README → "Architecture decisions".
class EventModel {
  const EventModel({
    required this.id,
    required this.name,
    required this.category,
    required this.venueName,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.startDateTime,
    this.ticketUrl,
  });

  final String id;
  final String name;
  final EventCategory category;
  final String venueName;
  final String cityName;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final DateTime? startDateTime;
  final String? ticketUrl;

  /// Returns `null` when the payload is missing venue coordinates — such
  /// an event cannot be placed on the map and is silently dropped by the
  /// caller rather than crashing the whole page parse.
  static EventModel? tryParse(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final venues = embedded?['venues'] as List<dynamic>?;
    if (venues == null || venues.isEmpty) return null;

    final venue = venues.first as Map<String, dynamic>;
    final location = venue['location'] as Map<String, dynamic>?;
    final latitude = double.tryParse('${location?['latitude']}');
    final longitude = double.tryParse('${location?['longitude']}');
    if (latitude == null || longitude == null) return null;

    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (id == null || name == null) return null;

    return EventModel(
      id: id,
      name: name,
      category: EventCategory.fromApiName(_segmentName(json)),
      venueName: venue['name'] as String? ?? 'Место не указано',
      cityName: (venue['city'] as Map<String, dynamic>?)?['name'] as String? ??
          'Неизвестный город',
      latitude: latitude,
      longitude: longitude,
      imageUrl: _bestImageUrl(json['images'] as List<dynamic>?),
      startDateTime: _parseStart(json['dates'] as Map<String, dynamic>?),
      ticketUrl: json['url'] as String?,
    );
  }

  static String? _segmentName(Map<String, dynamic> json) {
    final classifications = json['classifications'] as List<dynamic>?;
    if (classifications == null || classifications.isEmpty) return null;
    final first = classifications.first as Map<String, dynamic>;
    return (first['segment'] as Map<String, dynamic>?)?['name'] as String?;
  }

  /// Picks the widest image, since Ticketmaster returns many aspect
  /// ratios/resolutions with no field marking a "primary" one.
  static String? _bestImageUrl(List<dynamic>? images) {
    if (images == null || images.isEmpty) return null;
    final sorted = [...images.cast<Map<String, dynamic>>()]..sort(
        (a, b) => ((b['width'] as num?) ?? 0).compareTo((a['width'] as num?) ?? 0),
      );
    return sorted.first['url'] as String?;
  }

  static DateTime? _parseStart(Map<String, dynamic>? dates) {
    final start = dates?['start'] as Map<String, dynamic>?;
    if (start == null) return null;

    final isoDateTime = start['dateTime'] as String?;
    if (isoDateTime != null) return DateTime.tryParse(isoDateTime);

    final localDate = start['localDate'] as String?;
    if (localDate == null) return null;
    final localTime = start['localTime'] as String?;
    return DateTime.tryParse(localTime != null ? '${localDate}T$localTime' : localDate);
  }

  EventEntity toEntity() => EventEntity(
        id: id,
        name: name,
        category: category,
        venueName: venueName,
        cityName: cityName,
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageUrl,
        startDateTime: startDateTime,
        ticketUrl: ticketUrl,
      );
}
