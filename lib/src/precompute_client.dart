import 'dart:convert';

import 'package:logging/logging.dart';
import 'bandit_logger.dart';
import 'assignment_logger.dart';
import 'assignment_cache.dart';
import 'configuration_store.dart';
import 'crypto.dart';
import 'sdk_version.dart';
import 'subject.dart';
import 'configuration_wire_protocol.dart';
import 'api_client.dart';

// Configuration for the precomputed client
class ClientConfiguration {
  /// Assignment logger
  final AssignmentLogger? assignmentLogger;

  /// Bandit logger
  final BanditLogger? banditLogger;

  /// Platform for the SDK
  final SdkPlatform? sdkPlatform;

  /// Base URL for API requests
  final String? baseUrl;

  /// Request timeout
  final Duration? requestTimeout;

  /// Whether to throw on failed initialization
  final bool? throwOnFailedInitialization;

  /// Optional API client for testing
  final EppoApiClient? apiClient;

  /// Assignment cache for flags
  ///
  /// By default, an InMemoryAssignmentCache is used to prevent duplicate logging of the same assignment.
  /// To disable assignment deduplication, use NoOpAssignmentCache:
  /// ```dart
  /// SdkOptions(
  ///   // other options...
  ///   assignmentCache: NoOpAssignmentCache(),
  /// )
  /// ```
  final AssignmentCache flagAssignmentCache;

  /// Assignment cache for bandit actions
  final AssignmentCache banditActionCache;

  /// Creates a new set of precomputed flags request parameters
  ClientConfiguration({
    this.assignmentLogger,
    this.banditLogger,
    this.sdkPlatform,
    this.baseUrl,
    this.requestTimeout,
    this.throwOnFailedInitialization,
    this.apiClient,
    AssignmentCache? flagAssignmentCache,
    AssignmentCache? banditActionCache,
  })  : flagAssignmentCache = flagAssignmentCache ?? InMemoryAssignmentCache(),
        banditActionCache = banditActionCache ?? InMemoryAssignmentCache();
}

/// Client for evaluating precomputed feature flags and bandits
class EppoPrecomputedClient {
  final String _sdkKey;
  final SubjectEvaluation _subjectEvaluation;
  final ClientConfiguration _clientConfiguration;
  final ConfigurationStore<ObfuscatedPrecomputedFlag> _precomputedFlagStore;
  final ConfigurationStore<ObfuscatedPrecomputedBandit> _precomputedBanditStore;
  EppoApiClient? _apiClient;
  final Logger _logger = Logger('EppoPrecomputedClient');

  /// Creates a new precomputed client
  EppoPrecomputedClient(String sdkKey, SubjectEvaluation subjectEvaluation,
      ClientConfiguration clientConfiguration)
      : _sdkKey = sdkKey,
        _subjectEvaluation = subjectEvaluation,
        _clientConfiguration = clientConfiguration,
        _precomputedFlagStore =
            InMemoryConfigurationStore<ObfuscatedPrecomputedFlag>(),
        _precomputedBanditStore =
            InMemoryConfigurationStore<ObfuscatedPrecomputedBandit>(),
        _apiClient = clientConfiguration.apiClient;

  /// Fetches precomputed flags from the server
  Future<void> fetchPrecomputedFlags() async {
    final throwOnFailedInitialization =
        _clientConfiguration.throwOnFailedInitialization ?? false;

    // Only create a new API client if one wasn't provided in the options
    _apiClient ??= EppoApiClient(
      sdkKey: _sdkKey,
      sdkVersion: getSdkVersion(),
      sdkPlatform: _clientConfiguration.sdkPlatform ?? SdkPlatform.unknown,
      baseUrl: _clientConfiguration.baseUrl,
      requestTimeout: _clientConfiguration.requestTimeout,
    );

    try {
      final response = await _apiClient!.fetchPrecomputedFlags(
        _subjectEvaluation,
      );

      _precomputedFlagStore.update(response.flags,
          salt: response.salt, format: response.format.toString());
      _precomputedBanditStore.update(response.bandits,
          salt: response.salt, format: response.format.toString());

      _logger.info(
        'successfully fetched precomputed flags',
        {
          'flags': response.flags.length,
          'bandits': response.bandits.length,
        },
      );
    } catch (e) {
      if (throwOnFailedInitialization) {
        throw Exception('failed to initialize precomputed flags: $e');
      } else {
        _logger.severe(
            'failed to initialize precomputed flags', e, StackTrace.current);
      }
    }
  }

  /// Gets a string assignment for a flag
  String getStringAssignment(String flagKey, String defaultValue) {
    return _getPrecomputedAssignment(
      flagKey,
      defaultValue,
      VariationType.string,
    );
  }

  /// Gets a boolean assignment for a flag
  bool getBooleanAssignment(String flagKey, bool defaultValue) {
    return _getPrecomputedAssignment(
      flagKey,
      defaultValue,
      VariationType.boolean,
    );
  }

  /// Gets an integer assignment for a flag
  int getIntegerAssignment(String flagKey, int defaultValue) {
    return _getPrecomputedAssignment(
      flagKey,
      defaultValue,
      VariationType.integer,
    );
  }

  /// Gets a numeric (double) assignment for a flag
  double getNumericAssignment(String flagKey, double defaultValue) {
    return _getPrecomputedAssignment(
      flagKey,
      defaultValue,
      VariationType.numeric,
    );
  }

  /// Gets a JSON object assignment for a flag
  Map<String, dynamic> getJSONAssignment(
    String flagKey,
    Map<String, dynamic> defaultValue,
  ) {
    return _getPrecomputedAssignment(
      flagKey,
      defaultValue,
      VariationType.json,
      (value) {
        if (value is String) {
          try {
            return JsonDecoder().convert(value) as Map<String, dynamic>;
          } catch (e) {
            _logger.warning('unable to parse JSON', e, StackTrace.current);
            return defaultValue;
          }
        } else if (value is Map) {
          // If the value is already a Map (decoded from JSON), convert it to Map<String, dynamic>
          try {
            return Map<String, dynamic>.from(value);
          } catch (e) {
            _logger.warning('unable to convert Map', e, StackTrace.current);
            return defaultValue;
          }
        }
        return defaultValue;
      },
    );
  }

  /// Gets a bandit action for a flag
  BanditEvaluation getBanditAction(
    String flagKey,
    String defaultValue,
  ) {
    final obfuscatedBandit = _getPrecomputedBandit(flagKey);

    if (obfuscatedBandit == null) {
      _logger.warning(
        'no assigned variation because bandit not found',
        {
          'flagKey': flagKey,
        },
      );
      return BanditEvaluation(variation: defaultValue, action: null);
    }

    // Decode the bandit inline
    final decodedBanditKey = decodeBase64(obfuscatedBandit.banditKey);
    final decodedAction = decodeBase64(obfuscatedBandit.action);
    final decodedModelVersion = decodeBase64(obfuscatedBandit.modelVersion);
    final decodedActionNumericAttributes =
        obfuscatedBandit.actionNumericAttributes.map(
      (key, value) =>
          MapEntry(key, double.tryParse(decodeBase64(value)) ?? 0.0),
    );
    final decodedActionCategoricalAttributes =
        obfuscatedBandit.actionCategoricalAttributes.map(
      (key, value) => MapEntry(key, decodeBase64(value)),
    );

    final assignedVariation = getStringAssignment(flagKey, defaultValue);

    final banditEvent = BanditEvent(
      timestamp: DateTime.timestamp(),
      featureFlag: flagKey,
      bandit: decodedBanditKey,
      subject: _subjectEvaluation.subject.subjectKey,
      action: decodedAction,
      actionProbability: obfuscatedBandit.actionProbability,
      optimalityGap: obfuscatedBandit.optimalityGap,
      modelVersion: decodedModelVersion,
      subjectNumericAttributes:
          _subjectEvaluation.subject.subjectAttributes?.numericAttributes.map(
        (key, value) => MapEntry(key, value.toDouble()),
      ),
      subjectCategoricalAttributes: _subjectEvaluation
          .subject.subjectAttributes?.categoricalAttributes
          .map(
        (key, value) => MapEntry(key, value),
      ),
      actionNumericAttributes: decodedActionNumericAttributes,
      actionCategoricalAttributes: decodedActionCategoricalAttributes,
      metaData: buildLoggerMetadata(),
    );

    try {
      _logBanditAction(banditEvent);
    } catch (error) {
      _logger.severe('unable to log bandit action', error, StackTrace.current);
    }

    return BanditEvaluation(
        variation: assignedVariation, action: decodedAction);
  }

  // Private helper methods
  T _getPrecomputedAssignment<T>(
    String flagKey,
    T defaultValue,
    VariationType expectedType, [
    T Function(dynamic value)? valueTransformer,
  ]) {
    if (flagKey.isEmpty) {
      throw ArgumentError('Invalid argument: flagKey cannot be blank');
    }

    final precomputedFlag = _getPrecomputedFlag(flagKey);

    if (precomputedFlag == null) {
      _logger.warning(
        'no assigned variation because flag not found',
        {
          'flagKey': flagKey,
        },
      );
      return defaultValue;
    }

    // Add type checking before proceeding
    if (!checkTypeMatch(expectedType, precomputedFlag.variationType)) {
      _logger.warning(
        'type mismatch',
        {
          'expected': expectedType.name,
          'flagKey': flagKey,
          'actual': precomputedFlag.variationType.name,
        },
      );
      return defaultValue;
    }

    // Decode the variation value based on its type
    final decodedValue = decodeValue(precomputedFlag.variationValue,
        precomputedFlag.variationType.toString().split('.').last);

    final result = FlagEvaluation(
      flagKey: flagKey,
      format: _precomputedFlagStore.getFormat() ?? '',
      subjectKey: _subjectEvaluation.subject.subjectKey,
      subjectAttributes:
          _subjectEvaluation.subject.subjectAttributes ?? ContextAttributes(),
      variation: Variation(
        key: precomputedFlag.variationKey != null
            ? decodeBase64(precomputedFlag.variationKey!)
            : '',
        value: decodedValue,
      ),
      allocationKey: precomputedFlag.allocationKey != null
          ? decodeBase64(precomputedFlag.allocationKey!)
          : '',
      extraLogging: precomputedFlag.extraLogging != null
          ? decodeStringMap(precomputedFlag.extraLogging!)
          : {},
      doLog: precomputedFlag.doLog,
    );

    try {
      final variation = result.variation;
      final variationValue = variation?.value;

      if (result.doLog) {
        _logAssignment(result);
      }

      if (variationValue != null) {
        return valueTransformer != null
            ? valueTransformer(variationValue)
            : variationValue as T;
      }
      return defaultValue;
    } catch (error) {
      _logger.warning('unable to transform value', error, StackTrace.current);
      return defaultValue;
    }
  }

  void _logAssignment(FlagEvaluation result) {
    final flagKey = result.flagKey;
    final subjectKey = result.subjectKey;
    final allocationKey = result.allocationKey;
    final subjectAttributes = result.subjectAttributes;
    final variation = result.variation;
    final format = result.format;

    // Create the assignment event
    final event = AssignmentEvent(
      allocation: allocationKey,
      experiment: allocationKey != null ? '$flagKey-$allocationKey' : null,
      featureFlag: flagKey,
      format: format,
      variation: variation?.key,
      subject: subjectKey,
      timestamp: DateTime.timestamp(),
      subjectAttributes: subjectAttributes.toJson(),
      metaData: buildLoggerMetadata(),
    );

    // Check if we've already logged this assignment
    if (variation != null && allocationKey != null) {
      final hasLoggedAssignment = _clientConfiguration.flagAssignmentCache.has(
        AssignmentCacheEntry(
          key: AssignmentCacheKey(
            flagKey: flagKey,
            subjectKey: subjectKey,
          ),
          value: VariationCacheValue(
            allocationKey: allocationKey,
            variationKey: variation.key,
          ),
        ),
      );

      if (hasLoggedAssignment == true) {
        return;
      }
    }

    // TODO: Add assignments to queue to flush.
    try {
      if (_clientConfiguration.assignmentLogger != null) {
        _clientConfiguration.assignmentLogger!.logAssignment(event);
      }

      // Update the assignment cache
      _clientConfiguration.flagAssignmentCache.set(
        AssignmentCacheEntry(
          key: AssignmentCacheKey(
            flagKey: flagKey,
            subjectKey: subjectKey,
          ),
          value: VariationCacheValue(
            allocationKey: allocationKey ?? '__eppo_no_allocation',
            variationKey: variation?.key ?? '__eppo_no_variation',
          ),
        ),
      );
    } catch (error) {
      _logger.severe(
          'unable to log assignment event', error, StackTrace.current);
    }
  }

  void _logBanditAction(BanditEvent event) {
    final subjectKey = event.subject;
    final flagKey = event.featureFlag;
    final banditKey = event.bandit;
    final actionKey = event.action ?? '__eppo_no_action';

    // Check if this bandit action has been logged before
    final hasLoggedBanditAction = _clientConfiguration.banditActionCache.has(
      AssignmentCacheEntry(
        key: AssignmentCacheKey(
          flagKey: flagKey,
          subjectKey: subjectKey,
        ),
        value: BanditCacheValue(
          banditKey: banditKey,
          actionKey: actionKey,
        ),
      ),
    );

    if (hasLoggedBanditAction) {
      // Ignore repeat assignment
      return;
    }

    // If here, we have a new assignment to be logged
    try {
      if (_clientConfiguration.banditLogger != null) {
        _clientConfiguration.banditLogger!.logBanditEvent(event);
      }
      // TODO: Add bandit events to queue to flush if needed

      // Record in the assignment cache to deduplicate subsequent repeat assignments
      _clientConfiguration.banditActionCache.set(
        AssignmentCacheEntry(
          key: AssignmentCacheKey(
            flagKey: flagKey,
            subjectKey: subjectKey,
          ),
          value: BanditCacheValue(
            banditKey: banditKey,
            actionKey: actionKey,
          ),
        ),
      );
    } catch (error) {
      _logger.severe(
        'unable to log bandit action event',
        error,
        StackTrace.current,
      );
    }
  }

  ObfuscatedPrecomputedFlag? _getPrecomputedFlag(String flagKey) {
    final salt = _precomputedFlagStore.salt;

    if (salt == null) {
      _logger.warning('missing salt for flag store');
      return null;
    }

    final saltedAndHashedFlagKey = getMD5Hash(flagKey, salt: salt);
    return _precomputedFlagStore.get(saltedAndHashedFlagKey);
  }

  ObfuscatedPrecomputedBandit? _getPrecomputedBandit(String banditKey) {
    final salt = _precomputedBanditStore.salt;

    if (salt == null) {
      _logger.warning('missing salt for bandit store');
      return null;
    }

    final saltedAndHashedBanditKey = getMD5Hash(banditKey, salt: salt);
    return _precomputedBanditStore.get(saltedAndHashedBanditKey);
  }
}

/// Represents a variation in a feature flag
class Variation {
  /// The key of the variation
  final String key;

  /// The value of the variation (can be string, number, or boolean)
  final dynamic value;

  /// Creates a new variation
  const Variation({
    required this.key,
    required this.value,
  });

  /// Converts this variation to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }

  /// Creates a variation from a JSON map
  factory Variation.fromJson(Map<String, dynamic> json) {
    return Variation(
      key: json['key'] as String,
      value: json['value'],
    );
  }
}

/// Represents the result of a flag evaluation without detailed information
class FlagEvaluation {
  /// The key of the flag being evaluated
  final String flagKey;

  /// The format of the flag evaluation
  final String format;

  /// The key of the subject being evaluated
  final String subjectKey;

  /// The attributes of the subject
  final ContextAttributes subjectAttributes;

  /// The key of the allocation, if any
  final String? allocationKey;

  /// The variation assigned to the subject
  final Variation? variation;

  /// Extra logging information
  final Map<String, String> extraLogging;

  /// Whether to log this evaluation as an assignment event
  final bool doLog;

  /// Creates a new flag evaluation result
  const FlagEvaluation({
    required this.flagKey,
    required this.format,
    required this.subjectKey,
    required this.subjectAttributes,
    this.allocationKey,
    this.variation,
    Map<String, String>? extraLogging,
    bool? doLog,
  })  : extraLogging = extraLogging ?? const {},
        doLog = doLog ?? false;

  /// Converts this evaluation to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'flagKey': flagKey,
      'format': format,
      'subjectKey': subjectKey,
      'subjectAttributes': subjectAttributes.toJson(),
      if (allocationKey != null) 'allocationKey': allocationKey,
      if (variation != null) 'variation': variation?.toJson(),
      'extraLogging': extraLogging,
      'doLog': doLog,
    };
  }
}

/// Represents the details of an assignment, including variation, action, and evaluation details
class BanditEvaluation {
  /// The assigned variation value
  final String variation;

  /// The action associated with the assignment, if any
  final String? action;

  /// Creates a new assignment details object
  const BanditEvaluation({
    required this.variation,
    this.action,
  });
}
