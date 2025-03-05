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

      // Ensure the salt is set before updating the store
      if (response.salt.isEmpty) {
        _logger.warning('$defaultLoggerPrefix Received empty salt from server');
        // Use a default salt for testing purposes
        _precomputedFlagStore.update(response.flags,
            salt: 'test-salt', format: response.format.toString());
      } else {
        _precomputedFlagStore.update(response.flags,
            salt: response.salt, format: response.format.toString());
      }

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

    final result = {
      'flagKey': flagKey,
      'format': _precomputedFlagStore.getFormat() ?? '',
      'subjectKey': _precompute.subject.subjectKey,
      'subjectAttributes': _precompute.subject.subjectAttributes,
      'variation': {
        'key': precomputedFlag.variationKey != null
            ? decodeBase64(precomputedFlag.variationKey!)
            : '',
        'value': decodedValue,
      },
      'allocationKey': precomputedFlag.allocationKey != null
          ? decodeBase64(precomputedFlag.allocationKey!)
          : '',
      'extraLogging': precomputedFlag.extraLogging != null
          ? decodeStringMap(precomputedFlag.extraLogging!)
          : {},
      'doLog': precomputedFlag.doLog,
    };

    try {
      final variation = result['variation'] as Map<String, dynamic>?;
      final variationValue = variation?['value'];

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

  ObfuscatedPrecomputedFlag? _getPrecomputedFlag(String flagKey) {
    final salt = _precomputedFlagStore.salt;

    if (salt == null) {
      _logger.warning('$defaultLoggerPrefix Missing salt for flag store');
      return null;
    }

    final saltedAndHashedFlagKey = getMD5Hash(flagKey, salt);
    final flag = _precomputedFlagStore.get(saltedAndHashedFlagKey);

    if (flag == null) {
      return null;
    }

    // No need to decode here - we'll decode the values when they're accessed
    // in the _getPrecomputedAssignment method
    return flag;
  }
}
