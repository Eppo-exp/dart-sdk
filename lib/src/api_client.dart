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
  final Duration requestTimeout;

  /// Creates a new API client
  EppoApiClient({
    required this.sdkKey,
    required this.sdkVersion,
    required this.sdkPlatform,
    String? baseUrl,
    Duration? requestTimeout,
    EppoHttpClient? httpClient,
  })  : baseUrl = baseUrl ?? eppoBaseUrl,
        requestTimeout = requestTimeout ?? defaultRequestTimeout,
        _httpClient = httpClient ?? DefaultEppoHttpClient();

  /// Fetches precomputed flags for a subject
  Future<ObfuscatedPrecomputedConfigurationResponse> fetchPrecomputedFlags(
    SubjectEvaluation subjectEvaluation,
  ) async {
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

    // Add validation for subject_key
    if (subjectEvaluation.subject.subjectKey.isEmpty) {
      throw ArgumentError('subject_key is required and cannot be empty');
    }

    // Prepare the payload
    final payload = {
      'subject_key': subjectEvaluation.subject.subjectKey,
      // Always provide a valid structure for subject_attributes even if it's null in the input
      'subject_attributes':
          subjectEvaluation.subject.subjectAttributes?.toJson() ??
              ContextAttributes().toJson(),
    };

    // Add bandit actions if available
    if (subjectEvaluation.banditActions != null) {
      payload['bandit_actions'] = subjectEvaluation.banditActions ?? {};
    }

    final responseData = await _httpClient.post(
      url,
      payload,
      requestTimeout,
      {},
    );

    return ObfuscatedPrecomputedConfigurationResponse.fromJson(responseData);
  }
}
