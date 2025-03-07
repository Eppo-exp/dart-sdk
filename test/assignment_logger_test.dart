import 'dart:convert';
import 'package:eppo/eppo.dart';
import 'package:test/test.dart';

void main() {
  group('AssignmentEvent', () {
    test('constructor sets all properties correctly', () {
      final timestamp = DateTime.now().toIso8601String();
      final event = AssignmentEvent(
        allocation: 'test-allocation',
        experiment: 'test-experiment',
        featureFlag: 'test-flag',
        format: 'v1',
        variation: 'test-variation',
        subject: 'user-123',
        timestamp: timestamp,
        subjectAttributes: {'country': 'US', 'age': 30},
        metaData: {'source': 'test'},
        evaluationDetails: {'rule': 'default'},
      );

      expect(event.allocation, equals('test-allocation'));
      expect(event.experiment, equals('test-experiment'));
      expect(event.featureFlag, equals('test-flag'));
      expect(event.format, equals('v1'));
      expect(event.variation, equals('test-variation'));
      expect(event.subject, equals('user-123'));
      expect(event.timestamp, equals(timestamp));
      expect(event.subjectAttributes, equals({'country': 'US', 'age': 30}));
      expect(event.metaData, equals({'source': 'test'}));
      expect(event.evaluationDetails, equals({'rule': 'default'}));
    });

    group('toJson', () {
      test('includes all non-null properties', () {
        final timestamp = DateTime.now().toIso8601String();
        final event = AssignmentEvent(
          allocation: 'test-allocation',
          experiment: 'test-experiment',
          featureFlag: 'test-flag',
          format: 'v1',
          variation: 'test-variation',
          subject: 'user-123',
          timestamp: timestamp,
          subjectAttributes: {'country': 'US', 'age': 30},
          metaData: {'source': 'test'},
          evaluationDetails: {'rule': 'default'},
        );

        final json = event.toJson();

        expect(json['allocation'], equals('test-allocation'));
        expect(json['experiment'], equals('test-experiment'));
        expect(json['featureFlag'], equals('test-flag'));
        expect(json['format'], equals('v1'));
        expect(json['variation'], equals('test-variation'));
        expect(json['subject'], equals('user-123'));
        expect(json['timestamp'], equals(timestamp));
        expect(json['subjectAttributes'], equals({'country': 'US', 'age': 30}));
        expect(json['metaData'], equals({'source': 'test'}));
        expect(json['evaluationDetails'], equals({'rule': 'default'}));
      });

      test('excludes null properties', () {
        final timestamp = DateTime.now().toIso8601String();
        final event = AssignmentEvent(
          featureFlag: 'test-flag',
          format: 'v1',
          subject: 'user-123',
          timestamp: timestamp,
        );

        final json = event.toJson();

        expect(json.containsKey('allocation'), isFalse);
        expect(json.containsKey('experiment'), isFalse);
        expect(json['featureFlag'], equals('test-flag'));
        expect(json['format'], equals('v1'));
        expect(json.containsKey('variation'), isFalse);
        expect(json['subject'], equals('user-123'));
        expect(json['timestamp'], equals(timestamp));
        expect(json.containsKey('subjectAttributes'), isFalse);
        expect(json.containsKey('metaData'), isFalse);
        expect(json.containsKey('evaluationDetails'), isFalse);
      });

      test('can be encoded to JSON string', () {
        final timestamp = DateTime.now().toIso8601String();
        final event = AssignmentEvent(
          allocation: 'test-allocation',
          experiment: 'test-experiment',
          featureFlag: 'test-flag',
          format: 'v1',
          variation: 'test-variation',
          subject: 'user-123',
          timestamp: timestamp,
          subjectAttributes: {'country': 'US', 'age': 30},
          metaData: {'source': 'test'},
          evaluationDetails: {'rule': 'default'},
        );

        final jsonString = jsonEncode(event.toJson());

        // Verify that the string is valid JSON
        expect(() => jsonDecode(jsonString), returnsNormally);

        // Verify that the decoded JSON matches the original
        final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decodedJson['allocation'], equals('test-allocation'));
        expect(decodedJson['experiment'], equals('test-experiment'));
        expect(decodedJson['featureFlag'], equals('test-flag'));
        expect(decodedJson['format'], equals('v1'));
        expect(decodedJson['variation'], equals('test-variation'));
        expect(decodedJson['subject'], equals('user-123'));
        expect(decodedJson['timestamp'], equals(timestamp));
        expect(decodedJson['subjectAttributes'], isA<Map>());
        expect(decodedJson['subjectAttributes']['country'], equals('US'));
        expect(decodedJson['subjectAttributes']['age'], equals(30));
      });

      test('handles complex nested structures', () {
        final timestamp = DateTime.now().toIso8601String();
        final event = AssignmentEvent(
          featureFlag: 'test-flag',
          format: 'v1',
          subject: 'user-123',
          timestamp: timestamp,
          subjectAttributes: {
            'country': 'US',
            'age': 30,
            'preferences': {
              'theme': 'dark',
              'notifications': true,
              'favorites': [1, 2, 3],
            },
            'history': [
              {'date': '2023-01-01', 'action': 'login'},
              {'date': '2023-01-02', 'action': 'purchase'},
            ],
          },
        );

        final jsonString = jsonEncode(event.toJson());

        // Verify that the string is valid JSON
        expect(() => jsonDecode(jsonString), returnsNormally);

        // Verify that the complex nested structures are preserved
        final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
        final attrs = decodedJson['subjectAttributes'] as Map<String, dynamic>;

        expect(attrs['country'], equals('US'));
        expect(attrs['age'], equals(30));

        final prefs = attrs['preferences'] as Map<String, dynamic>;
        expect(prefs['theme'], equals('dark'));
        expect(prefs['notifications'], isTrue);
        expect(prefs['favorites'], equals([1, 2, 3]));

        final history = attrs['history'] as List;
        expect(history.length, equals(2));
        expect(history[0]['date'], equals('2023-01-01'));
        expect(history[0]['action'], equals('login'));
        expect(history[1]['date'], equals('2023-01-02'));
        expect(history[1]['action'], equals('purchase'));
      });
    });
  });

  group('AssignmentLogger', () {
    test('interface can be implemented', () {
      // Create a simple implementation of AssignmentLogger
      final logger = _TestAssignmentLogger();

      // Verify that it can be used as an AssignmentLogger
      AssignmentLogger typedLogger = logger;

      // Create a test event
      final event = AssignmentEvent(
        featureFlag: 'test-flag',
        format: 'v1',
        subject: 'user-123',
        timestamp: DateTime.now().toIso8601String(),
      );

      // Log the event
      typedLogger.logAssignment(event);

      // Verify that the event was logged
      expect(logger.lastEvent, equals(event));
      expect(logger.lastEventJson, equals(event.toJson()));
    });
  });
}

// Simple implementation of AssignmentLogger for testing
class _TestAssignmentLogger implements AssignmentLogger {
  AssignmentEvent? lastEvent;
  Map<String, dynamic>? lastEventJson;

  @override
  void logAssignment(AssignmentEvent event) {
    lastEvent = event;
    lastEventJson = event.toJson();
  }
}
