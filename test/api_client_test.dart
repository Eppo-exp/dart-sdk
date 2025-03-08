import 'dart:async';
import 'package:eppo/src/http_client.dart';
import 'package:eppo/src/sdk_version.dart';
import 'package:eppo/src/api_client.dart';
import 'package:eppo/src/subject.dart';
import 'package:eppo/src/configuration_wire_protocol.dart';

import 'package:test/test.dart';

class MockEppoHttpClient implements EppoHttpClient {
  final Map<String, dynamic>? responseData;
  final Exception? exceptionToThrow;
  final int? statusCode;

  // Track the last request for verification
  String? lastUrl;
  Map<String, dynamic>? lastPayload;
  Duration? lastTimeout;
  Map<String, String>? lastHeaders;

  MockEppoHttpClient({
    this.responseData,
    this.exceptionToThrow,
    this.statusCode,
  });

  @override
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> payload,
    Duration timeout,
    Map<String, String> headers,
  ) async {
    // Store request details for verification
    lastUrl = url;
    lastPayload = payload;
    lastTimeout = timeout;
    lastHeaders = headers;

    // Simulate errors if configured
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    if (statusCode != null && (statusCode! < 200 || statusCode! >= 300)) {
      throw HttpException('Request failed with status: $statusCode');
    }

    // Return mock response or empty map
    return responseData ?? {};
  }
}

void main() {
  group('EppoApiClient', () {
    late MockEppoHttpClient mockHttpClient;
    late EppoApiClient apiClient;

    const sdkKey = 'test-sdk-key';
    const sdkVersion = '1.0.0';
    const baseUrl = 'https://api.test.com';

    setUp(() {
      mockHttpClient = MockEppoHttpClient();
      apiClient = EppoApiClient(
        sdkKey: sdkKey,
        sdkVersion: sdkVersion,
        sdkPlatform: SdkPlatform.dart,
        baseUrl: baseUrl,
        httpClient: mockHttpClient,
      );
    });

    group('fetchPrecomputedFlags', () {
      test('handles successful response', () async {
        // Arrange
        final mockResponse = {
          'flags': {
            'test-flag': {
              'allocationKey': 'allocation-1',
              'variationKey': 'variation-1',
              'variationType': 'string',
              'extraLogging': {'key1': 'value1'},
              'doLog': true,
              'variationValue': 'test-value',
            },
          },
          'bandits': {
            'test-bandit': {
              'banditKey': 'bandit-1',
              'action': 'action-1',
              'modelVersion': 'v1',
              'actionNumericAttributes': {'attr1': 'value1'},
              'actionCategoricalAttributes': {'cat1': 'value1'},
              'actionProbability': 0.75,
              'optimalityGap': 0.1,
            },
          },
          'salt': 'test-salt',
          'format': 'precomputed',
          'obfuscated': true,
          'createdAt': '2023-01-01T00:00:00Z',
          'environment': {'name': 'test-env'},
        };

        mockHttpClient = MockEppoHttpClient(responseData: mockResponse);
        apiClient = EppoApiClient(
          sdkKey: sdkKey,
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: baseUrl,
          httpClient: mockHttpClient,
        );

        // Act
        final result = await apiClient.fetchPrecomputedFlags(
          SubjectEvaluation(
            subject: Subject(
              subjectKey: 'user-123',
              subjectAttributes: ContextAttributes(
                categoricalAttributes: {'country': 'US'},
              ),
            ),
          ),
        );

        // Assert
        expect(result.flags.length, 1);
        expect(result.flags['test-flag']?.variationValue, 'test-value');
        expect(result.flags['test-flag']?.variationType, VariationType.string);
        expect(result.salt, 'test-salt');

        // Verify request was made correctly
        expect(mockHttpClient.lastUrl, contains(baseUrl));
        expect(mockHttpClient.lastUrl, contains('apiKey=$sdkKey'));
        expect(mockHttpClient.lastPayload?['subject_key'], 'user-123');
      });

      test(
        'throws HttpException when server returns error status code',
        () async {
          // Arrange
          mockHttpClient = MockEppoHttpClient(statusCode: 500);
          apiClient = EppoApiClient(
            sdkKey: sdkKey,
            sdkVersion: sdkVersion,
            sdkPlatform: SdkPlatform.dart,
            baseUrl: baseUrl,
            httpClient: mockHttpClient,
          );

          // Act & Assert
          expect(
            () => apiClient.fetchPrecomputedFlags(
              SubjectEvaluation(
                subject: Subject(
                  subjectKey: 'user-123',
                ),
              ),
            ),
            throwsA(isA<HttpException>()),
          );
        },
      );

      test('throws TimeoutException when request times out', () async {
        // Arrange
        mockHttpClient = MockEppoHttpClient(
          exceptionToThrow: TimeoutException('Request timed out'),
        );
        apiClient = EppoApiClient(
          sdkKey: sdkKey,
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: baseUrl,
          httpClient: mockHttpClient,
        );

        // Act & Assert
        expect(
          () => apiClient.fetchPrecomputedFlags(
            SubjectEvaluation(
              subject: Subject(
                subjectKey: 'user-123',
              ),
            ),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('throws FormatException when response is not valid JSON', () async {
        // Arrange
        mockHttpClient = MockEppoHttpClient(
          exceptionToThrow: FormatException('Invalid JSON'),
        );
        apiClient = EppoApiClient(
          sdkKey: sdkKey,
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: baseUrl,
          httpClient: mockHttpClient,
        );

        // Act & Assert
        expect(
          () => apiClient.fetchPrecomputedFlags(
            SubjectEvaluation(
              subject: Subject(
                subjectKey: 'user-123',
              ),
            ),
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('handles 401 Unauthorized error', () async {
        // Arrange
        mockHttpClient = MockEppoHttpClient(statusCode: 401);
        apiClient = EppoApiClient(
          sdkKey: 'invalid-key',
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: baseUrl,
          httpClient: mockHttpClient,
        );

        // Act & Assert
        expect(
          () => apiClient.fetchPrecomputedFlags(
            SubjectEvaluation(
              subject: Subject(
                subjectKey: 'user-123',
              ),
            ),
          ),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              contains('401'),
            ),
          ),
        );
      });

      test('handles 404 Not Found error', () async {
        // Arrange
        mockHttpClient = MockEppoHttpClient(statusCode: 404);
        apiClient = EppoApiClient(
          sdkKey: sdkKey,
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: 'https://invalid-url.com',
          httpClient: mockHttpClient,
        );

        // Act & Assert
        expect(
          () => apiClient.fetchPrecomputedFlags(
            SubjectEvaluation(
              subject: Subject(
                subjectKey: 'user-123',
              ),
            ),
          ),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              contains('404'),
            ),
          ),
        );
      });

      test('handles network errors', () async {
        // Arrange
        mockHttpClient = MockEppoHttpClient(
          exceptionToThrow: Exception('Network error'),
        );
        apiClient = EppoApiClient(
          sdkKey: sdkKey,
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: baseUrl,
          httpClient: mockHttpClient,
        );

        // Act & Assert
        expect(
          () => apiClient.fetchPrecomputedFlags(
            SubjectEvaluation(
              subject: Subject(
                subjectKey: 'user-123',
              ),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('request payload formatting', () {
      setUp(() {
        // Common setup for all payload tests
        mockHttpClient = MockEppoHttpClient(responseData: {
          'flags': {},
          'bandits': {},
          'salt': 'test-salt',
          'format': 'precomputed',
          'obfuscated': true,
          'createdAt': '2023-01-01T00:00:00Z',
          'environment': {'name': 'test-env'},
        });

        apiClient = EppoApiClient(
          sdkKey: sdkKey,
          sdkVersion: sdkVersion,
          sdkPlatform: SdkPlatform.dart,
          baseUrl: baseUrl,
          httpClient: mockHttpClient,
        );
      });

      test('formats request with just subject key', () async {
        // Act
        await apiClient.fetchPrecomputedFlags(
          SubjectEvaluation(
            subject: Subject(
              subjectKey: 'user-123',
            ),
          ),
        );

        // Assert
        expect(mockHttpClient.lastPayload, isNotNull);
        expect(mockHttpClient.lastPayload!['subject_key'], equals('user-123'));
        expect(mockHttpClient.lastPayload!['subject_attributes'], isMap);
        expect(
            mockHttpClient.lastPayload!['subject_attributes']
                ['categoricalAttributes'],
            isEmpty);
        expect(
            mockHttpClient.lastPayload!['subject_attributes']
                ['numericAttributes'],
            isEmpty);
        expect(
            mockHttpClient.lastPayload!.containsKey('bandit_actions'), isFalse);
      });

      test('formats request with subject attributes', () async {
        // Act
        await apiClient.fetchPrecomputedFlags(
          SubjectEvaluation(
            subject: Subject(
              subjectKey: 'user-456',
              subjectAttributes: ContextAttributes(
                categoricalAttributes: {'country': 'US', 'device': 'mobile'},
                numericAttributes: {'age': 25, 'visits': 10},
              ),
            ),
          ),
        );

        // Assert
        expect(mockHttpClient.lastPayload, isNotNull);
        expect(mockHttpClient.lastPayload!['subject_key'], equals('user-456'));

        // Check subject_attributes exists
        final subjectAttrs = mockHttpClient.lastPayload!['subject_attributes'];
        expect(subjectAttrs, isNotNull);
        expect(subjectAttrs, isA<Map>());

        // Check for categoricalAttributes and numericAttributes
        expect(subjectAttrs.containsKey('categoricalAttributes'), isTrue);
        expect(subjectAttrs.containsKey('numericAttributes'), isTrue);

        // Check categorical values
        final categorical = subjectAttrs['categoricalAttributes'];
        expect(categorical, isA<Map>());
        expect(categorical['country'], equals('US'));
        expect(categorical['device'], equals('mobile'));

        // Check numeric values
        final numeric = subjectAttrs['numericAttributes'];
        expect(numeric, isA<Map>());
        expect(numeric['age'], equals(25));
        expect(numeric['visits'], equals(10));
      });

      test('formats request with bandit actions', () async {
        // Act
        await apiClient.fetchPrecomputedFlags(
          SubjectEvaluation(
            subject: Subject(
              subjectKey: 'user-789',
            ),
            banditActions: {
              'test-bandit': {
                'action1': {'price': 10.99, 'category': 'electronics'},
                'action2': {'price': 5.99, 'category': 'books'}
              }
            },
          ),
        );

        // Assert
        expect(mockHttpClient.lastPayload, isNotNull);
        expect(mockHttpClient.lastPayload!['subject_key'], equals('user-789'));
        expect(mockHttpClient.lastPayload!['bandit_actions'], isMap);
        expect(mockHttpClient.lastPayload!['bandit_actions']['test-bandit'],
            isMap);
        expect(
            mockHttpClient.lastPayload!['bandit_actions']['test-bandit']
                ['action1'],
            isMap);
        expect(
            mockHttpClient.lastPayload!['bandit_actions']['test-bandit']
                ['action1']['price'],
            equals(10.99));
        expect(
            mockHttpClient.lastPayload!['bandit_actions']['test-bandit']
                ['action1']['category'],
            equals('electronics'));
        expect(
            mockHttpClient.lastPayload!['bandit_actions']['test-bandit']
                ['action2'],
            isMap);
        expect(
            mockHttpClient.lastPayload!['bandit_actions']['test-bandit']
                ['action2']['price'],
            equals(5.99));
      });
    });
  });
}
