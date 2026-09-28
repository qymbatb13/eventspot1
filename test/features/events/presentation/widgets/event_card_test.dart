import 'package:eventspot/features/events/domain/entities/event_category.dart';
import 'package:eventspot/features/events/domain/entities/event_entity.dart';
import 'package:eventspot/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders event name, venue and city', (tester) async {
    const event = EventEntity(
      id: '1',
      name: 'Rock Fest 2026',
      category: EventCategory.music,
      venueName: 'Central Arena',
      cityName: 'Almaty',
      latitude: 43.22,
      longitude: 76.85,
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EventCard(event: event))),
    );

    expect(find.text('Rock Fest 2026'), findsOneWidget);
    expect(find.textContaining('Central Arena'), findsOneWidget);
    expect(find.text('Almaty'), findsOneWidget);
  });

  testWidgets('falls back to a placeholder icon when there is no image', (tester) async {
    const event = EventEntity(
      id: '2',
      name: 'Mystery Event',
      category: EventCategory.miscellaneous,
      venueName: 'TBD',
      cityName: 'TBD',
      latitude: 0,
      longitude: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EventCard(event: event))),
    );

    expect(find.byIcon(Icons.event), findsOneWidget);
  });

  testWidgets('calls onTap when the card is tapped', (tester) async {
    const event = EventEntity(
      id: '3',
      name: 'Tap Me',
      category: EventCategory.sports,
      venueName: 'Arena',
      cityName: 'City',
      latitude: 0,
      longitude: 0,
    );
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventCard(event: event, onTap: () => taps++),
        ),
      ),
    );
    await tester.tap(find.text('Tap Me'));

    expect(taps, 1);
  });
}
