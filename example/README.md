# Eppo Feature Flagging SDK Example

This example demonstrates how to use the Eppo SDK for feature flagging and experimentation in a Dart application, showcasing both the traditional singleton API and the new multi-instance API.

## What This Example Shows

- **Singleton API**: Traditional single-user SDK usage
- **Multi-Instance API**: Managing multiple user contexts (anonymous vs. logged-in users)
- **User State Transitions**: Handling anonymous → logged-in user flows
- **API Coexistence**: How both APIs work together seamlessly
- **Instance Management**: Creating, using, and cleaning up user instances
- **Different User Types**: Anonymous users, free users, premium users with different attributes
- **Feature Flag Types**: String, boolean, integer, numeric, JSON flags
- **Bandit Actions**: Personalized recommendations and content selection
- **Custom Assignment Logger**: Tracking flag assignments for analytics

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

## Example Output Structure

When run successfully, you'll see a comprehensive demonstration organized into 7 parts:

```
🚀 Eppo SDK Multi-Instance Example
===================================

📱 Part 1: Singleton API
-------------------------
✅ Initialized SDK for logged-in user: user-123
   Premium feature enabled: true

👥 Part 2: Multi-Instance API
------------------------------
✅ Created anonymous user instance
✅ Created second user instance

🔍 Part 3: Flag Evaluations Per User
------------------------------------
Anonymous user flags:
   Premium feature: false
   Show signup banner: false

Second user flags:
   Premium feature: false
   Show signup banner: false

🔗 Part 4: API Coexistence
--------------------------
Singleton API result: true
Multi-instance API (same subject): true
Results match: true

📊 Part 5: Instance Management
------------------------------
Active subjects: [user-123, anonymous-session-abc123, user-456]
Total instances: 3

Cleaning up anonymous user...
Active subjects after cleanup: [user-123, user-456]

🔄 Part 6: User State Transition
---------------------------------
Simulating anonymous → logged-in user transition...
Before login - signup banner: false
After login - premium feature: true

✨ Example completed successfully!
Final active subjects: [user-123, user-456, user-789]
```

## Key API Additions

### Multi-Instance Usage

```dart
// Create instances for different users
final anonymousUser = await Eppo.forSubject(
  'anonymous-session-123',
  subjectAttributes: ContextAttributes(
    categoricalAttributes: {'user_type': 'anonymous'},
    numericAttributes: {'session_count': 1},
  ),
);

final loggedInUser = await Eppo.forSubject(
  'user-456',
  subjectAttributes: ContextAttributes(
    categoricalAttributes: {'user_type': 'authenticated', 'plan': 'premium'},
    numericAttributes: {'age': 30, 'account_age_days': 180},
  ),
);

// Use per-user flag evaluations
bool showSignup = anonymousUser.getBooleanAssignment('signup-banner', false);
bool premiumFeature = loggedInUser.getBooleanAssignment('premium-feature', false);
```

### Instance Management

```dart
// Check active instances
List<String> activeUsers = Eppo.activeSubjects;

// Clean up when user logs out
Eppo.removeSubject('anonymous-session-123');

// Reset all instances
Eppo.reset();
```

## Further Reading

For more advanced usage and configuration options, see the [full documentation](https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/).
