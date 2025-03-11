import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:eppo/eppo.dart';
import 'dart:io';

class FlagEvaluationBenchmark extends BenchmarkBase {
  FlagEvaluationBenchmark(this.sdkKey, this.subjectKey)
      : super('FlagEvaluation');

  final String sdkKey;
  final String subjectKey;

  static void main(String sdkKey, String subjectKey) {
    FlagEvaluationBenchmark(sdkKey, subjectKey).report();
  }

  // The benchmark code.
  @override
  void run() {
    Eppo.getStringAssignment('dart-test-flag-string', 'default-string');
  }

  // Not measured setup code executed prior to the benchmark runs.
  @override
  void setup() {
    Eppo.initialize(
        sdkKey,
        SubjectEvaluation(subject: Subject(subjectKey: subjectKey)),
        ClientConfiguration());
  }

  // Not measured teardown code executed after the benchmark runs.
  @override
  void teardown() {}
}

void main(List<String> args) async {
  // Check for SDK key in arguments
  if (args.isEmpty) {
    print(
      'Usage: dart benchmark/flag_evaluation.dart <sdk-key> <subject-key>',
    );
    exit(1);
  }

  final sdkKey = args[0];
  final subjectKey = args.length > 1 ? args[1] : 'user-123';

  FlagEvaluationBenchmark.main(sdkKey, subjectKey);
}
