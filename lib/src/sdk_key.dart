import 'dart:convert';
import 'crypto.dart';

/// Wrapper for an SDK key; built from the SDK Key token string, this class extracts encoded fields,
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
      final queryPairs = <String, String>{};
      final pairs = decodedString.split('&');

      for (final pair in pairs) {
        if (pair.isEmpty) {
          continue;
        }
        final pairParts = pair.split('=');
        final key = Uri.decodeComponent(pairParts[0]);
        final value = pairParts.length > 1 ? Uri.decodeComponent(pairParts[1]) : null;

        if (value != null) {
          queryPairs[key] = value;
        }
      }
      return queryPairs;
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
