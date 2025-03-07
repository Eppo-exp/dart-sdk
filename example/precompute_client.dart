import 'dart:io';
import 'package:eppo/eppo.dart';
import 'package:logging/logging.dart';

/// This example demonstrates how to use the EppoPrecomputedClient to fetch and evaluate
/// feature flags for a given subject.
///
/// Usage:
/// ```
/// dart example/load_precompute_response.dart <sdk-key> [subject-key]
/// ```
///
/// The SDK key is required and should be a valid Eppo SDK key.
/// The subject key is optional and defaults to 'user-123'.
void main(List<String> args) async {
  // Configure logging
  Logger.root.level = Level.INFO;

  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart example/load_precompute_response.dart <sdk-key> [subject-key]',
    );
    exit(1);
  }

  final sdkKey = args[0];
  final subjectKey = args.length > 1 ? args[1] : 'user-123';

  print('Using SDK key: $sdkKey');
  print('Using subject key: $subjectKey');

  // Create subject attributes
  final attributes = ContextAttributes(
    categoricalAttributes: {'country': 'US', 'device': 'mobile'},
    numericAttributes: {'age': 30, 'visits': 5},
  );

  // Create subject
  final subject = Subject(
    subjectKey: subjectKey,
    subjectAttributes: attributes,
  );

  // Create SDK options
  final sdkOptions = SdkOptions(
    sdkKey: sdkKey,
    sdkPlatform: SdkPlatform.dart,
    throwOnFailedInitialization: false, // Don't throw on initialization failure
  );

  // Create precompute arguments
  final precomputeArgs = PrecomputeArguments(subject: subject);

  // Create client
  // fetch precomputed flags
  await Eppo.initialize(precomputeArgs, sdkOptions);

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
