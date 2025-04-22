import 'crypto.dart';

/// SDK key, built from an enhanced SDK token string; this class extracts encoded fields,
/// such as the customer-specific service gateway subdomain.
class SDKKey {
  /// The original SDK token string
  final String sdkTokenString;

  /// Map of decoded parameters from the token
  final Map<String, String> decodedParams;

  /// Creates a new SDK key instance
  SDKKey(this.sdkTokenString) : decodedParams = _decodeToken(sdkTokenString);

  /// Decodes the token to extract parameters
  static Map<String, String> _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return {};
      }

      final payload = parts[1];
      if (payload.isEmpty) {
        return {};
      }

      final decodedString = decodeBase64(payload);
      // decodeBase64 returns the original string if decoding fails
      if (decodedString == payload) {
        return {};
      }
      
      // Use URI class to parse query parameters
      final uri = Uri.parse('http://dummy.com?$decodedString');
      
      // Convert query parameters to a Map<String, String>
      final queryParams = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        queryParams[key] = value;
      });
      
      return queryParams;
    } catch (e) {
      // If there's an error parsing the token, return an empty map
      return {};
    }
  }

  /// Gets the subdomain from the decoded token.
  ///
  /// @return The subdomain or null if not present
  String? getSubdomain() {
    return decodedParams['cs'];
  }

  /// Gets the full SDK Key token string.
  String getToken() {
    return sdkTokenString;
  }

  /// Checks if the SDK Key had the subdomain encoded.
  ///
  /// @return true if the token is valid and contains required parameters
  bool isValid() {
    return decodedParams.isNotEmpty;
  }
}
