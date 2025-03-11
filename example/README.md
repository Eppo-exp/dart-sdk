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

## Key Concepts and Code Snippets

### Custom Assignment Logger

Create a custom logger to track flag assignments:

```dart
import 'package:eppo/eppo.dart';

class MyAssignmentLogger extends AssignmentLogger {
  @override
  void logAssignment(AssignmentEvent event) {
    print('logAssignment: ${event.featureFlag} ${event.variation} ${event.timestamp}');
  }
}
```

### Creating a Subject

Create a subject with attributes for targeted flag assignments:

```dart
final subject = Subject(
  subjectKey: 'user-123',
  subjectAttributes: ContextAttributes(
    categoricalAttributes: {'country': 'US', 'device': 'mobile'},
    numericAttributes: {'age': 30, 'visits': 5},
  ),
);
final subjectEvaluation = SubjectEvaluation(subject: subject);
```

### Providing Bandit Actions

When using bandit algorithms, you must provide actions during initialization:

```dart
// Create a subject evaluation with bandit actions
final subjectEvaluation = SubjectEvaluation(
  subject: Subject(
    subjectKey: 'user-identifier',
    subjectAttributes: ContextAttributes(
      categoricalAttributes: {'country': 'usa'},
      numericAttributes: {'age': 30},
    ),
  ),
  banditActions: {
    'nike': {
      'brand_affinity': 0.4,
      'from': 'usa',
    }
  },
);
```

### SDK Initialization

Initialize the SDK with your key and configuration:

```dart
final clientConfiguration = ClientConfiguration(
  sdkPlatform: SdkPlatform.dart,
  assignmentLogger: MyAssignmentLogger(),
);

await Eppo.initialize(
  'your-sdk-key', 
  subjectEvaluation, 
  clientConfiguration
);
```

### Evaluating Feature Flags

#### String Flag

```dart
final stringValue = Eppo.getStringAssignment('dart-test-flag-string', 'default-string');
print('string-flag: $stringValue');
```

#### Boolean Flag

```dart
final boolValue = Eppo.getBooleanAssignment('dart-test-flag-boolean', false);
print('boolean-flag: $boolValue');
```

#### Integer Flag

```dart
final intValue = Eppo.getIntegerAssignment('dart-test-flag-integer', 0);
print('integer-flag: $intValue');
```

#### Numeric Flag

```dart
final numValue = Eppo.getNumericAssignment('dart-test-flag-numeric', 0.0);
print('numeric-flag: $numValue');
```

#### JSON Flag

```dart
final jsonValue = Eppo.getJSONAssignment('dart-test-flag-json', {});
print('json-flag: $jsonValue');
```

#### Bandit Action

```dart
final banditValue = Eppo.getBanditAction('update-highlights-bandit', 'default-bandit');
print('bandit-flag: action=${banditValue.action} variation=${banditValue.variation}');
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

## Further Reading

For more advanced usage and configuration options, see the [full documentation](https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/).
