# Eppo Feature Flagging SDK Example

This example demonstrates how to use the Eppo SDK for feature flagging and experimentation in a Dart application.

## What This Example Shows

- How to initialize the Eppo SDK
- How to create and configure a subject with attributes
- How to evaluate different types of feature flags (string, boolean, integer, numeric, JSON)
- How to use bandit actions
- How to implement a custom assignment logger

## Running the Example

To run this example, you'll need a valid Eppo SDK key. You can get one by signing up at [geteppo.com](https://geteppo.com).

```bash
# From the root of the eppo package
dart run example/main.dart <your-sdk-key> [optional-subject-key]
```

If you don't provide a subject key, the example will use 'user-123' as the default.

## Example Code

```dart
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

void main(List<String> args) async {
  // Configure logging
  Logger.root.level = Level.INFO;

  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart example/main.dart <sdk-key> <subject-key>',
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
  await Eppo.initialize(sdkKey, subjectEvaluation, clientConfiguration: clientConfiguration);

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
}
```

## Expected Output

When run successfully, you should see output similar to:

```
Example flag assignments:
-------------------------
string-flag: value-from-eppo
boolean-flag: true
integer-flag: 42
numeric-flag: 3.14
json-flag: {key: value, nested: {property: example}}
bandit-flag: action=recommended-action variation=variation-1
```

## Key Concepts

### Subject

A subject represents the entity for which you're evaluating feature flags. This could be a user, device, or any other entity in your system. You can attach attributes to subjects to enable targeted flag assignments.

### Feature Flags

Feature flags allow you to control the behavior of your application without deploying new code. Eppo supports various types of flags:

- **String flags**: For text values
- **Boolean flags**: For on/off features
- **Integer flags**: For whole number values
- **Numeric flags**: For decimal values
- **JSON flags**: For complex configuration objects

### Bandit Actions

Bandit algorithms dynamically select the best action based on performance. This is useful for recommendation systems and other optimization scenarios.

### Assignment Logging

The SDK can log flag assignments to help you track which variations are being served to which subjects. You can implement a custom logger to integrate with your analytics system.

## Further Reading

For more advanced usage and configuration options, see the [full documentation](https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/).
