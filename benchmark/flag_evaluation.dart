import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:eppo/eppo.dart';
import 'dart:io';

// Base class for all flag evaluation benchmarks
abstract class BaseFlagBenchmark extends BenchmarkBase {
  BaseFlagBenchmark(super.name, this.sdkKey, this.subjectKey);

  final String sdkKey;
  final String subjectKey;

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

// String flag benchmark
class StringFlagBenchmark extends BaseFlagBenchmark {
  StringFlagBenchmark(String sdkKey, String subjectKey)
      : super('StringFlag', sdkKey, subjectKey);

  @override
  void run() {
    Eppo.getStringAssignment('dart-test-flag-string', 'default-string');
  }
}

// Boolean flag benchmark
class BooleanFlagBenchmark extends BaseFlagBenchmark {
  BooleanFlagBenchmark(String sdkKey, String subjectKey)
      : super('BooleanFlag', sdkKey, subjectKey);

  @override
  void run() {
    Eppo.getBooleanAssignment('dart-test-flag-boolean', false);
  }
}

// Integer flag benchmark
class IntegerFlagBenchmark extends BaseFlagBenchmark {
  IntegerFlagBenchmark(String sdkKey, String subjectKey)
      : super('IntegerFlag', sdkKey, subjectKey);

  @override
  void run() {
    Eppo.getIntegerAssignment('dart-test-flag-integer', 0);
  }
}

// Numeric flag benchmark
class NumericFlagBenchmark extends BaseFlagBenchmark {
  NumericFlagBenchmark(String sdkKey, String subjectKey)
      : super('NumericFlag', sdkKey, subjectKey);

  @override
  void run() {
    Eppo.getNumericAssignment('dart-test-flag-numeric', 0.0);
  }
}

// JSON flag benchmark
class JSONFlagBenchmark extends BaseFlagBenchmark {
  JSONFlagBenchmark(String sdkKey, String subjectKey)
      : super('JSONFlag', sdkKey, subjectKey);

  @override
  void run() {
    Eppo.getJSONAssignment('dart-test-flag-json', {});
  }
}

// Bandit action benchmark
class BanditActionBenchmark extends BaseFlagBenchmark {
  BanditActionBenchmark(String sdkKey, String subjectKey)
      : super('BanditAction', sdkKey, subjectKey);

  @override
  void run() {
    Eppo.getBanditAction('update-highlights-bandit', 'default-bandit');
  }
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

  // Run all benchmarks
  print('Running individual benchmarks for each flag type...\n');

  StringFlagBenchmark(sdkKey, subjectKey).report();
  BooleanFlagBenchmark(sdkKey, subjectKey).report();
  IntegerFlagBenchmark(sdkKey, subjectKey).report();
  NumericFlagBenchmark(sdkKey, subjectKey).report();
  JSONFlagBenchmark(sdkKey, subjectKey).report();
  BanditActionBenchmark(sdkKey, subjectKey).report();
}

// Combined benchmark for all methods
class FlagEvaluationBenchmark extends BaseFlagBenchmark {
  FlagEvaluationBenchmark(String sdkKey, String subjectKey)
      : super('AllFlags', sdkKey, subjectKey);

  @override
  void run() {
    // Test all assignment methods
    Eppo.getStringAssignment('dart-test-flag-string', 'default-string');
    Eppo.getBooleanAssignment('dart-test-flag-boolean', false);
    Eppo.getIntegerAssignment('dart-test-flag-integer', 0);
    Eppo.getNumericAssignment('dart-test-flag-numeric', 0.0);
    Eppo.getJSONAssignment('dart-test-flag-json', {});
    Eppo.getBanditAction('update-highlights-bandit', 'default-bandit');
  }
}
