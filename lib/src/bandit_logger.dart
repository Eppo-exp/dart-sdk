class BanditEvent {
  /// The timestamp when the event occurred
  final DateTime timestamp;

  /// The feature flag key
  final String featureFlag;

  /// The bandit key
  final String bandit;

  /// The subject key
  final String subject;

  /// The action associated with the bandit
  final String? action;

  /// The probability of the action
  final double? actionProbability;

  /// The optimality gap
  final double? optimalityGap;

  /// The model version
  final String? modelVersion;

  /// Numeric attributes of the subject
  final Map<String, double>? subjectNumericAttributes;

  /// Categorical attributes of the subject
  final Map<String, String>? subjectCategoricalAttributes;

  /// Numeric attributes of the action
  final Map<String, double>? actionNumericAttributes;

  /// Categorical attributes of the action
  final Map<String, String>? actionCategoricalAttributes;

  /// Metadata about the SDK
  final Map<String, dynamic> metaData;

  /// Creates a new bandit event
  BanditEvent({
    required this.timestamp,
    required this.featureFlag,
    required this.bandit,
    required this.subject,
    this.action,
    this.actionProbability,
    this.optimalityGap,
    this.modelVersion,
    this.subjectNumericAttributes,
    this.subjectCategoricalAttributes,
    this.actionNumericAttributes,
    this.actionCategoricalAttributes,
    required this.metaData,
  });
}

/// Interface for logging bandit events
abstract class BanditLogger {
  /// Logs a bandit event
  void logBanditEvent(BanditEvent event);
}
