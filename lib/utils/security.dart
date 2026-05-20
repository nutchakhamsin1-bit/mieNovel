import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _saltLength = 16;
  static const int _iterations = 10000;
  static const String _prefix = 'sha256';

  static String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(_saltLength, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _pbkdf2(String password, String salt) {
    List<int> bytes = utf8.encode('$salt$password');
    for (var i = 0; i < _iterations; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Url.encode(bytes);
  }

  static String hash(String password) {
    final salt = _generateSalt();
    final digest = _pbkdf2(password, salt);
    return '$_prefix\$$_iterations\$$salt\$$digest';
  }

  static bool verify(String password, String? stored) {
    if (stored == null || stored.isEmpty) return false;
    final parts = stored.split('\$');
    if (parts.length != 4 || parts[0] != _prefix) {
      return stored == password;
    }
    final salt = parts[2];
    final digest = parts[3];
    final candidate = _pbkdf2(password, salt);
    return _constantTimeEquals(candidate, digest);
  }

  static bool isHashed(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('$_prefix\$');
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

class InputValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อผู้ใช้';
    }
    final trimmed = value.trim();
    if (!_usernameRegex.hasMatch(trimmed)) {
      return 'ชื่อผู้ใช้ต้องมี 3-20 ตัวอักษร (a-z, 0-9, _ .)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  static String? validateName(String? value, {String field = 'ข้อมูล'}) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอก$field';
    }
    if (value.trim().length < 2) {
      return '$fieldสั้นเกินไป';
    }
    return null;
  }

  static String sanitize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
