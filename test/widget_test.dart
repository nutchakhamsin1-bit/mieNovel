import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/security.dart';

void main() {
  group('PasswordHasher', () {
    test('hash + verify roundtrip works', () {
      final hashed = PasswordHasher.hash('correctHorseBattery42');
      expect(PasswordHasher.verify('correctHorseBattery42', hashed), isTrue);
      expect(PasswordHasher.verify('wrong', hashed), isFalse);
    });

    test('hash is salted (two hashes of same password differ)', () {
      final a = PasswordHasher.hash('same-password');
      final b = PasswordHasher.hash('same-password');
      expect(a, isNot(equals(b)));
    });

    test('isHashed detects raw vs hashed strings', () {
      expect(PasswordHasher.isHashed('hello'), isFalse);
      expect(PasswordHasher.isHashed(PasswordHasher.hash('hi')), isTrue);
    });

    test('verify falls back to equality for legacy plain-text values', () {
      expect(PasswordHasher.verify('legacy', 'legacy'), isTrue);
      expect(PasswordHasher.verify('legacy', 'other'), isFalse);
    });
  });

  group('InputValidator', () {
    test('rejects bad emails', () {
      expect(InputValidator.validateEmail(''), isNotNull);
      expect(InputValidator.validateEmail('not-an-email'), isNotNull);
      expect(InputValidator.validateEmail('ok@example.com'), isNull);
    });

    test('rejects short or wrong usernames', () {
      expect(InputValidator.validateUsername('a'), isNotNull);
      expect(InputValidator.validateUsername('hi user'), isNotNull);
      expect(InputValidator.validateUsername('ok_user.1'), isNull);
    });

    test('rejects short passwords', () {
      expect(InputValidator.validatePassword('abc'), isNotNull);
      expect(InputValidator.validatePassword('abcdef'), isNull);
    });
  });

  testWidgets('AppTheme renders without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(title: const Text('Mie Novel')),
          body: const Center(child: Text('Hello')),
        ),
      ),
    );
    expect(find.text('Mie Novel'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
