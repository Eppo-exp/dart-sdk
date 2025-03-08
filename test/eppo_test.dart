import 'package:eppo/eppo.dart';
import 'package:test/test.dart';

void main() {
  group('Eppo', () {
    setUp(() {
      // Reset Eppo before each test to ensure a clean state
      Eppo.reset();
    });

    test('getBooleanAssignment returns default value when not initialized', () {
      // Arrange
      const flagKey = 'test-flag';
      const defaultValue = true;

      // Act
      final result = Eppo.getBooleanAssignment(flagKey, defaultValue);

      // Assert
      expect(result, equals(defaultValue));
    });
  });
}
