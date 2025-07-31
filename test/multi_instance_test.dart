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
        () async => await Eppo.forSubject(
          SubjectEvaluation(
            subject: Subject(subjectKey: 'test-user'),
          ),
        ),
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
      final instance = await Eppo.forSubject(
        SubjectEvaluation(
          subject: Subject(subjectKey: 'test-user'),
        ),
      );
      expect(instance, isA<EppoPrecomputedClient>());
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

      final user1 = await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-1')));
      final user2 = await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-2')));

      expect(user1, isA<EppoPrecomputedClient>());
      expect(user2, isA<EppoPrecomputedClient>());
      expect(Eppo.activeSubjects.length, 3); // initial-user + user-1 + user-2
      expect(Eppo.activeSubjects, contains('initial-user'));
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

      await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-1')));
      await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-1'))); // Second call should reuse existing instance

      expect(Eppo.activeSubjects.length, 2); // initial-user + user-1
      expect(Eppo.activeSubjects, contains('initial-user'));
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

      await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-1')));
      expect(Eppo.activeSubjects.length, 2); // initial-user + user-1

      Eppo.removeSubject('user-1');
      expect(Eppo.activeSubjects.length, 1); // only initial-user remains
      expect(Eppo.activeSubjects, contains('initial-user'));
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

      await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-1')));
      await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-2')));
      expect(Eppo.activeSubjects.length, 3); // initial-user + user-1 + user-2

      Eppo.reset();
      expect(Eppo.activeSubjects.length, 0);
    });

    test('EppoPrecomputedClient provides all flag evaluation methods', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      final instance = await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'test-user')));

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

    test('singleton and multi-instance share same storage', () async {
      // Initialize the SDK with a specific subject
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'singleton-user'),
        ),
        ClientConfiguration(),
      );

      // The singleton instance should be available
      expect(Eppo.instance, isNotNull);
      
      // Getting an instance for the same subject should return the same client
      final sameSubjectInstance = await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'singleton-user')));
      expect(sameSubjectInstance, isA<EppoPrecomputedClient>());
      
      // Should only have one instance total
      expect(Eppo.activeSubjects.length, 1);
      expect(Eppo.activeSubjects, contains('singleton-user'));
      
      // Removing the singleton subject should clear the singleton instance too
      Eppo.removeSubject('singleton-user');
      expect(Eppo.instance, isNull);
      expect(Eppo.activeSubjects.length, 0);
    });

    test('concurrent forSubject calls create only one instance', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      // Make multiple concurrent calls for the same subject
      final futures = <Future<EppoPrecomputedClient>>[];
      for (int i = 0; i < 5; i++) {
        futures.add(Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'concurrent-user'))));
      }

      // Wait for all to complete
      final instances = await Future.wait(futures);

      // Should only create one instance total (initial-user + concurrent-user)
      expect(Eppo.activeSubjects.length, 2);
      expect(Eppo.activeSubjects, contains('initial-user'));
      expect(Eppo.activeSubjects, contains('concurrent-user'));

      // All returned instances should be for the same underlying client
      expect(instances.length, 5);
      for (final instance in instances) {
        expect(instance, isA<EppoPrecomputedClient>());
      }
    });

    test('client is available immediately after creation', () async {
      // Initialize the SDK first
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'initial-user'),
        ),
        ClientConfiguration(),
      );

      // The singleton instance should be available immediately after initialize
      expect(Eppo.instance, isNotNull);
      expect(Eppo.activeSubjects, contains('initial-user'));

      // Start creating a new subject instance
      final futureInstance = Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'new-user')));
      
      // The subject should appear in activeSubjects immediately
      // (even though forSubject hasn't completed yet)
      expect(Eppo.activeSubjects, contains('new-user'));
      
      // Complete the creation
      final instance = await futureInstance;
      expect(instance, isA<EppoPrecomputedClient>());
      
      // Should still be there after completion
      expect(Eppo.activeSubjects, contains('new-user'));
    });

    test('singleton API works seamlessly with forSubject API', () async {
      // 1. Start with singleton API
      await Eppo.initialize(
        'test-sdk-key',
        SubjectEvaluation(
          subject: Subject(subjectKey: 'user-123'),
        ),
        ClientConfiguration(),
      );

      // 2. Use singleton methods
      expect(Eppo.instance, isNotNull);
      String singletonResult = Eppo.getStringAssignment('test-flag', 'default');
      expect(singletonResult, 'default');

      // 3. Use forSubject with same subject key as singleton
      final sameUserInstance = await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-123')));
      expect(sameUserInstance, isA<EppoPrecomputedClient>());
      
      // Should return same results as singleton (same underlying client)
      String instanceResult = sameUserInstance.getStringAssignment('test-flag', 'default');
      expect(instanceResult, singletonResult);

      // 4. Use forSubject with different subject key
      final otherUserInstance = await Eppo.forSubject(SubjectEvaluation(subject: Subject(subjectKey: 'user-456')));
      expect(otherUserInstance, isA<EppoPrecomputedClient>());

      // 5. Verify storage
      expect(Eppo.activeSubjects.length, 2);
      expect(Eppo.activeSubjects, contains('user-123')); // Singleton subject
      expect(Eppo.activeSubjects, contains('user-456')); // Multi-instance subject

      // 6. Singleton should still work
      expect(Eppo.instance, isNotNull);
      String stillWorking = Eppo.getStringAssignment('test-flag', 'default');
      expect(stillWorking, 'default');
    });
  });
}