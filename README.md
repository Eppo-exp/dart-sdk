# Eppo SDK for Dart and Flutter

The Eppo SDK enables feature flags and experiments in your Dart and Flutter applications with only a few lines of code.

The SDK handles all the complexity of feature flag evaluation and experiment assignment locally in your application. 
The guide below will walk you through installing the SDK and implementing your first feature flag, experiment, and contextual bandit.

See [https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/](https://docs.geteppo.com/sdks/client-sdks/dart/quickstart/) for detailed usage instructions.

## Basic Usage (Singleton)

For simple applications with a single user context:

```dart
import 'package:eppo/eppo.dart';

// Initialize the SDK
await Eppo.initialize(
  'your-sdk-key',
  SubjectEvaluation(
    subject: Subject(
      subjectKey: 'user-123',
      subjectAttributes: ContextAttributes(
        categoricalAttributes: {
          'country': 'US',
          'device_type': 'mobile',
          'subscription_plan': 'premium',
        },
        numericAttributes: {
          'age': 28,
          'account_age_days': 180,
        },
      ),
    ),
  ),
  ClientConfiguration(),
);

// Make an assignment
final String variation = Eppo.getStringAssignment(
  'homepage-redesign',
  'control',
);

// Render different components based on assignment
if (variation == 'variant-a') {
  print('Showing homepage variant A');
} else if (variation == 'variant-b') {
  print('Showing homepage variant B');
} else {
  print('Showing homepage control');
}
```

## Multi-Instance Usage (Recommended)

For applications that need to handle both logged-out and logged-in users, or multiple user contexts:

### Setup

First, initialize the SDK with any user (this sets up shared configuration):

```dart
import 'package:eppo/eppo.dart';

// Initialize SDK with initial user
await Eppo.initialize(
  'your-sdk-key',
  SubjectEvaluation(
    subject: Subject(subjectKey: 'initial-user'),
  ),
  ClientConfiguration(),
);
```

### Logged-Out Users (Anonymous)

For users who haven't logged in yet, use anonymous identifiers with basic device/session attributes:

```dart
// Create instance for anonymous user
final anonymousUser = await Eppo.forSubject(
  SubjectEvaluation(
    subject: Subject(
      subjectKey: 'anonymous-abc123def', // Use session ID
      subjectAttributes: ContextAttributes(
        categoricalAttributes: {
          'user_type': 'anonymous',
          'device_type': 'mobile',
          'platform': 'ios',
          'country': 'US',
          'referrer_source': 'google',
          'app_version': '2.1.0',
        },
        numericAttributes: {
          'session_count': 1,
          'days_since_install': 0,
        },
      ),
    ),
  ),
);

// Get feature flags for anonymous user
bool showSignupBanner = anonymousUser.getBooleanAssignment('signup-banner', false);
String onboardingFlow = anonymousUser.getStringAssignment('onboarding-flow', 'standard');
int maxFreeArticles = anonymousUser.getIntegerAssignment('free-article-limit', 3);
```

### Logged-In Users

For authenticated users, use their user ID with rich user attributes:

```dart
// Create instance for authenticated user
final loggedInUser = await Eppo.forSubject(
  SubjectEvaluation(
    subject: Subject(
      subjectKey: 'user-12345', // Use actual user ID
      subjectAttributes: ContextAttributes(
        categoricalAttributes: {
          'user_type': 'authenticated',
          'subscription_plan': 'premium',
          'user_segment': 'power_user',
          'country': 'US',
          'device_type': 'mobile',
          'platform': 'ios',
          'registration_source': 'organic',
          'preferred_language': 'en',
        },
        numericAttributes: {
          'age': 32,
          'account_age_days': 245,
          'lifetime_value': 299.99,
          'monthly_sessions': 18,
          'articles_read_last_30_days': 45,
        },
      ),
    ),
  ),
);

// Get feature flags for authenticated user
bool showPremiumFeatures = loggedInUser.getBooleanAssignment('premium-features', false);
String dashboardLayout = loggedInUser.getStringAssignment('dashboard-layout', 'classic');
double discountRate = loggedInUser.getNumericAssignment('loyalty-discount', 0.0);

// Get personalized recommendations using bandits
BanditEvaluation recommendation = loggedInUser.getBanditAction('content-recommendations', 'trending');
String recommendationType = recommendation.variation;
String? specificContent = recommendation.action;
```

### User State Transitions

Handle transitions between anonymous and logged-in states:

```dart
import 'dart:io';
import 'package:eppo/eppo.dart';

class UserSessionManager {
  EppoPrecomputedClient? _currentUserInstance;
  String? _currentSessionId;
  String? _currentUserId;
  
  // When user is anonymous
  Future<void> initializeAnonymousUser(String sessionId) async {
    _currentSessionId = sessionId;
    _currentUserInstance = await Eppo.forSubject(
      SubjectEvaluation(
        subject: Subject(
          subjectKey: 'anonymous-$sessionId',
          subjectAttributes: ContextAttributes(
            categoricalAttributes: {
              'user_type': 'anonymous',
              'device_type': Platform.isIOS ? 'ios' : 'android',
              'app_version': '1.0.0', // Replace with actual app version
            },
            numericAttributes: {
              'session_count': 1, // Replace with actual session count
            },
          ),
        ),
      ),
    );
  }
  
  // When user logs in
  Future<void> loginUser(String userId, Map<String, dynamic> userProfile) async {
    // Clean up anonymous user instance
    if (_currentSessionId != null) {
      Eppo.removeSubject('anonymous-$_currentSessionId');
    }
    
    _currentUserId = userId;
    // Create authenticated user instance
    _currentUserInstance = await Eppo.forSubject(
      SubjectEvaluation(
        subject: Subject(
          subjectKey: 'user-$userId',
          subjectAttributes: ContextAttributes(
            categoricalAttributes: {
              'user_type': 'authenticated',
              'subscription_plan': userProfile['plan'] ?? 'free',
              'user_segment': userProfile['segment'] ?? 'regular',
              'country': userProfile['country'] ?? 'unknown',
            },
            numericAttributes: {
              'age': userProfile['age'] ?? 0,
              'account_age_days': _calculateAccountAge(userProfile['created_at']),
              'lifetime_value': userProfile['ltv'] ?? 0.0,
            },
          ),
        ),
      ),
    );
  }
  
  // When user logs out
  Future<void> logoutUser() async {
    if (_currentUserId != null) {
      Eppo.removeSubject('user-$_currentUserId');
      _currentUserId = null;
      // Optionally initialize new anonymous session
      await initializeAnonymousUser(_generateNewSessionId());
    }
  }
  
  // Helper methods
  int _calculateAccountAge(String? createdAt) {
    if (createdAt == null) return 0;
    final created = DateTime.parse(createdAt);
    return DateTime.now().difference(created).inDays;
  }
  
  String _generateNewSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // Get current user instance
  EppoPrecomputedClient? getCurrentUserInstance() => _currentUserInstance;
}
```

### Caching and Performance

Each subject instance maintains its own isolated cache for flag assignments and bandit actions. This provides several benefits:

- **Isolation**: Anonymous and logged-in users have separate caches, preventing cross-contamination
- **Deduplication**: Repeated flag evaluations for the same subject won't generate duplicate assignment logs
- **Performance**: Flag values are cached after first evaluation, reducing computation overhead

```dart
// Each subject gets its own cache
final anonymousUser = await Eppo.forSubject(
  SubjectEvaluation(subject: Subject(subjectKey: 'anonymous-123')),
);
final loggedInUser = await Eppo.forSubject(
  SubjectEvaluation(subject: Subject(subjectKey: 'user-456')),
);

// These calls will be cached separately per subject
anonymousUser.getBooleanAssignment('feature-a', false); // First call: evaluated + cached
anonymousUser.getBooleanAssignment('feature-a', false); // Second call: served from cache

loggedInUser.getBooleanAssignment('feature-a', false);  // Different subject, different cache
```

**Cache Lifecycle:**
- Cache is created when `Eppo.forSubject()` is first called for a subject
- Cache persists until `Eppo.removeSubject(subjectKey)` or `Eppo.reset()` is called
- Each cache is isolated - removing one subject doesn't affect others

**Immediate Availability:**
- Client instances are stored in the registry immediately upon creation
- Flag evaluations work right away (returning defaults until flag data loads)
- Background flag fetching doesn't block access to the client

**Memory Management:**
```dart
// Clean up specific subject's cache when user logs out
Eppo.removeSubject('user-12345'); // Frees cache for this subject only

// Clean up anonymous user cache after login
Eppo.removeSubject('anonymous-session-abc'); 

// Clean up all caches (app restart, complete reset)
Eppo.reset(); // Clears all subject caches and instances
```

### Instance Management

```dart
// Check active instances
List<String> activeUsers = Eppo.activeSubjects;
print('Active instances: $activeUsers');

// Clean up specific instance (removes cache and client)
Eppo.removeSubject('user-12345');

// Clean up all instances (app restart, etc.)
Eppo.reset();
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
