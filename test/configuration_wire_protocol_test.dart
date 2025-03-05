import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:eppo/src/configuration_wire_protocol.dart';

void main() {
  group('ObfuscatedPrecomputedConfigurationResponse', () {
    // Setup - load and parse test data once
    late Map<String, dynamic> response;

    setUpAll(() {
      final jsonString = File(
        'test/test-sample-data/configuration-wire/precomputed-v1.json',
      ).readAsStringSync();

      final jsonData = jsonDecode(jsonString);
      final responseString = jsonData['precomputed']['response'] as String;
      response = jsonDecode(responseString);
    });

    test('should parse from JSON correctly', () {
      // Parse the JSON
      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        response,
      );

      // Verify the basic properties
      expect(config.obfuscated, isTrue);
      expect(config.format, equals(FormatEnum.precomputed));
      expect(config.salt, equals('c29kaXVtY2hsb3JpZGU='));
      expect(config.createdAt, equals('2024-11-18T14:23:25.123Z'));
      expect(config.environment, equals('Test'));
    });

    test('should parse flags correctly', () {
      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        response,
      );

      // Verify the flags
      expect(config.flags.length, equals(6));

      // Check the first flag (STRING type)
      final stringFlag = config.flags['41a27b85ebdd7b1a5ae367a1a240a214'];
      expect(stringFlag, isNotNull);
      expect(stringFlag!.variationType, equals(VariationType.string));
      expect(stringFlag.variationValue, equals('cmVk'));
      expect(stringFlag.doLog, isTrue);
      expect(stringFlag.allocationKey, equals('YWxsb2NhdGlvbi0xMjM='));
      expect(stringFlag.variationKey, equals('dmFyaWF0aW9uLTEyMw=='));
      expect(stringFlag.extraLogging, isEmpty);

      // Check the boolean flag
      final booleanFlag = config.flags['2309e3afb59efcf9675c0a8eaa565879'];
      expect(booleanFlag, isNotNull);
      expect(booleanFlag!.variationType, equals(VariationType.boolean));
      expect(booleanFlag.variationValue, equals('dHJ1ZQ=='));

      // Check the integer flag
      final integerFlag = config.flags['06307a361b7f244ca792cc0dc5f264f7'];
      expect(integerFlag, isNotNull);
      expect(integerFlag!.variationType, equals(VariationType.integer));
      expect(integerFlag.variationValue, equals('NDI='));

      // Check the numeric flag
      final numericFlag = config.flags['60d9c95b958bdfe620111a1ab618c1f2'];
      expect(numericFlag, isNotNull);
      expect(numericFlag!.variationType, equals(VariationType.numeric));
      expect(numericFlag.variationValue, equals('My4xNA=='));

      // Check the JSON flag
      final jsonFlag = config.flags['155bbb597e48b282ceff3a342f28001f'];
      expect(jsonFlag, isNotNull);
      expect(jsonFlag!.variationType, equals(VariationType.json));
      expect(
        jsonFlag.variationValue,
        equals('eyJrZXkiOiJ2YWx1ZSIsIm51bWJlciI6MTIzfQ=='),
      );
    });

    test('should handle extra logging correctly', () {
      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        response,
      );

      // Check flag with extra logging
      final flagWithLogging = config.flags['35f919d963a541a0bd28f349f84050fb'];
      expect(flagWithLogging, isNotNull);
      expect(flagWithLogging!.extraLogging, isNotEmpty);
      expect(
        flagWithLogging.extraLogging!['aG9sZG91dEtleQ=='],
        equals('YWN0aXZlSG9sZG91dA=='),
      );
      expect(
        flagWithLogging.extraLogging!['aG9sZG91dFZhcmlhdGlvbg=='],
        equals('YWxsX3NoaXBwZWQ='),
      );
    });

    test('should handle empty bandits correctly', () {
      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        response,
      );

      // Verify bandits is empty
      expect(config.bandits, isEmpty);
    });
  });
}
