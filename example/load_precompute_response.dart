import 'dart:io';
import 'package:eppo/eppo_sdk.dart';
import 'package:eppo/src/api_client.dart';
import 'package:eppo/src/http_client.dart';
import 'package:eppo/src/sdk_version.dart' as sdk;
import 'package:eppo/src/subject.dart';

void main(List<String> args) async {
  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart example/load_precompute_response.dart <sdk-key> [subject-key]',
    );
    exit(1);
  }

  final sdkKey = args[0];
  final subjectKey = args.length > 1 ? args[1] : 'user-123';

  print('Using SDK key: $sdkKey');
  print('Using subject key: $subjectKey');

  // Create API client
  final apiClient = EppoApiClient(
    sdkKey: sdkKey,
    sdkVersion: '1.0.0',
    sdkPlatform: sdk.SdkPlatform.dart,
    httpClient: DefaultEppoHttpClient(),
  );

  // Create subject attributes
  final attributes = ContextAttributes(
    categoricalAttributes: {'country': 'US', 'device': 'mobile'},
    numericAttributes: {'age': 30, 'visits': 5},
  );

  // Fetch precomputed flags
  final response = await apiClient.fetchPrecomputedFlags(
    subjectKey: subjectKey,
    subjectAttributes: attributes,
  );

  // Print the response
  print(
    'Received ${response.flags.length} flags and ${response.bandits.length} bandits',
  );

  response.flags.forEach((key, flag) {
    print('Flag: $key');
    print('allocationKey: ${flag.allocationKey}');
    print('variationKey: ${flag.variationKey}');
    print('variationType: ${flag.variationType}');
    print('variationValue: ${flag.variationValue}');
    print('');
  });

  response.bandits.forEach((key, bandit) {
    print('Bandit: $key');
    print(bandit);
  });

  exit(0);
}
