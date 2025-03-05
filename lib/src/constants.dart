/// Default base URL for Eppo API
const String precomputedBaseUrl = 'https://fs-edge-assignment.eppo.cloud';

/// Precomputed flags endpoint for fetching assignments
const String precomputedFlagsEndpoint = '/assignments';

/// Default request timeout in milliseconds
const int defaultRequestTimeoutMs = 5000;

/// SDK platform enum
enum SdkPlatform {
  dart,
  flutter,
  other;

  @override
  String toString() {
    switch (this) {
      case SdkPlatform.dart:
        return 'dart';
      case SdkPlatform.flutter:
        return 'flutter';
      case SdkPlatform.other:
        return 'other';
    }
  }
}
