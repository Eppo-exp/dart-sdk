import 'dart:async';
import 'src/precompute_client.dart';
import 'src/subject.dart';
export 'src/assignment_cache.dart'
    show AssignmentCache, InMemoryAssignmentCache, NoOpAssignmentCache;
export 'src/assignment_logger.dart' show AssignmentLogger, AssignmentEvent;
export 'src/bandit_logger.dart' show BanditLogger, BanditEvent;
export 'src/precompute_client.dart' show ClientConfiguration, BanditEvaluation, EppoPrecomputedClient;
export 'src/subject.dart' show SubjectEvaluation, Subject, ContextAttributes;
export 'src/sdk_version.dart' show SdkPlatform;

/// The main interface to interact with the Eppo SDK.
///
/// Eppo is a feature flagging and experimentation platform that allows you to
/// control feature rollouts and run A/B tests in your application.
class Eppo {
  // Private constructor to prevent direct instantiation
  Eppo._();

  // Registry of client instances by subject key
  static final Map<String, EppoPrecomputedClient> _instances = {};

  // Simple mutex for thread-safe access
  static Future<void>? _lock;

  // Configuration shared across instances
  static String? _sharedSdkKey;
  static ClientConfiguration? _sharedClientConfiguration;
  
  // Track the current singleton subject key for backwards compatibility
  static String? _singletonSubjectKey;

  /// Gets the current client instance.
  ///
  /// Returns null if the SDK has not been initialized.
  static EppoPrecomputedClient? get instance => 
      _singletonSubjectKey != null ? _instances[_singletonSubjectKey] : null;

  /// Initializes the Eppo SDK with the provided configuration.
  ///
  /// This must be called before any other Eppo methods.
  ///
  /// NOTE: Future v2 API will separate SDK configuration from subject evaluation:
  /// ```dart
  /// // Proposed v2 API (sync configuration, no fetching)
  /// Eppo.configure('sdk-key', ClientConfiguration());
  /// final client = await Eppo.forSubject(subjectEvaluation);
  /// ```
  ///
  /// Parameters:
  /// - [sdkKey]: Your Eppo SDK key for authentication.
  /// - [subjectEvaluation]: Contains the subject information and optional bandit actions.
  /// - [clientConfiguration]: Configuration options for the SDK client.
  ///
  /// Returns a Future that completes when initialization is finished.
  ///
  /// Example:
  /// ```dart
  /// await Eppo.initialize(
  ///   'sdk-key-123',
  ///   SubjectEvaluation(
  ///     subject: Subject(
  ///       subjectKey: 'user-123',
  ///       subjectAttributes: ContextAttributes(
  ///         categoricalAttributes: {'country': 'US'},
  ///         numericAttributes: {'age': 25},
  ///       ),
  ///     ),
  ///   ),
  ///   ClientConfiguration(),
  /// );
  /// ```
  static Future<void> initialize(
      String sdkKey,
      SubjectEvaluation subjectEvaluation,
      ClientConfiguration clientConfiguration) async {
    // Store shared configuration for multi-instance support
    _sharedSdkKey = sdkKey;
    _sharedClientConfiguration = clientConfiguration;
    
    final subjectKey = subjectEvaluation.subject.subjectKey;
    
    // Create and store the singleton instance immediately
    final client = EppoPrecomputedClient(sdkKey, subjectEvaluation, clientConfiguration);
    _instances[subjectKey] = client;
    _singletonSubjectKey = subjectKey;
    
    // Fetch flags in background (client is already available for use)
    await client.fetchPrecomputedFlags();
  }

  /// Gets a string assignment for the specified flag.
  ///
  /// Parameters:
  /// - [flagKey]: The unique identifier for the feature flag.
  /// - [defaultValue]: The value to return if the flag is not found or an error occurs.
  ///
  /// Returns the assigned string value or the default value if the flag is not found.
  ///
  /// Example:
  /// ```dart
  /// String buttonText = Eppo.getStringAssignment('button-text-flag', 'Click me');
  /// ```
  static String getStringAssignment(String flagKey, String defaultValue) {
    return instance?.getStringAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  /// Gets a boolean assignment for the specified flag.
  ///
  /// Parameters:
  /// - [flagKey]: The unique identifier for the feature flag.
  /// - [defaultValue]: The value to return if the flag is not found or an error occurs.
  ///
  /// Returns the assigned boolean value or the default value if the flag is not found.
  ///
  /// Example:
  /// ```dart
  /// bool showFeature = Eppo.getBooleanAssignment('show-new-feature', false);
  /// ```
  static bool getBooleanAssignment(String flagKey, bool defaultValue) {
    return instance?.getBooleanAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  /// Gets an integer assignment for the specified flag.
  ///
  /// Parameters:
  /// - [flagKey]: The unique identifier for the feature flag.
  /// - [defaultValue]: The value to return if the flag is not found or an error occurs.
  ///
  /// Returns the assigned integer value or the default value if the flag is not found.
  ///
  /// Example:
  /// ```dart
  /// int maxItems = Eppo.getIntegerAssignment('max-items-flag', 10);
  /// ```
  static int getIntegerAssignment(String flagKey, int defaultValue) {
    return instance?.getIntegerAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  /// Gets a numeric (double) assignment for the specified flag.
  ///
  /// Parameters:
  /// - [flagKey]: The unique identifier for the feature flag.
  /// - [defaultValue]: The value to return if the flag is not found or an error occurs.
  ///
  /// Returns the assigned numeric value or the default value if the flag is not found.
  ///
  /// Example:
  /// ```dart
  /// double discountRate = Eppo.getNumericAssignment('discount-rate', 0.1);
  /// ```
  static double getNumericAssignment(String flagKey, double defaultValue) {
    return instance?.getNumericAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  /// Gets a JSON assignment for the specified flag.
  ///
  /// Parameters:
  /// - [flagKey]: The unique identifier for the feature flag.
  /// - [defaultValue]: The value to return if the flag is not found or an error occurs.
  ///
  /// Returns the assigned JSON object or the default value if the flag is not found.
  ///
  /// Example:
  /// ```dart
  /// Map<String, dynamic> config = Eppo.getJSONAssignment(
  ///   'app-config',
  ///   {'theme': 'light', 'fontSize': 14},
  /// );
  /// ```
  static Map<String, dynamic> getJSONAssignment(
      String flagKey, Map<String, dynamic> defaultValue) {
    return instance?.getJSONAssignment(flagKey, defaultValue) ?? defaultValue;
  }

  /// Gets a bandit action for the specified flag.
  ///
  /// Bandit algorithms dynamically select the best action based on performance.
  ///
  /// Parameters:
  /// - [flagKey]: The unique identifier for the feature flag.
  /// - [defaultValue]: The value to return if the flag is not found or an error occurs.
  ///
  /// Returns a BanditEvaluation containing the selected action and variation,
  /// or a default evaluation if the flag is not found.
  ///
  /// Example:
  /// ```dart
  /// BanditEvaluation result = Eppo.getBanditAction('recommendation-flag', 'default');
  /// String variation = result.variation;
  /// String? action = result.action;
  /// ```
  static BanditEvaluation getBanditAction(String flagKey, String defaultValue) {
    return instance?.getBanditAction(flagKey, defaultValue) ??
        BanditEvaluation(variation: defaultValue, action: null);
  }

  /// Gets or creates an SDK instance for a specific subject.
  ///
  /// This allows you to have multiple SDK instances for different users,
  /// such as one for anonymous users and another for logged-in users.
  ///
  /// Parameters:
  /// - [subjectEvaluation]: Contains the subject information and optional bandit actions.
  ///
  /// Returns an EppoPrecomputedClient that provides flag evaluation methods for the specific subject.
  ///
  /// Example:
  /// ```dart
  /// // For anonymous user
  /// final anonymousEppo = await Eppo.forSubject(
  ///   SubjectEvaluation(
  ///     subject: Subject(subjectKey: 'anonymous-123'),
  ///   ),
  /// );
  /// 
  /// // For logged-in user with attributes
  /// final userEppo = await Eppo.forSubject(
  ///   SubjectEvaluation(
  ///     subject: Subject(
  ///       subjectKey: 'user-456',
  ///       subjectAttributes: ContextAttributes(
  ///         categoricalAttributes: {'country': 'US'},
  ///         numericAttributes: {'age': 25},
  ///       ),
  ///     ),
  ///   ),
  /// );
  /// ```
  static Future<EppoPrecomputedClient> forSubject(
    SubjectEvaluation subjectEvaluation,
  ) async {
    if (_sharedSdkKey == null || _sharedClientConfiguration == null) {
      throw StateError(
          'SDK not initialized. Call Eppo.initialize() first.');
    }

    final subjectKey = subjectEvaluation.subject.subjectKey;

    return await _withLock(() async {
      // Check if we already have an instance for this subject (including singleton)
      if (_instances.containsKey(subjectKey)) {
        return _instances[subjectKey]!;
      }

      final client = EppoPrecomputedClient(
        _sharedSdkKey!,
        subjectEvaluation,
        _sharedClientConfiguration!,
      );

      // Store the instance immediately so it's available for use
      _instances[subjectKey] = client;

      // Fetch flags in background (client is already available for flag evaluations)
      await client.fetchPrecomputedFlags();

      return client;
    });
  }

  /// Executes the given function with a lock to ensure thread safety
  static Future<T> _withLock<T>(Future<T> Function() fn) async {
    // Wait for any existing lock
    while (_lock != null) {
      await _lock;
    }

    // Create our lock
    final completer = Completer<void>();
    _lock = completer.future;

    try {
      return await fn();
    } finally {
      // Release the lock
      _lock = null;
      completer.complete();
    }
  }

  /// Removes an SDK instance for a specific subject key.
  ///
  /// This is useful for cleanup when a user logs out or is no longer active.
  ///
  /// Parameters:
  /// - [subjectKey]: The unique identifier for the subject to remove.
  ///
  /// Example:
  /// ```dart
  /// // When user logs out
  /// Eppo.removeSubject('user-456');
  /// ```
  static void removeSubject(String subjectKey) {
    _instances.remove(subjectKey);
    // If this was the singleton subject, clear the singleton reference
    if (_singletonSubjectKey == subjectKey) {
      _singletonSubjectKey = null;
    }
  }

  /// Gets all active subject keys that have SDK instances.
  ///
  /// Returns a list of subject keys that currently have active instances.
  static List<String> get activeSubjects => _instances.keys.toList();

  /// Resets the SDK to an uninitialized state.
  ///
  /// This clears all client instances and requires initialize() to be called
  /// again before using any other methods. Useful for testing or when switching users.
  ///
  /// Example:
  /// ```dart
  /// // When app restarts or needs complete reset
  /// Eppo.reset();
  /// ```
  static void reset() {
    _instances.clear();
    _sharedSdkKey = null;
    _sharedClientConfiguration = null;
    _singletonSubjectKey = null;
  }
}

