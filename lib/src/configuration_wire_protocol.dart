enum FormatEnum { precomputed }

/// Dart representation of the Precomputed server response
class ObfuscatedPrecomputedConfigurationResponse {
  /// Format of the configuration, always PRECOMPUTED
  final FormatEnum format = FormatEnum.precomputed;

  /// Always true, indicating this is an obfuscated configuration
  final bool obfuscated = true;

  /// When the configuration was created
  final String createdAt;

  /// Optional environment information
  final String? environment;

  /// Salt used for hashing md5-encoded strings
  final String salt;

  /// PrecomputedFlag ships values as string and uses ValueType to cast back on the client.
  /// Values are obfuscated as strings, so a separate Obfuscated interface is not needed for flags.
  final Map<MD5String, ObfuscatedPrecomputedFlag> flags;

  /// Map of hashed flag keys to obfuscated precomputed bandits
  final Map<MD5String, ObfuscatedPrecomputedBandit> bandits;

  ObfuscatedPrecomputedConfigurationResponse({
    required this.createdAt,
    this.environment,
    required this.salt,
    required this.flags,
    required this.bandits,
  });

  factory ObfuscatedPrecomputedConfigurationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ObfuscatedPrecomputedConfigurationResponse(
      createdAt: json['createdAt'] as String,
      environment:
          json['environment'] != null
              ? (json['environment'] is String
                  ? json['environment'] as String
                  : (json['environment'] as Map<String, dynamic>)['name']
                      as String)
              : null,
      salt: json['salt'] as String,
      flags: (json['flags'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, ObfuscatedPrecomputedFlag.fromJson(value)),
      ),
      bandits:
          json['bandits'] != null
              ? (json['bandits'] as Map<String, dynamic>).map(
                (key, value) =>
                    MapEntry(key, ObfuscatedPrecomputedBandit.fromJson(value)),
              )
              : {},
    );
  }
}

/// Represents a precomputed flag with a value and type
class ObfuscatedPrecomputedFlag {
  /// Optional flag key
  final MD5String? flagKey;

  /// Optional allocation key
  final MD5String? allocationKey;

  /// Optional variation key
  final MD5String? variationKey;

  /// Type of variation
  final String variationType;

  /// Optional extra logging information
  final Map<String, String>? extraLogging;

  /// Whether to log this flag
  final bool doLog;

  /// The base64 encoded variation value
  final Base64String variationValue;

  ObfuscatedPrecomputedFlag({
    this.flagKey,
    this.allocationKey,
    this.variationKey,
    required this.variationType,
    this.extraLogging,
    required this.doLog,
    required this.variationValue,
  });

  factory ObfuscatedPrecomputedFlag.fromJson(Map<String, dynamic> json) {
    return ObfuscatedPrecomputedFlag(
      flagKey: json['flagKey'] as MD5String?,
      allocationKey: json['allocationKey'] as MD5String?,
      variationKey: json['variationKey'] as MD5String?,
      variationType: json['variationType'] as String,
      extraLogging:
          json['extraLogging'] != null
              ? (json['extraLogging'] as Map<String, dynamic>)
                  .cast<String, String>()
              : null,
      doLog: json['doLog'] as bool,
      variationValue: json['variationValue'] as Base64String,
    );
  }
}

/// Represents an obfuscated precomputed bandit
class ObfuscatedPrecomputedBandit {
  /// Obfuscated bandit key
  final Base64String banditKey;

  /// Obfuscated action
  final Base64String action;

  /// Obfuscated model version
  final Base64String modelVersion;

  /// Obfuscated numeric attributes for the action
  final Map<Base64String, Base64String> actionNumericAttributes;

  /// Obfuscated categorical attributes for the action
  final Map<Base64String, Base64String> actionCategoricalAttributes;

  /// Probability of taking this action
  final double actionProbability;

  /// Gap to optimal action
  final double optimalityGap;

  ObfuscatedPrecomputedBandit({
    required this.banditKey,
    required this.action,
    required this.modelVersion,
    required this.actionNumericAttributes,
    required this.actionCategoricalAttributes,
    required this.actionProbability,
    required this.optimalityGap,
  });

  factory ObfuscatedPrecomputedBandit.fromJson(Map<String, dynamic> json) {
    return ObfuscatedPrecomputedBandit(
      banditKey: json['banditKey'] as String,
      action: json['action'] as String,
      modelVersion: json['modelVersion'] as String,
      actionNumericAttributes: (json['actionNumericAttributes']
              as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value)),
      actionCategoricalAttributes: (json['actionCategoricalAttributes']
              as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value)),
      actionProbability: json['actionProbability'] as double,
      optimalityGap: json['optimalityGap'] as double,
    );
  }
}

/// Type alias for MD5 hash strings
typedef MD5String = String;

/// Type alias for Base64 encoded strings
typedef Base64String = String;
