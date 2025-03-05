/// The current SDK version (private)
const String _sdkVersion = '1.0.0';

/// Supported SDK platforms
enum SdkPlatform {
  /// Dart platform
  dart,

  /// Flutter web platform
  flutterWeb,

  /// Flutter iOS platform
  flutterIos,

  /// Flutter Android platform
  flutterAndroid,
}

/// Returns the SDK version
String getSdkVersion() {
  return _sdkVersion;
}

/// Returns the SDK name prefix
const String _sdkNamePrefix = 'eppo-dart';

/// Returns the SDK name based on platform
String getSdkName(SdkPlatform platform) {
  switch (platform) {
    case SdkPlatform.dart:
      return _sdkNamePrefix;
    case SdkPlatform.flutterWeb:
      return '$_sdkNamePrefix-flutter-client-web';
    case SdkPlatform.flutterIos:
      return '$_sdkNamePrefix-flutter-client-ios';
    case SdkPlatform.flutterAndroid:
      return '$_sdkNamePrefix-flutter-client-android';
  }
}
