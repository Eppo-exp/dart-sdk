import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exception thrown when an HTTP request fails
class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}

/// Interface for HTTP client used by the Eppo API client
abstract class EppoHttpClient {
  /// Performs a POST request to the specified URL
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> payload,
    Duration timeout,
    Map<String, String> headers,
  );
}

/// Default implementation of EppoHttpClient using the http package
class DefaultEppoHttpClient implements EppoHttpClient {
  final http.Client _client;

  DefaultEppoHttpClient([http.Client? client])
      : _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> payload,
    Duration timeout,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json', ...headers},
      ).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw HttpException(
          'Request failed with status: ${response.statusCode}',
        );
      }
    } on FormatException {
      throw FormatException('Invalid JSON response');
    } on TimeoutException {
      throw TimeoutException(
          'Request timed out after ${timeout.inMilliseconds}ms');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
