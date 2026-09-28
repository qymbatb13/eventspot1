import 'package:eventspot/features/events/data/models/event_model.dart';
import 'package:eventspot/features/events/domain/entities/event_category.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _validEventJson({List<dynamic>? images}) => {
      'id': 'evt-1',
      'name': 'Rock Fest 2026',
      'url': 'https://ticketmaster.com/evt-1',
      'images': images ?? [
        {'url': 'https://img/small.jpg', 'width': 200},
        {'url': 'https://img/large.jpg', 'width': 1024},
      ],
      'dates': {
        'start': {'localDate': '2026-06-01', 'localTime': '19:00:00'},
      },
      'classifications': [
        {
          'segment': {'name': 'Music'},
        },
      ],
      '_embedded': {
        'venues': [
          {
            'name': 'Arena',
            'city': {'name': 'Almaty'},
            'location': {'latitude': '43.2220', 'longitude': '76.8512'},
          },
        ],
      },
    };

void main() {
  group('EventModel.tryParse', () {
    test('parses a well-formed event, picking the widest image', () {
      final model = EventModel.tryParse(_validEventJson());

      expect(model, isNotNull);
      expect(model!.id, 'evt-1');
      expect(model.name, 'Rock Fest 2026');
      expect(model.category, EventCategory.music);
      expect(model.venueName, 'Arena');
      expect(model.cityName, 'Almaty');
      expect(model.latitude, closeTo(43.2220, 0.0001));
      expect(model.longitude, closeTo(76.8512, 0.0001));
      expect(model.imageUrl, 'https://img/large.jpg');
      expect(model.startDateTime, DateTime.parse('2026-06-01T19:00:00'));
    });

    test('returns null when venue coordinates are missing', () {
      final json = _validEventJson();
      (json['_embedded'] as Map<String, dynamic>)['venues'] = <dynamic>[
        {'name': 'No location venue'},
      ];

      expect(EventModel.tryParse(json), isNull);
    });

    test('returns null when there is no embedded venue at all', () {
      final json = _validEventJson()..remove('_embedded');
      expect(EventModel.tryParse(json), isNull);
    });

    test('falls back to "Miscellaneous" for an unknown/missing classification', () {
      final json = _validEventJson()..remove('classifications');
      final model = EventModel.tryParse(json);
      expect(model!.category, EventCategory.miscellaneous);
    });

    test('handles an event with no images without throwing', () {
      final json = _validEventJson(images: []);
      final model = EventModel.tryParse(json);
      expect(model!.imageUrl, isNull);
    });

    test('parses ISO dateTime when present, ignoring localDate/localTime', () {
      final json = _validEventJson();
      (json['dates'] as Map<String, dynamic>)['start'] = {
        'dateTime': '2026-06-01T15:00:00Z',
        'localDate': '2026-06-01',
        'localTime': '19:00:00',
      };

      final model = EventModel.tryParse(json);
      expect(model!.startDateTime, DateTime.parse('2026-06-01T15:00:00Z'));
    });
  });
}
