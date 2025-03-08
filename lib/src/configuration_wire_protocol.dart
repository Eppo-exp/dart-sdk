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
    // Safely convert the flags map to Map<String, dynamic>
    final flagsMap = json['flags'] as Map;
    final typedFlagsMap = Map<String, dynamic>.from(flagsMap);

    final response = ObfuscatedPrecomputedConfigurationResponse(
      createdAt: json['createdAt'] as String,
      environment: json['environment'] != null
          ? (json['environment'] is String
              ? json['environment'] as String
              : (json['environment'] as Map<String, dynamic>)['name'] as String)
          : null,
      salt: json['salt'] as String,
      flags: typedFlagsMap.map(
        (key, value) {
          return MapEntry(
              key,
              ObfuscatedPrecomputedFlag.fromJson(
                  value as Map<String, dynamic>));
        },
      ),
      bandits: json['bandits'] != null
          ? (json['bandits'] as Map).cast<String, dynamic>().map(
                (key, value) => MapEntry(
                    key,
                    ObfuscatedPrecomputedBandit.fromJson(
                        value as Map<String, dynamic>)),
              )
          : {},
    );

    return response;
  }
}

/// Represents a precomputed flag with a value and type
class ObfuscatedPrecomputedFlag {
  /// Optional allocation key
  final Base64String? allocationKey;

  /// Optional variation key
  final Base64String? variationKey;

  /// Type of variation
  final VariationType variationType;

  /// Optional extra logging information
  final Map<String, Base64String>? extraLogging;

  /// Whether to log this flag
  final bool doLog;

  /// The base64 encoded variation value
  final Base64String variationValue;

  ObfuscatedPrecomputedFlag({
    this.allocationKey,
    this.variationKey,
    required this.variationType,
    this.extraLogging,
    required this.doLog,
    required this.variationValue,
  });

  factory ObfuscatedPrecomputedFlag.fromJson(Map<String, dynamic> json) {
    // Handle extraLogging safely
    Map<String, Base64String>? extraLoggingMap;
    if (json['extraLogging'] != null) {
      final extraLoggingRaw = json['extraLogging'] as Map;
      extraLoggingMap = Map<String, Base64String>.fromEntries(
        extraLoggingRaw.entries.map((entry) =>
            MapEntry(entry.key.toString(), entry.value as Base64String)),
      );
    }

    final flag = ObfuscatedPrecomputedFlag(
      allocationKey: json['allocationKey'] as String?,
      variationKey: json['variationKey'] as String?,
      variationType: _parseVariationType(json['variationType'] as String),
      extraLogging: extraLoggingMap,
      doLog: json['doLog'] as bool,
      variationValue: json['variationValue'] as String,
    );

    return flag;
  }

  // Helper method to parse variation type case-insensitively
  static VariationType _parseVariationType(String typeStr) {
    final normalized = typeStr.toLowerCase();
    return VariationType.values.firstWhere(
      (type) => type.toString().split('.').last == normalized,
      orElse: () => throw ArgumentError('Invalid variation type: $typeStr'),
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
    // Safely handle the numeric attributes map
    final numericAttrsRaw = json['actionNumericAttributes'] as Map;
    final numericAttrs = Map<String, String>.fromEntries(
      numericAttrsRaw.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value.toString())),
    );

    // Safely handle the categorical attributes map
    final categoricalAttrsRaw = json['actionCategoricalAttributes'] as Map;
    final categoricalAttrs = Map<String, String>.fromEntries(
      categoricalAttrsRaw.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value.toString())),
    );

    return ObfuscatedPrecomputedBandit(
      banditKey: json['banditKey'] as String,
      action: json['action'] as String,
      modelVersion: json['modelVersion'] as String,
      actionNumericAttributes: numericAttrs,
      actionCategoricalAttributes: categoricalAttrs,
      actionProbability: (json['actionProbability'] as num).toDouble(),
      optimalityGap: (json['optimalityGap'] as num).toDouble(),
    );
  }
}

/// Type alias for MD5 hash strings
typedef MD5String = String;

/// Type alias for Base64 encoded strings
typedef Base64String = String;

/// Enumeration of supported variation types
enum VariationType {
  /// String type variations
  string,

  /// Boolean type variations
  boolean,

  /// Integer type variations
  integer,

  /// Numeric (double) type variations
  numeric,

  /// JSON object type variations
  json,
}

/// Checks if the expected type matches the actual type
bool checkTypeMatch(VariationType expected, VariationType actual) {
  if (expected == actual) {
    return true;
  }

  // Special case: integer is compatible with numeric
  if (expected == VariationType.numeric && actual == VariationType.integer) {
    return true;
  }

  return false;
}
