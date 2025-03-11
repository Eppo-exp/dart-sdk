# Eppo SDK for Dart and Flutter

The Eppo SDK enables feature flags and experiments in your Dart and Flutter applications with only a few lines of code.

The SDK handles all the complexity of feature flag evaluation and experiment assignment locally in your application. 
The guide below will walk you through installing the SDK and implementing your first feature flag, experiment, and contextual bandit.

See [https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/](https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/) for detailed usage instructions.

```dart
import 'package:eppo/eppo.dart';

// Initialize the SDK
await Eppo.initialize(
  'your-sdk-key',
  SubjectEvaluation(
    subject: Subject(
      subjectKey: 'user-identifier'
    )
  )
);

// Make an assignment
final String variation = Eppo.getStringAssignment(
  'my-neat-feature',
  'default-value',
);

// Render different components based on assignment
switch(variation) {
  case 'landing-page-a':
    return renderLandingPageA();
  case 'landing-page-b':
    return renderLandingPageB();
  default:
    return renderLandingPageC();
}
```

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  eppo: ^1.0.0
```

## Contributing

```bash
dart pub get
dart analyze
```

### Running the tests

```bash
dart test
```

### Running the benchmarks

The SDK includes a benchmark for evaluating the performance of the SDK when evaluating feature flags.

```bash
dart run benchmark/flag_evaluation.dart <sdk-key> <subject-key>
```

The SDK also includes a benchmark for evaluating the performance of the SDK when fetching configurations.

```bash
dart run benchmark/configuration_fetch.dart <sdk-key> <subject-key>
```
