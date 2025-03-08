import 'package:logging/logging.dart';

import 'src/precompute_client.dart';
import 'src/subject.dart';
export 'src/assignment_cache.dart'
    show AssignmentCache, InMemoryAssignmentCache, NoOpAssignmentCache;
export 'src/assignment_logger.dart' show AssignmentLogger, AssignmentEvent;
export 'src/bandit_logger.dart' show BanditLogger, BanditEvent;
export 'src/precompute_client.dart' show ClientConfiguration, BanditEvaluation;
export 'src/subject.dart' show SubjectEvaluation, Subject, ContextAttributes;
export 'src/sdk_version.dart' show SdkPlatform;

/// The main interface to interact with the Eppo SDK.
///
/// Eppo is a feature flagging and experimentation platform that allows you to
/// control feature rollouts and run A/B tests in your application.
class Eppo {
  static EppoPrecomputedClient? _clientInstance;
  static final Logger _logger = Logger('eppo');

  /// Initializes the Eppo SDK with the provided configuration.
  ///
  /// This must be called before any other Eppo methods.
  ///
  /// Parameters:
  /// - [sdkKey]: Your Eppo API key for authentication.
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
    _clientInstance =
        EppoPrecomputedClient(sdkKey, subjectEvaluation, clientConfiguration);
    await fetchPrecomputedFlags();
  }

  /// Fetches precomputed flags on-demand.
  ///
  /// This can be called to refresh flag values without reinitializing the SDK.
  /// If the SDK is not initialized, a warning will be logged and the method will return.
  ///
  /// Returns a Future that completes when flags have been fetched.
  ///
  /// Example:
  /// ```dart
  /// await Eppo.fetchPrecomputedFlags();
  /// ```
  static Future<void> fetchPrecomputedFlags() async {
    if (_clientInstance == null) {
      _logger.warning('Eppo not initialized');
      return;
    }
    await _clientInstance!.fetchPrecomputedFlags();
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
    return _clientInstance?.getStringAssignment(flagKey, defaultValue) ??
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
    return _clientInstance?.getBooleanAssignment(flagKey, defaultValue) ??
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
    return _clientInstance?.getIntegerAssignment(flagKey, defaultValue) ??
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
    return _clientInstance?.getNumericAssignment(flagKey, defaultValue) ??
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
    return _clientInstance?.getJSONAssignment(flagKey, defaultValue) ??
        defaultValue;
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
    return _clientInstance?.getBanditAction(flagKey, defaultValue) ??
        BanditEvaluation(variation: defaultValue, action: null);
  }

  /// Resets the SDK to an uninitialized state.
  ///
  /// This clears the client instance and requires initialize() to be called
  /// again before using any other methods. Useful for testing or when switching users.
  ///
  /// Example:
  /// ```dart
  /// // When user logs out
  /// Eppo.reset();
  /// ```
  static void reset() {
    _clientInstance = null;
  }
}
