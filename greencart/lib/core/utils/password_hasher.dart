import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hash kata sandi untuk autentikasi lokal DEMO.
/// Memakai salt acak dan SHA-256 berulang. Ini BUKAN pengaman setara produksi:
/// aplikasi produksi harus memakai server autentikasi dan algoritma
/// bcrypt/argon2, bukan penyimpanan lokal.
class PasswordHasher {
  static const _rounds = 2000;

  static String hash(String password, {String? salt}) {
    final s = salt ?? _newSalt();
    var digest = sha256.convert(utf8.encode('$s:$password')).bytes;
    for (var i = 0; i < _rounds; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(s)]).bytes;
    }
    return '$s:${base64Url.encode(digest)}';
  }

  static bool verify(String password, String stored) {
    final idx = stored.indexOf(':');
    if (idx < 0) return false;
    return hash(password, salt: stored.substring(0, idx)) == stored;
  }

  static String _newSalt() {
    final rnd = Random.secure();
    return base64Url.encode(List<int>.generate(12, (_) => rnd.nextInt(256)));
  }
}
