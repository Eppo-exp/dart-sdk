import 'dart:convert';

import 'package:eppo/eppo_sdk.dart';
import 'package:eppo/src/sdk_version.dart' as sdk;
import 'package:logging/logging.dart';

// Parameters for precomputed flags requests
class SdkOptions {
  /// SDK key for authentication
  final String sdkKey;

  /// Platform for the SDK
  final sdk.SdkPlatform sdkPlatform;

  /// Assignment logger
  final AssignmentLogger? assignmentLogger;

  /// Base URL for API requests
  final String? baseUrl;

  /// Request timeout in milliseconds
  final int? requestTimeoutMs;

  /// Whether to throw on failed initialization
  final bool? throwOnFailedInitialization;

  /// Optional API client for testing
  final EppoApiClient? apiClient;

  /// Creates a new set of precomputed flags request parameters
  const SdkOptions({
    required this.sdkKey,
    required this.sdkPlatform,
    this.assignmentLogger,
    this.baseUrl,
    this.requestTimeoutMs,
    this.throwOnFailedInitialization,
    this.apiClient,
  });
}

/// Options for creating a precomputed client
class PrecomputeArguments {
  /// Subject information
  final Subject subject;

  /// Bandit actions
  final Map<String, Map<String, Map<String, dynamic>>>? banditActions;

  const PrecomputeArguments({
    required this.subject,
    this.banditActions,
  });
}

/// Client for evaluating precomputed feature flags and bandits
class EppoPrecomputedClient {
  final SdkOptions _sdkOptions;
  final PrecomputeArguments _precompute;
  final ConfigurationStore<ObfuscatedPrecomputedFlag> _precomputedFlagStore;
  EppoApiClient? _apiClient;
  final Logger _logger = Logger('EppoPrecomputedClient');

  // TODO: Add assignment cache
  /// Cache for tracking logged assignments to prevent duplicates
  // AssignmentCache? assignmentCache;

  /// Creates a new precomputed client
  EppoPrecomputedClient(SdkOptions sdkOptions, PrecomputeArguments precompute)
      : _sdkOptions = sdkOptions,
        _precompute = precompute,
        _precomputedFlagStore =
            InMemoryConfigurationStore<ObfuscatedPrecomputedFlag>(),
        _apiClient = sdkOptions.apiClient;

  /// Fetches precomputed flags from the server
  Future<void> fetchPrecomputedFlags() async {
    final throwOnFailedInitialization =
        _sdkOptions.throwOnFailedInitialization ?? false;

    // Only create a new API client if one wasn't provided in the options
    _apiClient ??= EppoApiClient(
      sdkKey: _sdkOptions.sdkKey,
      sdkVersion: sdk.getSdkVersion(),
      sdkPlatform: _sdkOptions.sdkPlatform,
      baseUrl: _sdkOptions.baseUrl,
      requestTimeoutMs: _sdkOptions.requestTimeoutMs,
    );

    try {
      final response = await _apiClient!.fetchPrecomputedFlags(
        subjectKey: _precompute.subject.subjectKey,
        subjectAttributes: _precompute.subject.subjectAttributes,
        banditActions: _precompute.banditActions ?? {},
      );

      // Update the store with the received salt and format
      if (response.salt.isEmpty) {
        _logger.warning('$defaultLoggerPrefix Received empty salt from server');
      }
      _precomputedFlagStore.update(response.flags,
          salt: response.salt, format: response.format.toString());

      _logger
          .info('$defaultLoggerPrefix Successfully fetched precomputed flags');
    } catch (e) {
      if (throwOnFailedInitialization) {
        throw Exception('Failed to initialize precomputed flags: $e');
      } else {
        _logger.severe(
          '$defaultLoggerPrefix Failed to initialize precomputed flags: $e',
        );
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
            _logger.warning('$defaultLoggerPrefix Error parsing JSON: $e');
            return defaultValue;
          }
        } else if (value is Map) {
          // If the value is already a Map (decoded from JSON), convert it to Map<String, dynamic>
          try {
            return Map<String, dynamic>.from(value);
          } catch (e) {
            _logger.warning('$defaultLoggerPrefix Error converting Map: $e');
            return defaultValue;
          }
        }
        return defaultValue;
      },
    );
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
        '$defaultLoggerPrefix No assigned variation. Flag not found: $flagKey',
      );
      return defaultValue;
    }

    // Add type checking before proceeding
    if (!checkTypeMatch(expectedType, precomputedFlag.variationType)) {
      final errorMessage =
          '$defaultLoggerPrefix Type mismatch: expected ${expectedType.name} but flag $flagKey has type ${precomputedFlag.variationType.name}';
      _logger.warning(errorMessage);
      return defaultValue;
    }

    // Decode the variation value based on its type
    final decodedValue = decodeValue(precomputedFlag.variationValue,
        precomputedFlag.variationType.toString().split('.').last);

    final result = FlagEvaluation(
      flagKey: flagKey,
      format: _precomputedFlagStore.getFormat() ?? '',
      subjectKey: _precompute.subject.subjectKey,
      subjectAttributes: _precompute.subject.subjectAttributes,
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
      _logger.warning('$defaultLoggerPrefix Error transforming value: $error');
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
      timestamp: DateTime.now().toIso8601String(),
      subjectAttributes: subjectAttributes.toJson(),
      metaData: _buildLoggerMetadata(),
      evaluationDetails: null,
    );

    // TODO: Add assignment cache
    // Check if we've already logged this assignment
    // if (variation != null && allocationKey != null) {
    //   final hasLoggedAssignment = assignmentCache?.has(
    //     flagKey: flagKey,
    //     subjectKey: subjectKey,
    //     allocationKey: allocationKey,
    //     variationKey: variation.key,
    //   );

    //   if (hasLoggedAssignment == true) {
    //     return;
    //   }
    // }

    // TODO: Add assignments to queue to flush.
    try {
      if (_sdkOptions.assignmentLogger != null) {
        _sdkOptions.assignmentLogger!.logAssignment(event);
      }

      // Update the assignment cache
      // assignmentCache?.set(
      //   flagKey: flagKey,
      //   subjectKey: subjectKey,
      //   allocationKey: allocationKey ?? '__eppo_no_allocation',
      //   variationKey: variation?.key ?? '__eppo_no_variation',
      // );
    } catch (error) {
      _logger.severe(
          '$defaultLoggerPrefix Error logging assignment event: $error');
    }
  }

  /// Builds metadata for the logger
  Map<String, dynamic> _buildLoggerMetadata() {
    return {
      'sdkVersion': sdk.getSdkVersion(),
      'sdkName': sdk.SdkPlatform.dart.toString(),
    };
  }

  ObfuscatedPrecomputedFlag? _getPrecomputedFlag(String flagKey) {
    final salt = _precomputedFlagStore.salt;

    if (salt == null) {
      _logger.warning('$defaultLoggerPrefix Missing salt for flag store');
      return null;
    }

    final saltedAndHashedFlagKey = getMD5Hash(flagKey, salt);
    return _precomputedFlagStore.get(saltedAndHashedFlagKey);
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
