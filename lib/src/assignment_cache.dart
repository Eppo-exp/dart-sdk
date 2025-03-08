import 'crypto.dart';

/// Assignment cache keys are only on the subject and flag level, while the entire value is used
/// for uniqueness checking. This way if an assigned variation or bandit action changes for a
/// flag, it evicts the old one. Then, if an older assignment is later reassigned, it will be treated
/// as new.
class AssignmentCacheKey {
  /// The subject identifier
  final String subjectKey;

  /// The flag identifier
  final String flagKey;

  /// Creates a new assignment cache key
  const AssignmentCacheKey({
    required this.subjectKey,
    required this.flagKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentCacheKey &&
          runtimeType == other.runtimeType &&
          subjectKey == other.subjectKey &&
          flagKey == other.flagKey;

  @override
  int get hashCode => subjectKey.hashCode ^ flagKey.hashCode;
}

/// Base class for cache values
abstract class CacheValue {
  /// Converts the value to a map
  Map<String, String> toMap();
}

/// Cache value for variation assignments
class VariationCacheValue implements CacheValue {
  /// The allocation key
  final String allocationKey;

  /// The variation key
  final String variationKey;

  /// Creates a new variation cache value
  const VariationCacheValue({
    required this.allocationKey,
    required this.variationKey,
  });

  /// Converts the value to a map
  @override
  Map<String, String> toMap() => {
        'allocationKey': allocationKey,
        'variationKey': variationKey,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariationCacheValue &&
          runtimeType == other.runtimeType &&
          allocationKey == other.allocationKey &&
          variationKey == other.variationKey;

  @override
  int get hashCode => allocationKey.hashCode ^ variationKey.hashCode;
}

/// Cache value for bandit assignments
class BanditCacheValue implements CacheValue {
  /// The bandit key
  final String banditKey;

  /// The action key
  final String actionKey;

  /// Creates a new bandit cache value
  const BanditCacheValue({
    required this.banditKey,
    required this.actionKey,
  });

  /// Converts the value to a map
  @override
  Map<String, String> toMap() => {
        'banditKey': banditKey,
        'actionKey': actionKey,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BanditCacheValue &&
          runtimeType == other.runtimeType &&
          banditKey == other.banditKey &&
          actionKey == other.actionKey;

  @override
  int get hashCode => banditKey.hashCode ^ actionKey.hashCode;
}

/// Type alias for assignment cache values
typedef AssignmentCacheValue = CacheValue;

/// Combined key and value for an assignment cache entry
class AssignmentCacheEntry {
  /// The cache key
  final AssignmentCacheKey key;

  /// The cache value
  final AssignmentCacheValue value;

  /// Creates a new assignment cache entry
  const AssignmentCacheEntry({
    required this.key,
    required this.value,
  });
}

/// Converts an [AssignmentCacheKey] to a string.
String assignmentCacheKeyToString(AssignmentCacheKey key) {
  return getMD5Hash('${key.subjectKey};${key.flagKey}');
}

/// Converts an [AssignmentCacheValue] to a string.
String assignmentCacheValueToString(AssignmentCacheValue value) {
  return getMD5Hash(value.toMap().values.join(';'));
}

/// Interface for an assignment cache
abstract class AssignmentCache {
  /// Sets an entry in the cache
  void set(AssignmentCacheEntry entry);

  /// Checks if an entry exists in the cache
  bool has(AssignmentCacheEntry entry);
}

/// Abstract base class for assignment caches
abstract class AbstractAssignmentCache implements AssignmentCache {
  /// The delegate map
  final Map<String, String> delegate;

  /// Creates a new abstract assignment cache
  AbstractAssignmentCache(this.delegate);

  /// Returns whether the provided [AssignmentCacheEntry] is present in the cache.
  @override
  bool has(AssignmentCacheEntry entry) {
    return get(entry.key) == assignmentCacheValueToString(entry.value);
  }

  /// Gets a value from the cache
  String? get(AssignmentCacheKey key) {
    return delegate[assignmentCacheKeyToString(key)];
  }

  /// Stores the provided [AssignmentCacheEntry] in the cache. If the key already exists, it
  /// will be overwritten.
  @override
  void set(AssignmentCacheEntry entry) {
    delegate[assignmentCacheKeyToString(entry.key)] =
        assignmentCacheValueToString(entry.value);
  }

  /// Returns an iterable of all entries in the cache
  Iterable<MapEntry<String, String>> entries() {
    return delegate.entries;
  }
}

/// A cache that never expires.
///
/// The primary use case is for client-side SDKs, where the cache is only used
/// for a single user.
class InMemoryAssignmentCache extends AbstractAssignmentCache {
  /// Creates a new in-memory assignment cache
  InMemoryAssignmentCache([Map<String, String>? store])
      : super(store ?? <String, String>{});
}

/// No-op implementation of the assignment cache that disables caching
///
/// This implementation always returns false for has() and does nothing for set(),
/// effectively disabling assignment deduplication.
class NoOpAssignmentCache implements AssignmentCache {
  @override
  bool has(AssignmentCacheEntry entry) {
    // Always return false to disable caching
    return false;
  }

  @override
  void set(AssignmentCacheEntry entry) {
    // Do nothing
  }
}
