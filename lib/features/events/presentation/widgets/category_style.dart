import 'package:flutter/material.dart';

import '../../domain/entities/event_category.dart';

Color colorForCategory(EventCategory category) => switch (category) {
      EventCategory.music => Colors.deepPurple,
      EventCategory.sports => Colors.green,
      EventCategory.artsAndTheatre => Colors.orange,
      EventCategory.film => Colors.pink,
      EventCategory.miscellaneous => Colors.blue,
    };

IconData iconForCategory(EventCategory category) => switch (category) {
      EventCategory.music => Icons.music_note,
      EventCategory.sports => Icons.sports_soccer,
      EventCategory.artsAndTheatre => Icons.theater_comedy,
      EventCategory.film => Icons.movie,
      EventCategory.miscellaneous => Icons.local_activity,
    };
