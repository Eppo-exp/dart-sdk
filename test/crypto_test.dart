import 'package:eppo/src/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('decodeStringMap', () {
    test('decodes both keys and values from base64', () {
      final decoded = decodeStringMap({
        encodeBase64('holdoutKey'): encodeBase64('activeHoldout'),
        encodeBase64('holdoutVariation'): encodeBase64('all_shipped'),
      });

      expect(
        decoded,
        equals({
          'holdoutKey': 'activeHoldout',
          'holdoutVariation': 'all_shipped',
        }),
      );
    });

    test('leaves plaintext keys unchanged when not valid base64', () {
      final decoded = decodeStringMap({
        'key1': encodeBase64('value1'),
      });

      expect(decoded, equals({'key1': 'value1'}));
    });

    test('returns empty map for empty input', () {
      expect(decodeStringMap({}), isEmpty);
    });
  });
}
