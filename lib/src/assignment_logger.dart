/// Represents an event for logging an assignment
class AssignmentEvent {
  /// The allocation the subject was assigned to
  final String? allocation;

  /// The experiment identifier
  final String? experiment;

  /// The feature flag identifier
  final String featureFlag;

  /// The format of the assignment
  final String format;

  /// The variation key that was assigned
  final String? variation;

  /// The subject identifier
  final String subject;

  /// The timestamp of the assignment
  final String timestamp;

  /// The subject attributes
  final Map<String, dynamic>? subjectAttributes;

  /// Additional metadata
  final Map<String, dynamic>? metaData;

  /// Details about the evaluation
  final Map<String, dynamic>? evaluationDetails;

  /// Creates a new assignment event
  const AssignmentEvent({
    this.allocation,
    this.experiment,
    required this.featureFlag,
    required this.format,
    this.variation,
    required this.subject,
    required this.timestamp,
    this.subjectAttributes,
    this.metaData,
    this.evaluationDetails,
  });

  /// Converts this assignment event to a JSON map
  Map<String, dynamic> toJson() {
    return {
      if (allocation != null) 'allocation': allocation,
      if (experiment != null) 'experiment': experiment,
      'featureFlag': featureFlag,
      'format': format,
      if (variation != null) 'variation': variation,
      'subject': subject,
      'timestamp': timestamp,
      if (subjectAttributes != null) 'subjectAttributes': subjectAttributes,
      if (metaData != null) 'metaData': metaData,
      if (evaluationDetails != null) 'evaluationDetails': evaluationDetails,
    };
  }
}

/// Interface for logging assignment events
abstract class AssignmentLogger {
  /// Logs an assignment event
  void logAssignment(AssignmentEvent event);
}
