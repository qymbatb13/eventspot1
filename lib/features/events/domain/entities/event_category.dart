/// Coarse-grained category used for the filter bar.
///
/// Maps onto Ticketmaster's `classificationName` query parameter, which
/// only accepts a handful of top-level "segment" names.
enum EventCategory {
  music,
  sports,
  artsAndTheatre,
  film,
  miscellaneous;

  /// Value Ticketmaster's API expects for `classificationName`.
  String get ticketmasterName => switch (this) {
        EventCategory.music => 'Music',
        EventCategory.sports => 'Sports',
        EventCategory.artsAndTheatre => 'Arts & Theatre',
        EventCategory.film => 'Film',
        EventCategory.miscellaneous => 'Miscellaneous',
      };

  /// Human-readable label for the UI (Russian, matches the rest of the app).
  String get label => switch (this) {
        EventCategory.music => 'Концерты',
        EventCategory.sports => 'Спорт',
        EventCategory.artsAndTheatre => 'Театр и искусство',
        EventCategory.film => 'Кино',
        EventCategory.miscellaneous => 'Другое',
      };

  /// Best-effort mapping from a free-text segment name returned by the API
  /// (e.g. from `classifications[0].segment.name`) back to our enum, for
  /// coloring markers by category even when no filter is applied.
  static EventCategory fromApiName(String? name) {
    switch (name) {
      case 'Music':
        return EventCategory.music;
      case 'Sports':
        return EventCategory.sports;
      case 'Arts & Theatre':
        return EventCategory.artsAndTheatre;
      case 'Film':
        return EventCategory.film;
      default:
        return EventCategory.miscellaneous;
    }
  }
}
