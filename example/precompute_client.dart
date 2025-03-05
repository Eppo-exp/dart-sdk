import 'dart:io';
import 'package:eppo/eppo_sdk.dart';
import 'package:eppo/src/sdk_version.dart' as sdk;
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
    sdkPlatform: sdk.SdkPlatform.dart,
    throwOnFailedInitialization: false, // Don't throw on initialization failure
  );

  // Create precompute arguments
  final precomputeArgs = PrecomputeArguments(subject: subject);

  // Create client
  final client = EppoPrecomputedClient(sdkOptions, precomputeArgs);

  // Fetch precomputed flags
  await client.fetchPrecomputedFlags();

  // Print some example assignments
  print('\nExample flag assignments:');
  print('-------------------------');

  // Try to get some common flag types
  final stringValue =
      client.getStringAssignment('dart-test-flag-string', 'default-string');
  print('string-flag: $stringValue');

  final boolValue =
      client.getBooleanAssignment('dart-test-flag-boolean', false);
  print('boolean-flag: $boolValue');

  final intValue = client.getIntegerAssignment('dart-test-flag-integer', 0);
  print('integer-flag: $intValue');

  final numValue = client.getNumericAssignment('dart-test-flag-numeric', 0.0);
  print('numeric-flag: $numValue');

  final jsonValue = client.getJSONAssignment('dart-test-flag-json', {});
  print('json-flag: $jsonValue');

  exit(0);
}
