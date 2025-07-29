import 'package:test/test.dart';
import 'package:eppo/eppo.dart';

void main() {
  group('Multi-Instance Support', () {
    setUp(() {
      // Reset before each test
      Eppo.reset();
    });

    test('forSubject throws StateError when not initialized', () async {
      expect(
        () async => await Eppo.forSubject('test-user'),
        throwsA(isA<StateError>()),
      );
    });

    test('forSubject works after initialization', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      // Should not throw
      final instance = await Eppo.forSubject('test-user');
      expect(instance, isA<EppoInstance>());
    });

    test('multiple subjects can have separate instances', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      final user1 = await Eppo.forSubject('user-1');
      final user2 = await Eppo.forSubject('user-2');

      expect(user1, isA<EppoInstance>());
      expect(user2, isA<EppoInstance>());
      expect(Eppo.activeSubjects.length, 2);
      expect(Eppo.activeSubjects, contains('user-1'));
      expect(Eppo.activeSubjects, contains('user-2'));
    });

    test('same subject returns same instance', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      await Eppo.forSubject('user-1');
      await Eppo.forSubject('user-1'); // Second call should reuse existing instance

      expect(Eppo.activeSubjects.length, 1);
      expect(Eppo.activeSubjects, contains('user-1'));
    });

    test('removeSubject removes instance', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      await Eppo.forSubject('user-1');
      expect(Eppo.activeSubjects.length, 1);

      Eppo.removeSubject('user-1');
      expect(Eppo.activeSubjects.length, 0);
    });

    test('reset clears all instances', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      await Eppo.forSubject('user-1');
      await Eppo.forSubject('user-2');
      expect(Eppo.activeSubjects.length, 2);

      Eppo.reset();
      expect(Eppo.activeSubjects.length, 0);
    });

    test('EppoInstance provides all flag evaluation methods', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      final instance = await Eppo.forSubject('test-user');

      // Test that all methods exist and return default values
      expect(instance.getStringAssignment('test-flag', 'default'), 'default');
      expect(instance.getBooleanAssignment('test-flag', false), false);
      expect(instance.getIntegerAssignment('test-flag', 42), 42);
      expect(instance.getNumericAssignment('test-flag', 3.14), 3.14);
      expect(instance.getJSONAssignment('test-flag', {'key': 'value'}), {'key': 'value'});
      
      final banditResult = instance.getBanditAction('test-flag', 'default');
      expect(banditResult.variation, 'default');
      expect(banditResult.action, null);
    });
  });
}