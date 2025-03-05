import 'package:eppo/eppo_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final eppo = Eppo();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(eppo.isAwesome, isTrue);
    });
  });
}
