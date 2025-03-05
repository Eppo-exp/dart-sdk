import 'package:eppo/eppo_sdk.dart';
import 'package:eppo/src/http_client.dart';
import 'package:eppo/src/sdk_version.dart' as sdk;

/// API client for Eppo services
class EppoApiClient {
  final EppoHttpClient _httpClient;

  /// SDK key for authentication
  final String sdkKey;

  /// SDK version
  final String sdkVersion;

  /// SDK name
  final sdk.SdkPlatform sdkPlatform;

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
  }) : baseUrl = baseUrl ?? precomputedBaseUrl,
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
      'sdkName': sdkPlatform.toString(),
    };

    final queryString = queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    final url = '$baseUrl$precomputedFlagsEndpoint?$queryString';

    print('Fetching precomputed flags from $url');
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
