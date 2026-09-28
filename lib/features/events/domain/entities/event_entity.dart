import 'package:equatable/equatable.dart';

import 'event_category.dart';

/// A single event, independent of how it was fetched or serialized.
/// Nothing in this class knows that Ticketmaster exists.
class EventEntity extends Equatable {
  const EventEntity({
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

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        venueName,
        cityName,
        latitude,
        longitude,
        imageUrl,
        startDateTime,
        ticketUrl,
      ];
}
