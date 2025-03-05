import 'package:eppo/src/api_client.dart';
import 'package:eppo/src/configuration_wire_protocol.dart';
import 'package:eppo/src/crypto.dart';
import 'package:eppo/src/http_client.dart';
import 'package:eppo/src/precompute_client.dart';
import 'package:eppo/src/sdk_version.dart' as sdk;
import 'package:eppo/src/subject.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

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

void main() {
  group('EppoPrecomputedClient', () {
    late EppoPrecomputedClient client;
    late EppoApiClient apiClient;
    late MockEppoHttpClient mockHttpClient;

    const sdkKey = 'test-sdk-key';
    const subjectKey = 'user-123';
    const salt = 'test-salt';

    // Calculate actual MD5 hashes for our flag keys
    final stringFlagHash = getMD5Hash('string-flag', salt);
    final booleanFlagHash = getMD5Hash('boolean-flag', salt);
    final integerFlagHash = getMD5Hash('integer-flag', salt);
    final numericFlagHash = getMD5Hash('numeric-flag', salt);
    final jsonFlagHash = getMD5Hash('json-flag', salt);

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
        'bandits': {},
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
      final sdkOptions = SdkOptions(
        sdkKey: sdkKey,
        sdkPlatform: sdk.SdkPlatform.dart,
        apiClient: apiClient,
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

    test('returns default value for non-existent flag', () {
      final result = client.getStringAssignment('non-existent-flag', 'default');
      expect(result, 'default');
    });

    test('returns default value for type mismatch', () {
      // Try to get a string flag as a boolean
      final result = client.getBooleanAssignment('string-flag', false);
      expect(result, false);
    });
  });
}
