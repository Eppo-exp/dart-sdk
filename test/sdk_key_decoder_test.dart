import 'dart:convert';
import 'package:test/test.dart';
import 'package:eppo/src/sdk_key_decoder.dart';

String encodeSdkKey({String? configHostname, String? eventHostname}) {
  final params = {
    if (configHostname != null) 'ch': configHostname,
    if (eventHostname != null) 'eh': eventHostname,
  };
  final queryString = Uri(queryParameters: params).query;
  final encodedPayload = base64.encode(utf8.encode(queryString));
  return 'zCsQuoHJxVPp895.$encodedPayload';
}

void main() {
  group('SdkKeyDecoder', () {
    test('should return null when SDK key has neither host', () {
      final hostname = SdkKeyDecoder.decodeConfigurationHostname(
        encodeSdkKey(),
      );
      expect(hostname, isNull);
    });

    test('should return null when SDK key has only event host', () {
      final hostname = SdkKeyDecoder.decodeConfigurationHostname(
        encodeSdkKey(eventHostname: '123456.e.testing.eppo.cloud'),
      );
      expect(hostname, isNull);
    });

    test('should decode configuration host when SDK key has both hosts', () {
      final hostname = SdkKeyDecoder.decodeConfigurationHostname(
        encodeSdkKey(
          configHostname: '123456.e.testing.fscdn.eppo.cloud',
          eventHostname: '123456.e.testing.eppo.cloud',
        ),
      );
      expect(hostname, equals('https://123456.e.testing.fscdn.eppo.cloud'));
    });

    test('should add https://h prefix to hostname without scheme', () {
      final hostname = SdkKeyDecoder.decodeConfigurationHostname(
        encodeSdkKey(configHostname: '123456.e.testing.fscdn.eppo.cloud'),
      );
      expect(hostname, equals('https://123456.e.testing.fscdn.eppo.cloud'));
    });
  });
}
