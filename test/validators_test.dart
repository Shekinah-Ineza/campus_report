import 'package:campus_report/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('student'), isNotNull);
      expect(Validators.email('student@uni'), isNotNull);
    });
    test('accepts a valid email, ignoring surrounding spaces', () {
      expect(Validators.email(' a.student@uni.edu '), isNull);
    });
  });

  group('Validators.password', () {
    test('requires at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.title', () {
    test('enforces 5 to 100 characters after trimming', () {
      expect(Validators.title('   abc   '), isNotNull);
      expect(Validators.title('Broken tap'), isNull);
      expect(Validators.title('x' * 101), isNotNull);
    });
  });

  group('Validators.description', () {
    test('enforces 10 to 1000 characters', () {
      expect(Validators.description('too short'), isNotNull);
      expect(Validators.description('The tap in room 4 leaks.'), isNull);
      expect(Validators.description('x' * 1001), isNotNull);
    });
  });
}
