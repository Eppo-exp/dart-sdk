import 'dart:convert';
import 'package:eppo/src/api_endpoints.dart';
import 'package:eppo/src/sdk_key.dart';
import 'package:test/test.dart';

void main() {
  group('ApiEndpoints', () {
    group('Base URL resolution', () {
      test('should use baseUrl when provided', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        expect(apiEndpoints.getBaseUrl(), equals('https://custom-url.com'));
        expect(apiEndpoints.getPrecomputedFlagsEndpoint(), equals('https://custom-url.com/assignments'));
      });

      test('should use subdomain from SDK key when no baseUrl provided', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
        );
        
        expect(apiEndpoints.getBaseUrl(), equals('https://test-subdomain.fs-edge-assignment.eppo.cloud'));
        expect(apiEndpoints.getPrecomputedFlagsEndpoint(), equals('https://test-subdomain.fs-edge-assignment.eppo.cloud/assignments'));
      });

      test('should use default URL when no subdomain in SDK key', () {
        final sdkKey = SDKKey('invalid-token');
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
        );
        
        expect(apiEndpoints.getBaseUrl(), equals('https://fs-edge-assignment.eppo.cloud'));
        expect(apiEndpoints.getPrecomputedFlagsEndpoint(), equals('https://fs-edge-assignment.eppo.cloud/assignments'));
      });

      test('should prioritize baseUrl over subdomain', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://priority-url.com',
        );
        
        expect(apiEndpoints.getBaseUrl(), equals('https://priority-url.com'));
        expect(apiEndpoints.getPrecomputedFlagsEndpoint(), equals('https://priority-url.com/assignments'));
      });
    });

    group('URL normalization', () {
      test('should normalize URLs with trailing slashes', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        
        // URL with trailing slash
        final apiEndpoints1 = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com/',
        );
        expect(apiEndpoints1.getBaseUrl(), equals('https://custom-url.com'));
        
        // URL with multiple trailing slashes
        final apiEndpoints2 = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com///',
        );
        expect(apiEndpoints2.getBaseUrl(), equals('https://custom-url.com'));
      });
      
      test('should add protocol to URLs without protocol', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        
        // URL without protocol
        final apiEndpoints1 = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'custom-url.com',
        );
        expect(apiEndpoints1.getBaseUrl(), equals('https://custom-url.com'));
        
        // URL with protocol-relative format
        final apiEndpoints2 = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: '//custom-url.com',
        );
        expect(apiEndpoints2.getBaseUrl(), equals('//custom-url.com'));
      });
      
      test('should preserve http protocol when specified', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'http://custom-url.com',
        );
        expect(apiEndpoints.getBaseUrl(), equals('http://custom-url.com'));
      });
    });
    
    group('Query parameter handling', () {
      test('should append query parameters to precomputed endpoint', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final queryParams = {
          'apiKey': 'test-api-key',
          'sdkVersion': '1.0.0',
          'sdkName': 'eppo-dart',
        };
        
        final url = apiEndpoints.getPrecomputedFlagsEndpoint(queryParams);
        expect(url, contains('https://custom-url.com/assignments?'));
        expect(url, contains('apiKey=test-api-key'));
        expect(url, contains('sdkVersion=1.0.0'));
        expect(url, contains('sdkName=eppo-dart'));
      });
      
      test('should handle empty query parameters', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final url1 = apiEndpoints.getPrecomputedFlagsEndpoint({});
        expect(url1, equals('https://custom-url.com/assignments'));
        
        final url2 = apiEndpoints.getPrecomputedFlagsEndpoint(null);
        expect(url2, equals('https://custom-url.com/assignments'));
      });
      
      test('should properly encode query parameter values', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final queryParams = {
          'param': 'value with spaces',
          'special': 'value+with+plus&other=chars',
        };
        
        final url = apiEndpoints.getPrecomputedFlagsEndpoint(queryParams);
        // Dart URI explicitly "percent-encodes" spaces as + https://api.dart.dev/dart-core/Uri/Uri.html
        expect(url, contains('param=value+with+spaces'));
        expect(url, contains('special=value%2Bwith%2Bplus%26other%3Dchars'));
      });
    });
    
    group('buildUrl method', () {
      test('should build URL with path and query parameters', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final queryParams = {
          'param1': 'value1',
          'param2': 'value2',
        };
        
        // Test with path starting with slash
        final url1 = apiEndpoints.buildUrl('/custom-path', queryParams);
        expect(url1, contains('https://custom-url.com/custom-path?'));
        expect(url1, contains('param1=value1'));
        expect(url1, contains('param2=value2'));
        
        // Test with path not starting with slash
        final url2 = apiEndpoints.buildUrl('another-path', queryParams);
        expect(url2, contains('https://custom-url.com/another-path?'));
        expect(url2, contains('param1=value1'));
        expect(url2, contains('param2=value2'));
      });
      
      test('should handle paths with special characters', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final url = apiEndpoints.buildUrl('/path with spaces/and/special+chars');
        expect(url, equals('https://custom-url.com/path with spaces/and/special+chars'));
      });
      
      test('should handle empty or null paths', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final url1 = apiEndpoints.buildUrl('');
        expect(url1, equals('https://custom-url.com/'));
      });
      
      test('should handle paths without query parameters', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final url = apiEndpoints.buildUrl('/path-only');
        expect(url, equals('https://custom-url.com/path-only'));
      });
    });
    
    group('Integration with EppoApiClient', () {
      test('should generate correct URL for API client', () {
        final payload = "cs=test-subdomain";
        final encodedPayload = base64Encode(utf8.encode(payload));
        final token = "signature.$encodedPayload";
        final sdkKey = SDKKey(token);
        final apiEndpoints = ApiEndpoints.precomputed(
          sdkKey: sdkKey,
          baseUrl: 'https://custom-url.com',
        );
        
        final queryParams = {
          'apiKey': 'test-sdk-key',
          'sdkVersion': '1.0.0',
          'sdkName': 'eppo-dart',
        };
        
        final url = apiEndpoints.getPrecomputedFlagsEndpoint(queryParams);
        expect(url, startsWith('https://custom-url.com/assignments?'));
        expect(url, contains('apiKey=test-sdk-key'));
        expect(url, contains('sdkVersion=1.0.0'));
        expect(url, contains('sdkName=eppo-dart'));
      });
    });
  });
}
