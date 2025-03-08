import 'dart:io';
import 'package:eppo/eppo.dart';
import 'package:logging/logging.dart';

class MyAssignmentLogger extends AssignmentLogger {
  @override
  void logAssignment(AssignmentEvent event) {
    print(
        'logAssignment: ${event.featureFlag} ${event.variation} ${event.timestamp}');
  }
}

/// This example demonstrates how to use the Eppo SDK to fetch and evaluate
/// feature flags and bandit actions for a given subject.
///
/// The SDK key is required and should be a valid Eppo SDK key.
/// The subject key is optional and defaults to 'user-123'.
void main(List<String> args) async {
  // Configure logging
  Logger.root.level = Level.INFO;

  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart example/example_precompute_client.dart <sdk-key> <subject-key>',
    );
    exit(1);
  }

  final sdkKey = args[0];
  final subjectKey = args.length > 1 ? args[1] : 'user-123';

  // Create subject with attributes
  final subject = Subject(
    subjectKey: subjectKey,
    subjectAttributes: ContextAttributes(
      categoricalAttributes: {'country': 'US', 'device': 'mobile'},
      numericAttributes: {'age': 30, 'visits': 5},
    ),
  );
  final subjectEvaluation = SubjectEvaluation(subject: subject);

  // Create SDK options
  final clientConfiguration = ClientConfiguration(
    sdkPlatform: SdkPlatform.dart,
    assignmentLogger: MyAssignmentLogger(),
  );

  // Initialize the SDK
  await Eppo.initialize(sdkKey, subjectEvaluation, clientConfiguration);

  // Print some example assignments
  print('\nExample flag assignments:');
  print('-------------------------');

  // Get precomputed assignments
  final stringValue =
      Eppo.getStringAssignment('dart-test-flag-string', 'default-string');
  print('string-flag: $stringValue');

  final boolValue = Eppo.getBooleanAssignment('dart-test-flag-boolean', false);
  print('boolean-flag: $boolValue');

  final intValue = Eppo.getIntegerAssignment('dart-test-flag-integer', 0);
  print('integer-flag: $intValue');

  final numValue = Eppo.getNumericAssignment('dart-test-flag-numeric', 0.0);
  print('numeric-flag: $numValue');

  final jsonValue = Eppo.getJSONAssignment('dart-test-flag-json', {});
  print('json-flag: $jsonValue');

  // Get precomputed bandit assignments
  final banditValue =
      Eppo.getBanditAction('update-highlights-bandit', 'default-bandit');
  print(
      'bandit-flag: action=${banditValue.action} variation=${banditValue.variation}');

  exit(0);
}
