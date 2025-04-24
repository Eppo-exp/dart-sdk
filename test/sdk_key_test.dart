import 'dart:convert';
import 'package:eppo/src/sdk_key.dart';
import 'package:test/test.dart';

void main() {
  group('SDKKey', () {
    test('should parse valid token with subdomain', () {
      // Using the same token format as in Java tests
      final payload = "cs=test-subdomain";
      final encodedPayload = base64Encode(utf8.encode(payload));
      final token = "signature.$encodedPayload";
      
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isTrue);
      expect(sdkKey.getSubdomain(), equals('test-subdomain'));
      expect(sdkKey.getToken(), equals(token));
    });

    test('should parse valid token with multiple parameters', () {
      // Using the same token format as in Java tests
      final payload = "cs=test-subdomain&other=value";
      final encodedPayload = base64Encode(utf8.encode(payload));
      final token = "signature.$encodedPayload";
      
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isTrue);
      expect(sdkKey.getSubdomain(), equals('test-subdomain'));
      expect(sdkKey.getToken(), equals(token));
    });

    test('should parse valid token with URL encoded characters', () {
      // Using the same token format as in Java tests
      final payload = "cs=test%20subdomain&other=special%26value";
      final encodedPayload = base64Encode(utf8.encode(payload));
      final token = "signature.$encodedPayload";
      
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isTrue);
      expect(sdkKey.getSubdomain(), equals('test subdomain'));
      expect(sdkKey.getToken(), equals(token));
    });

    test('should handle token without subdomain', () {
      // Using the same token format as in Java tests
      final payload = "other=value";
      final encodedPayload = base64Encode(utf8.encode(payload));
      final token = "signature.$encodedPayload";
      
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isTrue);
      expect(sdkKey.getSubdomain(), isNull);
      expect(sdkKey.getToken(), equals(token));
    });

    test('should handle token with empty payload', () {
      // Sample token with empty base64 encoded payload
      final token = 'signature.';
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isFalse);
      expect(sdkKey.getSubdomain(), isNull);
    });

    test('should handle invalid token format', () {
      final sdkKey = SDKKey('invalid-token');
      
      expect(sdkKey.isValid(), isFalse);
      expect(sdkKey.getSubdomain(), isNull);
    });

    test('should handle empty token', () {
      final sdkKey = SDKKey('');
      
      expect(sdkKey.isValid(), isFalse);
      expect(sdkKey.getSubdomain(), isNull);
    });

    test('should handle malformed base64 in token', () {
      // Using the same token format as in Java tests
      final token = 'signature.not-valid-base64';
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isFalse);
      expect(sdkKey.getSubdomain(), isNull);
    });
    
    test('should extract subdomain from JS SDK token', () {
      // Using the same token as in JS SDK tests
      final token = 'zCsQuoHJxVPp895.Y3M9ZXhwZXJpbWVudCZlaD1hYmMxMjMuZXBwby5jbG91ZA==';
      final sdkKey = SDKKey(token);
      
      expect(sdkKey.isValid(), isTrue);
      expect(sdkKey.getSubdomain(), equals('experiment'));
      expect(sdkKey.getToken(), equals(token));
    });
  });
}
