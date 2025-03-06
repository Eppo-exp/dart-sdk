import 'package:eppo/src/assignment_cache.dart';
import 'package:test/test.dart';

void main() {
  group('AssignmentCacheKey', () {
    test('equality works correctly', () {
      final key1 = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final key2 = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final key3 = AssignmentCacheKey(subjectKey: 'user2', flagKey: 'flag1');

      expect(key1, equals(key2));
      expect(key1, isNot(equals(key3)));
      expect(key1.hashCode, equals(key2.hashCode));
      expect(key1.hashCode, isNot(equals(key3.hashCode)));
    });
  });

  group('VariationCacheValue', () {
    test('toMap returns correct map', () {
      final value = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );

      expect(
          value.toMap(),
          equals({
            'allocationKey': 'allocation1',
            'variationKey': 'variation1',
          }));
    });

    test('equality works correctly', () {
      final value1 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final value2 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final value3 = VariationCacheValue(
        allocationKey: 'allocation2',
        variationKey: 'variation1',
      );

      expect(value1, equals(value2));
      expect(value1, isNot(equals(value3)));
      expect(value1.hashCode, equals(value2.hashCode));
      expect(value1.hashCode, isNot(equals(value3.hashCode)));
    });
  });

  group('assignmentCacheKeyToString', () {
    test('returns consistent hash for same key', () {
      final key1 = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final key2 = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');

      expect(assignmentCacheKeyToString(key1),
          equals(assignmentCacheKeyToString(key2)));
    });

    test('returns different hash for different keys', () {
      final key1 = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final key2 = AssignmentCacheKey(subjectKey: 'user2', flagKey: 'flag1');

      expect(assignmentCacheKeyToString(key1),
          isNot(equals(assignmentCacheKeyToString(key2))));
    });
  });

  group('assignmentCacheValueToString', () {
    test('returns consistent hash for same variation value', () {
      final value1 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final value2 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );

      expect(assignmentCacheValueToString(value1),
          equals(assignmentCacheValueToString(value2)));
    });

    test('returns different hash for different variation values', () {
      final value1 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final value2 = VariationCacheValue(
        allocationKey: 'allocation2',
        variationKey: 'variation1',
      );

      expect(assignmentCacheValueToString(value1),
          isNot(equals(assignmentCacheValueToString(value2))));
    });
  });

  group('InMemoryAssignmentCache', () {
    late InMemoryAssignmentCache cache;

    setUp(() {
      cache = InMemoryAssignmentCache();
    });

    test('set and has work correctly for variation entries', () {
      final key = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final value = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final entry = AssignmentCacheEntry(key: key, value: value);

      expect(cache.has(entry), isFalse);

      cache.set(entry);

      expect(cache.has(entry), isTrue);
    });

    test('set overwrites existing entries', () {
      final key = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final value1 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final entry1 = AssignmentCacheEntry(key: key, value: value1);

      cache.set(entry1);
      expect(cache.has(entry1), isTrue);

      final value2 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation2',
      );
      final entry2 = AssignmentCacheEntry(key: key, value: value2);

      cache.set(entry2);
      expect(cache.has(entry1), isFalse);
      expect(cache.has(entry2), isTrue);
    });

    test('entries returns all entries', () {
      final key1 = AssignmentCacheKey(subjectKey: 'user1', flagKey: 'flag1');
      final value1 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation1',
      );
      final entry1 = AssignmentCacheEntry(key: key1, value: value1);

      final key2 = AssignmentCacheKey(subjectKey: 'user2', flagKey: 'flag1');
      final value2 = VariationCacheValue(
        allocationKey: 'allocation1',
        variationKey: 'variation2',
      );
      final entry2 = AssignmentCacheEntry(key: key2, value: value2);

      cache.set(entry1);
      cache.set(entry2);

      final entries = cache.entries().toList();
      expect(entries.length, equals(2));

      final keyStrings = entries.map((e) => e.key).toSet();
      expect(keyStrings, contains(assignmentCacheKeyToString(key1)));
      expect(keyStrings, contains(assignmentCacheKeyToString(key2)));

      final valueStrings = entries.map((e) => e.value).toSet();
      expect(valueStrings, contains(assignmentCacheValueToString(value1)));
      expect(valueStrings, contains(assignmentCacheValueToString(value2)));
    });
  });
}
