import 'dart:convert';
import 'dart:io';
import 'package:eppo/src/crypto.dart';
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
      expect(config.flags.length, greaterThanOrEqualTo(6));

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

    test('should parse bandits correctly', () {
      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        response,
      );

      // Verify the bandits
      expect(config.bandits.length, equals(2));

      // Check the first bandit
      final stringFlagBandit = config.bandits[
          '41a27b85ebdd7b1a5ae367a1a240a214']; // hash for 'string-flag'
      expect(stringFlagBandit, isNotNull);
      expect(
          stringFlagBandit!.banditKey,
          equals(
              'cmVjb21tZW5kYXRpb24tbW9kZWwtdjE=')); // 'recommendation-model-v1' encoded
      expect(stringFlagBandit.action,
          equals('c2hvd19yZWRfYnV0dG9u')); // 'show_red_button' encoded
      expect(stringFlagBandit.actionProbability, equals(0.85));
      expect(stringFlagBandit.optimalityGap, equals(0.12));
      expect(stringFlagBandit.modelVersion,
          equals('djIuMy4x')); // 'v2.3.1' encoded

      // Check numeric attributes
      expect(stringFlagBandit.actionNumericAttributes, isNotNull);
      expect(stringFlagBandit.actionNumericAttributes.length, equals(2));
      expect(
        stringFlagBandit.actionNumericAttributes[
            'ZXhwZWN0ZWRDb252ZXJzaW9u'], // 'expectedConversion' encoded
        equals('MC4yMw=='), // '0.23' encoded
      );
      expect(
        stringFlagBandit.actionNumericAttributes[
            'ZXhwZWN0ZWRSZXZlbnVl'], // 'expectedRevenue' encoded
        equals('MTUuNzU='), // '15.75' encoded
      );

      // Check categorical attributes
      expect(stringFlagBandit.actionCategoricalAttributes, isNotNull);
      expect(stringFlagBandit.actionCategoricalAttributes.length, equals(2));
      expect(
        stringFlagBandit
            .actionCategoricalAttributes['Y2F0ZWdvcnk='], // 'category' encoded
        equals('cHJvbW90aW9u'), // 'promotion' encoded
      );
      expect(
        stringFlagBandit
            .actionCategoricalAttributes['cGxhY2VtZW50'], // 'placement' encoded
        equals('aG9tZV9zY3JlZW4='), // 'home_screen' encoded
      );

      // Check the second bandit
      final extraLoggingFlagBandit = config.bandits[
          '35f919d963a541a0bd28f349f84050fb']; // hash for 'string-flag-with-extra-logging'
      expect(extraLoggingFlagBandit, isNotNull);
      expect(
          extraLoggingFlagBandit!.banditKey,
          equals(
              'Y29udGVudC1yZWNvbW1lbmRhdGlvbg==')); // 'content-recommendation' encoded
      expect(extraLoggingFlagBandit.action,
          equals('ZmVhdHVyZWRfY29udGVudA==')); // 'featured_content' encoded
      expect(extraLoggingFlagBandit.actionProbability, equals(0.72));
      expect(extraLoggingFlagBandit.optimalityGap, equals(0.08));
      expect(extraLoggingFlagBandit.modelVersion,
          equals('djEuNS4w')); // 'v1.5.0' encoded
    });

    test('should decode bandit values correctly', () {
      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        response,
      );

      final stringFlagBandit = config.bandits[
          '41a27b85ebdd7b1a5ae367a1a240a214']!; // hash for 'string-flag'

      // Test decoding of string values
      expect(decodeBase64(stringFlagBandit.banditKey),
          equals('recommendation-model-v1'));
      expect(decodeBase64(stringFlagBandit.action), equals('show_red_button'));
      expect(decodeBase64(stringFlagBandit.modelVersion), equals('v2.3.1'));

      // Test decoding of numeric attributes
      final decodedNumericAttrs = stringFlagBandit.actionNumericAttributes.map(
        (key, value) => MapEntry(
          decodeBase64(key),
          double.parse(decodeBase64(value)),
        ),
      );
      expect(decodedNumericAttrs['expectedConversion'], equals(0.23));
      expect(decodedNumericAttrs['expectedRevenue'], equals(15.75));

      // Test decoding of categorical attributes
      final decodedCategoricalAttrs =
          stringFlagBandit.actionCategoricalAttributes.map(
        (key, value) => MapEntry(
          decodeBase64(key),
          decodeBase64(value),
        ),
      );
      expect(decodedCategoricalAttrs['category'], equals('promotion'));
      expect(decodedCategoricalAttrs['placement'], equals('home_screen'));
    });

    test('should handle missing bandits gracefully', () {
      // Create a response without bandits
      final responseWithoutBandits = Map<String, dynamic>.from(response);
      responseWithoutBandits.remove('bandits');

      final config = ObfuscatedPrecomputedConfigurationResponse.fromJson(
        responseWithoutBandits,
      );

      // Verify bandits is empty but not null
      expect(config.bandits, isNotNull);
      expect(config.bandits, isEmpty);
    });
  });
}
