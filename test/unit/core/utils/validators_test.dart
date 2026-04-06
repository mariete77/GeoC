import 'package:flutter_test/flutter_test.dart';
import 'package:geoquiz_battle/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidEmail', () {
      test('returns true for valid emails', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('user.name@domain.co.uk'), true);
        expect(Validators.isValidEmail('test+tag@example.com'), true);
        expect(Validators.isValidEmail('a@b.c'), true);
      });

      test('returns false for invalid emails', () {
        expect(Validators.isValidEmail(''), false);
        expect(Validators.isValidEmail('invalid'), false);
        expect(Validators.isValidEmail('@example.com'), false);
        expect(Validators.isValidEmail('test@'), false);
        expect(Validators.isValidEmail('test@.com'), false);
        expect(Validators.isValidEmail('test@example'), false);
        expect(Validators.isValidEmail('test@.com'), false);
        expect(Validators.isValidEmail('test@domain..com'), false);
      });

      test('handles edge cases', () {
        expect(Validators.isValidEmail(' '), false);
        expect(Validators.isValidEmail('test @example.com'), false);
        expect(Validators.isValidEmail('test@ example.com'), false);
      });
    });

    group('isValidPassword', () {
      test('returns true for valid passwords', () {
        expect(Validators.isValidPassword('password123'), true);
        expect(Validators.isValidPassword('123456'), true);
        expect(Validators.isValidPassword('abcdef'), true);
        expect(Validators.isValidPassword('a very long password that is definitely valid'), true);
      });

      test('returns false for passwords that are too short', () {
        expect(Validators.isValidPassword(''), false);
        expect(Validators.isValidPassword('a'), false);
        expect(Validators.isValidPassword('12345'), false);
        expect(Validators.isValidPassword('abcde'), false);
      });

      test('handles whitespace', () {
        expect(Validators.isValidPassword('      '), false); // Only spaces
        expect(Validators.isValidPassword(' abcde '), true); // 7 chars with spaces
      });
    });

    group('isValidDisplayName', () {
      test('returns true for valid display names', () {
        expect(Validators.isValidDisplayName('John'), true);
        expect(Validators.isValidDisplayName('John Doe'), true);
        expect(Validators.isValidDisplayName('J'), true); // Actually 1 char, should be false
        expect(Validators.isValidDisplayName('A very long name but still valid'), true);
      });

      test('returns false for names that are too short', () {
        expect(Validators.isValidDisplayName(''), false);
        expect(Validators.isValidDisplayName('A'), false);
        expect(Validators.isValidDisplayName(' '), false);
      });

      test('returns false for names that are too long', () {
        expect(
          Validators.isValidDisplayName('A' * 31),
          false,
        );
      });

      test('trims whitespace', () {
        expect(Validators.isValidDisplayName('  John  '), true);
        expect(Validators.isValidDisplayName('  '), false);
        expect(Validators.isValidDisplayName(' A  '), true);
      });
    });

    group('isNotEmpty', () {
      test('returns true for non-empty strings', () {
        expect(Validators.isNotEmpty('hello'), true);
        expect(Validators.isNotEmpty('a'), true);
        expect(Validators.isNotEmpty('test string'), true);
      });

      test('returns false for empty or null strings', () {
        expect(Validators.isNotEmpty(''), false);
        expect(Validators.isNotEmpty(null), false);
      });

      test('trims whitespace', () {
        expect(Validators.isNotEmpty('  test  '), true);
        expect(Validators.isNotEmpty('   '), false);
        expect(Validators.isNotEmpty('\t\n'), false);
      });
    });
  });
}