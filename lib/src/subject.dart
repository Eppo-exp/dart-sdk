/// Subject information for flag evaluation
class Subject {
  /// The subject key
  final String subjectKey;

  /// The subject attributes
  final ContextAttributes subjectAttributes;

  /// Creates a new subject
  const Subject({
    required this.subjectKey,
    required this.subjectAttributes,
  });
}

/// Attributes map type
typedef Attributes = Map<String, dynamic>;

/// Context attributes with numeric and categorical attributes
class ContextAttributes {
  /// Numeric attributes
  final Attributes numericAttributes;

  /// Categorical attributes
  final Attributes categoricalAttributes;

  /// Creates a new set of context attributes
  const ContextAttributes({
    this.numericAttributes = const {},
    this.categoricalAttributes = const {},
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'numericAttributes': numericAttributes,
      'categoricalAttributes': categoricalAttributes,
    };
  }
}
