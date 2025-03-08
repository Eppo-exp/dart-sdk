import 'sdk_version.dart';
import 'constants.dart';
import 'http_client.dart';
import 'configuration_wire_protocol.dart';
import 'subject.dart';

/// API client for Eppo services
class EppoApiClient {
  final EppoHttpClient _httpClient;

  /// SDK key for authentication
  final String sdkKey;

  /// SDK version
  final String sdkVersion;

  /// SDK name
  final SdkPlatform sdkPlatform;

  /// Base URL for API requests
  final String baseUrl;

  /// Request timeout in milliseconds
  final int requestTimeoutMs;

  /// Creates a new API client
  EppoApiClient({
    required this.sdkKey,
    required this.sdkVersion,
    required this.sdkPlatform,
    String? baseUrl,
    int? requestTimeoutMs,
    EppoHttpClient? httpClient,
  })  : baseUrl = baseUrl ?? precomputedBaseUrl,
        requestTimeoutMs = requestTimeoutMs ?? defaultRequestTimeoutMs,
        _httpClient = httpClient ?? DefaultEppoHttpClient();

  /// Fetches precomputed flags for a subject
  Future<ObfuscatedPrecomputedConfigurationResponse> fetchPrecomputedFlags({
    required String subjectKey,
    required ContextAttributes subjectAttributes,
    Map<String, Map<String, Map<String, dynamic>>>? banditActions,
  }) async {
    // Build URL with query parameters
    final queryParams = {
      'apiKey': sdkKey,
      'sdkVersion': sdkVersion,
      'sdkName': getSdkName(sdkPlatform),
    };

    final uri = Uri.parse(baseUrl).replace(
      path: precomputedFlagsEndpoint,
      queryParameters: queryParams,
    );
    final url = uri.toString();

    // Prepare the payload
    final payload = {
      'subject_key': subjectKey,
      'subject_attributes': subjectAttributes.toJson(),
    };

    // Add bandit actions if available
    if (banditActions != null) {
      payload['bandit_actions'] = banditActions;
    }

    final responseData = await _httpClient.post(
      url,
      payload,
      requestTimeoutMs,
      {},
    );

    return ObfuscatedPrecomputedConfigurationResponse.fromJson(responseData);
  }
}
