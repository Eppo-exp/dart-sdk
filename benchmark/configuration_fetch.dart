import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:eppo/eppo.dart';
import 'dart:io';

class ConfigurationFetchBenchmark extends AsyncBenchmarkBase {
  ConfigurationFetchBenchmark(this.sdkKey, this.subjectKey)
      : super('ConfigurationFetch');

  final String sdkKey;
  final String subjectKey;

  static Future<void> main(String sdkKey, String subjectKey) async {
    final benchmark = ConfigurationFetchBenchmark(sdkKey, subjectKey);
    await benchmark.report();

    // Add custom reporting in milliseconds
    final microseconds = await benchmark.measure();
    final milliseconds = microseconds / 1000;
    print('${benchmark.name}: ${milliseconds.toStringAsFixed(2)} ms');
  }

  // The benchmark code.
  @override
  Future<void> run() async {
    // Reset the SDK before each run to ensure we're testing initialization
    Eppo.reset();

    // Measure the time it takes to initialize the SDK
    await Eppo.initialize(
        sdkKey,
        SubjectEvaluation(subject: Subject(subjectKey: subjectKey)),
        ClientConfiguration());
  }

  // Not measured setup code executed prior to the benchmark runs.
  @override
  Future<void> setup() async {
    // No setup needed as we're testing the initialization itself
  }

  // Not measured teardown code executed after the benchmark runs.
  @override
  Future<void> teardown() async {
    Eppo.reset();
  }
}

void main(List<String> args) async {
  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart benchmark/configuration_fetch.dart <sdk-key> <subject-key>',
    );
    exit(1);
  }

  final sdkKey = args[0];
  final subjectKey = args.length > 1 ? args[1] : 'user-123';

  await ConfigurationFetchBenchmark.main(sdkKey, subjectKey);
}
