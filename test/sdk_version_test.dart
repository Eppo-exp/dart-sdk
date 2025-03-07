import 'package:eppo/src/sdk_version.dart';
import 'package:test/test.dart';

void main() {
  group('SDK Version', () {
    test('getSdkVersion returns correct version', () {
      expect(getSdkVersion(), '1.0.0');
    });

    test('getSdkName returns correct name for dart platform', () {
      expect(getSdkName(SdkPlatform.dart), 'eppo-dart');
    });

    test('getSdkName returns correct name for Flutter platforms', () {
      expect(
        getSdkName(SdkPlatform.flutterWeb),
        'eppo-dart-flutter-client-web',
      );
      expect(
        getSdkName(SdkPlatform.flutterIos),
        'eppo-dart-flutter-client-ios',
      );
      expect(
        getSdkName(SdkPlatform.flutterAndroid),
        'eppo-dart-flutter-client-android',
      );
      expect(
        getSdkName(SdkPlatform.unknown),
        'eppo-dart-unknown',
      );
    });

    test('SdkPlatform enum has expected values', () {
      expect(SdkPlatform.values.length, 5);
      expect(SdkPlatform.values, contains(SdkPlatform.dart));
      expect(SdkPlatform.values, contains(SdkPlatform.flutterWeb));
      expect(SdkPlatform.values, contains(SdkPlatform.flutterIos));
      expect(SdkPlatform.values, contains(SdkPlatform.flutterAndroid));
      expect(SdkPlatform.values, contains(SdkPlatform.unknown));
    });
  });
}
