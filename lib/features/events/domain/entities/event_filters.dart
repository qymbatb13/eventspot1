import 'package:equatable/equatable.dart';

import 'event_category.dart';

/// Everything the filter bar can control, bundled so the BLoC only has to
/// carry one object around instead of four loose fields.
class EventFilters extends Equatable {
  const EventFilters({
    this.category,
    this.radiusKm = 25,
    this.startDate,
    this.endDate,
    this.keyword,
  });

  /// `null` means "all categories".
  final EventCategory? category;
  final double radiusKm;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? keyword;

  EventFilters copyWith({
    EventCategory? category,
    bool clearCategory = false,
    double? radiusKm,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateRange = false,
    String? keyword,
  }) {
    return EventFilters(
      category: clearCategory ? null : (category ?? this.category),
      radiusKm: radiusKm ?? this.radiusKm,
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      keyword: keyword ?? this.keyword,
    );
  }

  @override
  List<Object?> get props => [category, radiusKm, startDate, endDate, keyword];
}
