import 'constants.dart';
import 'sdk_key.dart';

/// Utility class for constructing Eppo API base URLs.
///
/// Determines the effective base URL considering baseUrl, subdomain from SDK token,
/// and defaultUrl in that order.
class ApiEndpoints {
  /// The SDK key
  final SDKKey sdkKey;
  
  /// Custom base URL (optional)
  final String? baseUrl;
  
  /// Default base URL
  final String defaultUrl;

  /// Creates a new ApiEndpoints instance.
  ///
  /// [sdkKey] SDK Key instance for subdomain
  /// [baseUrl] Custom base URL (optional)
  /// [defaultUrl] Default base URL (defaults to precomputedBaseUrl)
  ApiEndpoints({
    required this.sdkKey,
    this.baseUrl,
    String? defaultUrl,
  }) : defaultUrl = defaultUrl ?? precomputedBaseUrl;

  /// Gets the normalized base URL based on the following priority:
  /// 1. If baseUrl is provided and not equal to DEFAULT_BASE_URL, use it
  /// 2. If the SDK Key contains a subdomain, use it with DEFAULT_BASE_URL
  /// 3. Otherwise, fall back to DEFAULT_BASE_URL
  ///
  /// The returned URL will:
  /// - Always have a protocol (defaults to https:// if none provided)
  /// - Never end with a trailing slash
  ///
  /// @return The normalized base URL
  String getBaseUrl() {
    String effectiveUrl;

    if (baseUrl != null && baseUrl != defaultUrl) {
      // This is to prevent forcing the SDK to send requests to the CDN server without
      // a subdomain even when encoded in SDK Key.
      effectiveUrl = baseUrl!;
    } else if (sdkKey.isValid()) {
      final subdomain = sdkKey.getSubdomain();
      if (subdomain != null) {
        // Extract the domain part without protocol
        final domainPart = defaultUrl.replaceAll(RegExp(r'^(https?:)?//'), '');
        effectiveUrl = '$subdomain.$domainPart';
      } else {
        effectiveUrl = defaultUrl;
      }
    } else {
      effectiveUrl = defaultUrl;
    }

    // Remove any trailing slashes
    effectiveUrl = effectiveUrl.replaceAll(RegExp(r'/+$'), '');

    // Add protocol if missing
    if (!effectiveUrl.contains(RegExp(r'^(https?://|//)'))) {
      effectiveUrl = 'https://$effectiveUrl';
    }

    return effectiveUrl;
  }

  /// Gets the URL for the precomputed flags endpoint.
  ///
  /// @param queryParams Optional query parameters to append to the URL
  /// @return The full precomputed flags endpoint URL
  String getPrecomputedFlagsEndpoint([Map<String, String>? queryParams]) {
    final baseEndpoint = '${getBaseUrl()}$precomputedFlagsEndpoint';
    
    if (queryParams == null || queryParams.isEmpty) {
      return baseEndpoint;
    }
    
    // Convert the query parameters to a URI and append them to the base endpoint
    final uri = Uri.parse(baseEndpoint).replace(
      queryParameters: queryParams,
    );
    
    return uri.toString();
  }
  
  /// Builds a complete URL with the given path and query parameters.
  ///
  /// @param path The path to append to the base URL
  /// @param queryParams Optional query parameters to append to the URL
  /// @return The complete URL
  String buildUrl(String path, [Map<String, String>? queryParams]) {
    final baseUrl = getBaseUrl();
    final fullPath = path.startsWith('/') ? path : '/$path';
    final baseEndpoint = '$baseUrl$fullPath';
    
    if (queryParams == null || queryParams.isEmpty) {
      return baseEndpoint;
    }
    
    // Convert the query parameters to a URI and append them to the base endpoint
    final uri = Uri.parse(baseEndpoint).replace(
      queryParameters: queryParams,
    );
    
    return uri.toString();
  }
}
