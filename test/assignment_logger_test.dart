import 'package:eppo/src/assignment_logger.dart';
import 'package:test/test.dart';

void main() {
  group('AssignmentEvent', () {
    test('constructor sets all properties correctly', () {
      final timestamp = DateTime.now();
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
        timestamp: DateTime.now(),
      );

      // Log the event
      typedLogger.logAssignment(event);

      // Verify that the event was logged
      expect(logger.lastEvent, equals(event));
    });
  });
}

// Simple implementation of AssignmentLogger for testing
class _TestAssignmentLogger implements AssignmentLogger {
  AssignmentEvent? lastEvent;

  @override
  void logAssignment(AssignmentEvent event) {
    lastEvent = event;
  }
}
