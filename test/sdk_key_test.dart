import 'dart:convert';
import 'package:eppo/src/sdk_key.dart';
import 'package:test/test.dart';

void main() {
  group('SdkKey', () {
    final testCases = [
      {
        'description': 'Valid token with subdomain',
        'payload': 'cs=test-subdomain',
        'isValid': true,
        'expectedSubdomain': 'test-subdomain',
      },
      {
        'description': 'Valid token with multiple parameters',
        'payload': 'cs=test-subdomain&other=value',
        'isValid': true,
        'expectedSubdomain': 'test-subdomain',
      },
      {
        'description': 'Token with URL encoded characters',
        'payload': 'cs=test%20subdomain&other=special%26value',
        'isValid': true,
        'expectedSubdomain': 'test subdomain',
      },
      {
        'description': 'Token without subdomain',
        'payload': 'other=value',
        'isValid': true,
        'expectedSubdomain': null,
      },
      {
        'description': 'Token with empty payload',
        'rawToken': 'signature.',
        'isValid': false,
        'expectedSubdomain': null,
      },
      {
        'description': 'Invalid token format',
        'rawToken': 'invalid-token',
        'isValid': false,
        'expectedSubdomain': null,
      },
      {
        'description': 'Empty token',
        'rawToken': '',
        'isValid': false,
        'expectedSubdomain': null,
      },
      {
        'description': 'Malformed base64 in token',
        'rawToken': 'signature.not-valid-base64',
        'isValid': false,
        'expectedSubdomain': null,
      },
      {
        'description': 'JS SDK token',
        'rawToken': 'zCsQuoHJxVPp895.Y3M9ZXhwZXJpbWVudCZlaD1hYmMxMjMuZXBwby5jbG91ZA==',
        'isValid': true,
        'expectedSubdomain': 'experiment',
      },
    ];
    
    // Run each test case in a loop
    for (final testCase in testCases) {
      test(testCase['description'] as String, () {
        // Prepare the token
        String token;
        if (testCase.containsKey('rawToken')) {
          token = testCase['rawToken'] as String;
        } else {
          final payload = testCase['payload'] as String;
          final encodedPayload = base64Encode(utf8.encode(payload));
          token = "signature.$encodedPayload";
        }
        
        // Create the SdkKey and test the expectations
        final sdkKey = SdkKey(token);
        
        expect(sdkKey.isValid, equals(testCase['isValid']), reason: 'isValid should match');
        expect(sdkKey.subdomain, equals(testCase['expectedSubdomain']), reason: 'subdomain should match');
        
        // Only verify token for raw tokens, as we can't predict the exact encoded value otherwise
        if (testCase.containsKey('rawToken')) {
          expect(sdkKey.token, equals(token), reason: 'token should match original');
        }
      });
    }
  });
}
