import 'dart:convert';
import 'package:logging/logging.dart';

/// A class for decoding SDK keys and extracting configuration hostname
class SdkKeyDecoder {
  static const String _paramName = 'ch';

  static final Logger _logger = Logger('SdkKeyDecoder');

  /// Decodes and returns the configuration hostname from the provided Eppo SDK key string.
  /// If the SDK key doesn't contain the configuration hostname, or it's invalid, it returns null.
  static String? decodeConfigurationHostname(String sdkKey) {
    final parts = sdkKey.split('.');
    if (parts.length < 2) return null;

    final encodedPayload = parts[1];
    if (encodedPayload.isEmpty) return null;

    try {
      final decodedPayload = utf8.decode(base64.decode(encodedPayload));
      final params = Uri.splitQueryString(decodedPayload);
      final hostname = params[_paramName];
      if (hostname == null || hostname.isEmpty) return null;

      if (!hostname.startsWith('http://') && !hostname.startsWith('https://')) {
        // prefix hostname with https scheme if none present
        return 'https://$hostname';
      } else {
        return hostname;
      }
    } catch (e) {
      // Canonical Dart logging for `debug` level
      _logger.fine('Error decoding configuration hostname: $e');
      return null;
    }
  }
}
