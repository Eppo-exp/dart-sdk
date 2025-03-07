import 'src/precompute_client.dart';

export 'src/assignment_cache.dart'
    show AssignmentCache, InMemoryAssignmentCache, NoOpAssignmentCache;
export 'src/assignment_logger.dart' show AssignmentLogger, AssignmentEvent;
export 'src/bandit_logger.dart' show BanditLogger, BanditEvent;
export 'src/precompute_client.dart'
    show SdkOptions, PrecomputeArguments, BanditEvaluation;
export 'src/subject.dart' show Subject, ContextAttributes;
export 'src/sdk_version.dart' show SdkPlatform;

/// The main interface to interact with the Eppo SDK
class Eppo {
  static EppoPrecomputedClient? _clientInstance;

  /// Initializes the SDK with the provided SDK key
  static Future<void> initialize(
      PrecomputeArguments subjectPrecompute, SdkOptions options) async {
    _clientInstance = EppoPrecomputedClient(options, subjectPrecompute);
    await _clientInstance!.fetchPrecomputedFlags();
  }

  static String getStringAssignment(String flagKey, String defaultValue) {
    return _clientInstance?.getStringAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  static bool getBooleanAssignment(String flagKey, bool defaultValue) {
    return _clientInstance?.getBooleanAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  static int getIntegerAssignment(String flagKey, int defaultValue) {
    return _clientInstance?.getIntegerAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  static double getNumericAssignment(String flagKey, double defaultValue) {
    return _clientInstance?.getNumericAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  static Map<String, dynamic> getJSONAssignment(
      String flagKey, Map<String, dynamic> defaultValue) {
    return _clientInstance?.getJSONAssignment(flagKey, defaultValue) ??
        defaultValue;
  }

  static BanditEvaluation getBanditAction(String flagKey, String defaultValue) {
    return _clientInstance?.getBanditAction(flagKey, defaultValue) ??
        BanditEvaluation(variation: defaultValue, action: null);
  }

  static void reset() {
    _clientInstance = null;
  }
}
