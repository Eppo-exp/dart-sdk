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
/// feature flags and bandit actions for multiple subjects.
///
/// Shows both the singleton API and the new multi-instance API for handling
/// anonymous users, logged-in users, and user state transitions.
///
/// The SDK key is required and should be a valid Eppo SDK key.
/// The subject key is optional and defaults to 'user-123'.
void main(List<String> args) async {
  // Configure logging
  Logger.root.level = Level.INFO;

  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart example/main.dart <sdk-key> [subject-key]',
    );
    exit(1);
  }

  final sdkKey = args[0];
  final subjectKey = args.length > 1 ? args[1] : 'user-123';

  // Create SDK configuration
  final clientConfiguration = ClientConfiguration(
    sdkPlatform: SdkPlatform.dart,
    assignmentLogger: MyAssignmentLogger(),
  );

  print('Eppo SDK Multi-Instance Example');
  print('=================================');

  // === 1️⃣ SINGLETON API (Traditional Usage) ===
  print('\n1️⃣ Singleton API');
  print('----------------');
  
  // Initialize with a logged-in user
  final loggedInUser = Subject(
    subjectKey: subjectKey,
    subjectAttributes: ContextAttributes(
      categoricalAttributes: {
        'user_type': 'authenticated',
        'subscription_plan': 'premium',
        'country': 'US',
        'device': 'mobile'
      },
      numericAttributes: {'age': 30, 'account_age_days': 180},
    ),
  );
  
  await Eppo.initialize(sdkKey, SubjectEvaluation(subject: loggedInUser), clientConfiguration);
  print('✅ Initialized SDK for logged-in user: $subjectKey');

  // Use singleton methods
  final premiumFeature = Eppo.getBooleanAssignment('premium-feature', false);
  print('   Premium feature enabled: $premiumFeature');

  // === 2️⃣ MULTI-INSTANCE API ===
  print('\n2️⃣ Multi-Instance API');
  print('---------------------');

  // Create instance for anonymous user
  final EppoPrecomputedClient anonymousUser = await Eppo.forSubject(
    SubjectEvaluation(
      subject: Subject(
        subjectKey: 'anonymous-session-abc123',
        subjectAttributes: ContextAttributes(
          categoricalAttributes: {
            'user_type': 'anonymous',
            'device': 'mobile',
            'platform': 'dart',
            'referrer_source': 'organic',
          },
          numericAttributes: {
            'session_count': 1,
            'days_since_install': 0,
          },
        ),
      ),
    ),
  );
  print('✅ Created anonymous user instance');

  // Create instance for different logged-in user
  final otherUser = await Eppo.forSubject(
    SubjectEvaluation(
      subject: Subject(
        subjectKey: 'user-456',
        subjectAttributes: ContextAttributes(
          categoricalAttributes: {
            'user_type': 'authenticated',
            'subscription_plan': 'free',
            'country': 'CA',
            'device': 'desktop',
          },
          numericAttributes: {'age': 25, 'account_age_days': 45},
        ),
      ),
    ),
  );
  print('✅ Created second user instance');

  // === 3️⃣ FLAG EVALUATIONS PER USER ===
  print('\n3️⃣ Flag Evaluations Per User');
  print('----------------------------');

  // Anonymous user evaluations
  final anonPremium = anonymousUser.getBooleanAssignment('premium-feature', false);
  final anonSignupBanner = anonymousUser.getBooleanAssignment('signup-banner', false);
  
  print('Anonymous user flags:');
  print('   Premium feature: $anonPremium');
  print('   Show signup banner: $anonSignupBanner');

  // Other user evaluations  
  final otherPremium = otherUser.getBooleanAssignment('premium-feature', false);
  final otherSignupBanner = otherUser.getBooleanAssignment('signup-banner', false);

  print('\nSecond user flags:');
  print('   Premium feature: $otherPremium');
  print('   Show signup banner: $otherSignupBanner');

  // === API COEXISTENCE ===
  print('\nAPI Coexistence:');
  print('----------------');

  // Singleton API still works
  final singletonResult = Eppo.getBooleanAssignment('premium-feature', false);
  print('Singleton API result: $singletonResult');

  // Same subject as singleton returns same client
  final sameAssingleton = await Eppo.forSubject(
    SubjectEvaluation(subject: Subject(subjectKey: subjectKey)),
  );
  final instanceResult = sameAssingleton.getBooleanAssignment('premium-feature', false);
  print('Multi-instance API (same subject): $instanceResult');
  print('✅ Results match: ${singletonResult == instanceResult}');

  // === INSTANCE MANAGEMENT ===
  print('\nInstance Management:');
  print('-------------------');

  print('Active subjects: ${Eppo.activeSubjects}');
  print('Total instances: ${Eppo.activeSubjects.length}');

  // Cleanup example
  print('\nCleaning up anonymous user...');
  Eppo.removeSubject('anonymous-session-abc123');
  print('Active subjects after cleanup: ${Eppo.activeSubjects}');

  // === USER STATE TRANSITION ===
  print('\nUser State Transition:');
  print('---------------------');

  // Simulate user login flow
  print('Simulating anonymous → logged-in user transition...');
  
  // 1. Start with anonymous user
  final tempAnonymous = await Eppo.forSubject(
    SubjectEvaluation(subject: Subject(subjectKey: 'temp-anonymous-xyz')),
  );
  final beforeLogin = tempAnonymous.getBooleanAssignment('signup-banner', false);
  print('Before login - signup banner: $beforeLogin');

  // 2. User logs in - clean up anonymous, create authenticated
  Eppo.removeSubject('temp-anonymous-xyz');
  final newLoggedInUser = await Eppo.forSubject(
    SubjectEvaluation(
      subject: Subject(
        subjectKey: 'user-789',
        subjectAttributes: ContextAttributes(
          categoricalAttributes: {
            'user_type': 'authenticated',
            'subscription_plan': 'premium',
            'country': 'US',
          },
          numericAttributes: {'age': 28, 'account_age_days': 1}, // New user
        ),
      ),
    ),
  );
  
  final afterLogin = newLoggedInUser.getBooleanAssignment('premium-feature', false);
  print('After login - premium feature: $afterLogin');

  print('\n✅ Example completed successfully!');
  print('Final active subjects: ${Eppo.activeSubjects}');
  
  exit(0);
}
