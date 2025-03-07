import 'package:eppo/eppo.dart';
import 'package:eppo/src/sdk_version.dart' as sdk;
import 'package:test/test.dart';
import 'package:eppo/src/crypto.dart';

class MockEppoHttpClient implements EppoHttpClient {
  final Map<String, dynamic> responseData;

  MockEppoHttpClient(this.responseData);

  @override
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> payload,
    int timeoutMs,
    Map<String, String> headers,
  ) async {
    return responseData;
  }
}

/// Mock implementation of AssignmentLogger for testing
class MockAssignmentLogger implements AssignmentLogger {
  final List<AssignmentEvent> loggedEvents = [];

  @override
  void logAssignment(AssignmentEvent event) {
    loggedEvents.add(event);
  }

  void clear() {
    loggedEvents.clear();
  }
}

void main() {
  group('EppoPrecomputedClient', () {
    late EppoPrecomputedClient client;
    late EppoApiClient apiClient;
    late MockEppoHttpClient mockHttpClient;
    late MockAssignmentLogger mockLogger;

    const sdkKey = 'test-sdk-key';
    const subjectKey = 'user-123';
    const salt = 'test-salt';

    // Calculate actual MD5 hashes for our flag keys
    final stringFlagHash = getMD5Hash('string-flag', salt: salt);
    final booleanFlagHash = getMD5Hash('boolean-flag', salt: salt);
    final integerFlagHash = getMD5Hash('integer-flag', salt: salt);
    final numericFlagHash = getMD5Hash('numeric-flag', salt: salt);
    final jsonFlagHash = getMD5Hash('json-flag', salt: salt);

    setUp(() async {
      // Encode the values in the mock response
      final encodedMockResponse = {
        'flags': {
          stringFlagHash: {
            'allocationKey': encodeBase64('allocation-1'),
            'variationKey': encodeBase64('variation-1'),
            'variationType': 'string',
            'extraLogging': {'key1': encodeBase64('value1')},
            'doLog': true,
            'variationValue': encodeBase64('test-string-value'),
          },
          booleanFlagHash: {
            'allocationKey': encodeBase64('allocation-2'),
            'variationKey': encodeBase64('variation-2'),
            'variationType': 'boolean',
            'doLog': true,
            'variationValue': encodeBase64('true'),
          },
          integerFlagHash: {
            'allocationKey': encodeBase64('allocation-3'),
            'variationKey': encodeBase64('variation-3'),
            'variationType': 'integer',
            'doLog': true,
            'variationValue': encodeBase64('42'),
          },
          numericFlagHash: {
            'allocationKey': encodeBase64('allocation-4'),
            'variationKey': encodeBase64('variation-4'),
            'variationType': 'numeric',
            'doLog': true,
            'variationValue': encodeBase64('3.14'),
          },
          jsonFlagHash: {
            'allocationKey': encodeBase64('allocation-5'),
            'variationKey': encodeBase64('variation-5'),
            'variationType': 'json',
            'doLog': true,
            'variationValue':
                encodeBase64('{"key":"value","nested":{"num":123}}'),
          },
        },
        'bandits': {
          stringFlagHash: {
            "banditKey": encodeBase64("recommendation-model-v1"),
            "action": encodeBase64("show_red_button"),
            "actionProbability": 0.85,
            "optimalityGap": 0.12,
            "modelVersion": encodeBase64("v2.3.1"),
            "actionNumericAttributes": {
              "expectedConversion": encodeBase64("0.23"),
              "expectedRevenue": encodeBase64("15.75")
            },
            "actionCategoricalAttributes": {
              "category": encodeBase64("promotion"),
              "placement": encodeBase64("home_screen")
            }
          },
        },
        'salt': salt,
        'format': 'precomputed',
        'obfuscated': true,
        'createdAt': '2023-01-01T00:00:00Z',
        'environment': {'name': 'test-env'},
      };

      mockHttpClient = MockEppoHttpClient(encodedMockResponse);

      // Create API client with mock HTTP client
      apiClient = EppoApiClient(
        sdkKey: sdkKey,
        sdkVersion: '1.0.0',
        sdkPlatform: sdk.SdkPlatform.dart,
        httpClient: mockHttpClient,
      );

      // Create subject with attributes
      final subject = Subject(
        subjectKey: subjectKey,
        subjectAttributes: ContextAttributes(
          categoricalAttributes: {'country': 'US', 'device': 'mobile'},
          numericAttributes: {'age': 30},
        ),
      );

      // Create SDK options
      mockLogger = MockAssignmentLogger();
      final sdkOptions = SdkOptions(
        sdkKey: sdkKey,
        sdkPlatform: sdk.SdkPlatform.dart,
        apiClient: apiClient,
        assignmentLogger: mockLogger,
      );

      // Create precompute arguments
      final precomputeArgs = PrecomputeArguments(subject: subject);

      // Create client
      client = EppoPrecomputedClient(sdkOptions, precomputeArgs);

      // Fetch precomputed flags
      await client.fetchPrecomputedFlags();
    });

    test('getStringAssignment returns correct value', () {
      final result = client.getStringAssignment('string-flag', 'default');
      expect(result, 'test-string-value');
    });

    test('getBooleanAssignment returns correct value', () {
      final result = client.getBooleanAssignment('boolean-flag', false);
      expect(result, true);
    });

    test('getIntegerAssignment returns correct value', () {
      final result = client.getIntegerAssignment('integer-flag', 0);
      expect(result, 42);
    });

    test('getNumericAssignment returns correct value', () {
      final result = client.getNumericAssignment('numeric-flag', 0.0);
      expect(result, 3.14);
    });

    test('getJSONAssignment returns correct value', () {
      final result = client.getJSONAssignment('json-flag', {});
      expect(result, {
        'key': 'value',
        'nested': {'num': 123}
      });
    });

    test('getBanditAction returns correct value', () {
      final result = client.getBanditAction('string-flag', 'default-bandit');
      expect(result.action, 'show_red_button');
      expect(result.variation, 'test-string-value');
    });

    test('returns default value for non-existent flag', () {
      final result = client.getStringAssignment('non-existent-flag', 'default');
      expect(result, 'default');
    });

    test('returns default value for type mismatch', () {
      // Try to get a string flag as a boolean
      final result = client.getBooleanAssignment('string-flag', false);
      expect(result, false);
    });

    group('Assignment Logging', () {
      late EppoPrecomputedClient clientWithoutCache;
      late EppoPrecomputedClient clientWithCache;
      late MockAssignmentLogger loggerWithoutCache;
      late MockAssignmentLogger loggerWithCache;
      late SdkOptions sdkOptionsWithCache;

      setUp(() async {
        // Setup client without assignment cache
        loggerWithoutCache = MockAssignmentLogger();
        final sdkOptionsWithoutCache = SdkOptions(
          sdkKey: sdkKey,
          sdkPlatform: sdk.SdkPlatform.dart,
          apiClient: apiClient,
          assignmentLogger: loggerWithoutCache,
          flagAssignmentCache:
              NoOpAssignmentCache(), // Use NoOpAssignmentCache to disable deduplication
        );

        final precomputeArgs = PrecomputeArguments(
          subject: Subject(
            subjectKey: subjectKey,
            subjectAttributes: ContextAttributes(
              categoricalAttributes: {'country': 'US', 'device': 'mobile'},
              numericAttributes: {'age': 30},
            ),
          ),
        );

        clientWithoutCache =
            EppoPrecomputedClient(sdkOptionsWithoutCache, precomputeArgs);
        await clientWithoutCache.fetchPrecomputedFlags();

        // Setup client with assignment cache
        loggerWithCache = MockAssignmentLogger();
        sdkOptionsWithCache = SdkOptions(
          sdkKey: sdkKey,
          sdkPlatform: sdk.SdkPlatform.dart,
          apiClient: apiClient,
          assignmentLogger: loggerWithCache,
          // Use explicit cache
          flagAssignmentCache: InMemoryAssignmentCache(),
        );

        clientWithCache =
            EppoPrecomputedClient(sdkOptionsWithCache, precomputeArgs);
        await clientWithCache.fetchPrecomputedFlags();
      });

      test('logs canonical assignments when doLog is true', () {
        // Clear any previous events
        mockLogger.clear();

        // Get a flag value - this should trigger logging since doLog is true in the mock response
        client.getStringAssignment('string-flag', 'default');
        client.getStringAssignment('string-flag', 'default');

        // Verify that an event was logged
        expect(mockLogger.loggedEvents, hasLength(1));

        // Verify the logged event details
        final event = mockLogger.loggedEvents.first;
        expect(event.featureFlag, equals('string-flag'));
        expect(event.subject, equals(subjectKey));
        expect(event.variation, equals('variation-1'));
        expect(event.allocation, equals('allocation-1'));
        expect(event.experiment, equals('string-flag-allocation-1'));
      });

      test('logs different flag assignments separately', () {
        // Clear any previous events
        mockLogger.clear();

        // Get different flag values
        client.getStringAssignment('string-flag', 'default');
        client.getBooleanAssignment('boolean-flag', false);

        // Verify that both events were logged
        expect(mockLogger.loggedEvents, hasLength(2));

        // Verify the logged event details
        expect(mockLogger.loggedEvents[0].featureFlag, equals('string-flag'));
        expect(mockLogger.loggedEvents[1].featureFlag, equals('boolean-flag'));
      });

      test('logs duplicate assignments without deduplication', () {
        // Clear any previous events
        loggerWithoutCache.clear();

        // Get the same flag value twice
        clientWithoutCache.getStringAssignment('string-flag', 'default');
        clientWithoutCache.getStringAssignment('string-flag', 'default');

        // Should log both assignments since we're using NoOpAssignmentCache
        expect(loggerWithoutCache.loggedEvents, hasLength(2));
      });

      test('does not log duplicate assignments with cache', () {
        // Clear any previous events
        loggerWithCache.clear();

        // Get the same flag value twice
        clientWithCache.getStringAssignment('string-flag', 'default');
        clientWithCache.getStringAssignment('string-flag', 'default');

        // Should only log once due to cache
        expect(loggerWithCache.loggedEvents, hasLength(1));
      });

      test('logs for each unique flag with cache', () {
        // Clear any previous events
        loggerWithCache.clear();

        // Get different flag values
        clientWithCache.getStringAssignment('string-flag', 'default');
        clientWithCache.getStringAssignment(
            'string-flag', 'default'); // Cache hit
        clientWithCache.getBooleanAssignment('boolean-flag', false);
        clientWithCache.getBooleanAssignment(
            'boolean-flag', false); // Cache hit
        clientWithCache.getIntegerAssignment('integer-flag', 0);
        clientWithCache.getIntegerAssignment('integer-flag', 0); // Cache hit

        // Should log once for each unique flag
        expect(loggerWithCache.loggedEvents, hasLength(3));
      });

      test('NoOpAssignmentCache always returns false for has()', () {
        final cache = NoOpAssignmentCache();
        final entry = AssignmentCacheEntry(
          key: AssignmentCacheKey(
            flagKey: 'test-flag',
            subjectKey: 'test-subject',
          ),
          value: VariationCacheValue(
            allocationKey: 'test-allocation',
            variationKey: 'test-variation',
          ),
        );

        // Set the entry
        cache.set(entry);

        // Should still return false even after setting
        expect(cache.has(entry), isFalse);
      });

      test('InMemoryAssignmentCache returns true for has() after set()', () {
        final cache = InMemoryAssignmentCache();
        final entry = AssignmentCacheEntry(
          key: AssignmentCacheKey(
            flagKey: 'test-flag',
            subjectKey: 'test-subject',
          ),
          value: VariationCacheValue(
            allocationKey: 'test-allocation',
            variationKey: 'test-variation',
          ),
        );

        // Initially should return false
        expect(cache.has(entry), isFalse);

        // Set the entry
        cache.set(entry);

        // Now should return true
        expect(cache.has(entry), isTrue);

        // Different value should return false
        final differentEntry = AssignmentCacheEntry(
          key: AssignmentCacheKey(
            flagKey: 'test-flag',
            subjectKey: 'test-subject',
          ),
          value: VariationCacheValue(
            allocationKey: 'different-allocation',
            variationKey: 'test-variation',
          ),
        );
        expect(cache.has(differentEntry), isFalse);
      });

      test('logs assignments when flag values change', () {
        // Clear any previous events
        loggerWithCache.clear();

        // Get the initial assignment
        final initialValue =
            clientWithCache.getStringAssignment('string-flag', 'default');
        expect(initialValue, equals('test-string-value'));

        // Verify initial log was made
        expect(loggerWithCache.loggedEvents, hasLength(1));
        expect(
            loggerWithCache.loggedEvents[0].featureFlag, equals('string-flag'));
        expect(
            loggerWithCache.loggedEvents[0].variation, equals('variation-1'));

        // Create a new AssignmentCacheEntry with the same key but different value
        final cacheKey = AssignmentCacheKey(
          flagKey: 'string-flag',
          subjectKey: subjectKey,
        );

        // Create a new cache entry with the same key but different value
        final newCacheEntry = AssignmentCacheEntry(
          key: cacheKey,
          value: VariationCacheValue(
            allocationKey: 'allocation-1',
            variationKey: 'variation-changed',
          ),
        );

        // Set the new cache entry
        sdkOptionsWithCache.flagAssignmentCache.set(newCacheEntry);

        // Get the assignment again - this should log again because the cache value changed
        clientWithCache.getStringAssignment('string-flag', 'default');

        // Verify another log was made
        expect(loggerWithCache.loggedEvents, hasLength(2));
      });
    });
  });
}
