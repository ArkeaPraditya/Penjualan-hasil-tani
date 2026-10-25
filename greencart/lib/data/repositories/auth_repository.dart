import 'package:sqflite/sqflite.dart';

import '../../core/errors.dart';
import '../../core/utils/password_hasher.dart';
import '../../core/utils/validators.dart';
import '../models/models.dart';

class AuthRepository {
  AuthRepository(this._db);
  final Database _db;

  String _normalize(String v) => v.trim().toLowerCase().replaceAll(RegExp(r'[\s-]'), '');

  Future<AppUser> register({
    required String name,
    required String emailOrPhone,
    required String password,
    UserRole role = UserRole.buyer,
  }) async {
    final err = Validators.name(name) ?? Validators.emailOrPhone(emailOrPhone) ?? Validators.password(password);
    if (err != null) throw AppException(err);
    final login = _normalize(emailOrPhone);
    final exists = await _db.query('users', where: 'email_or_phone = ?', whereArgs: [login], limit: 1);
    if (exists.isNotEmpty) throw AppException('Email atau nomor HP ini sudah terdaftar. Silakan masuk.');
    final id = await _db.insert('users', {
      'name': name.trim(),
      'email_or_phone': login,
      'password_hash': PasswordHasher.hash(password),
      'role': role == UserRole.seller ? 'seller' : 'buyer',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return (await getById(id))!;
  }

  Future<AppUser> login(String emailOrPhone, String password) async {
    final rows = await _db.query('users', where: 'email_or_phone = ?', whereArgs: [_normalize(emailOrPhone)], limit: 1);
    if (rows.isEmpty || !PasswordHasher.verify(password, rows.first['password_hash'] as String)) {
      throw AppException('Email/nomor HP atau kata sandi salah.');
    }
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> getById(int id) async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser> updateProfile(int id, {required String name, required String emailOrPhone}) async {
    final err = Validators.name(name) ?? Validators.emailOrPhone(emailOrPhone);
    if (err != null) throw AppException(err);
    final login = _normalize(emailOrPhone);
    final clash = await _db.query('users', where: 'email_or_phone = ? AND id != ?', whereArgs: [login, id], limit: 1);
    if (clash.isNotEmpty) throw AppException('Email atau nomor HP sudah dipakai akun lain.');
    await _db.update('users', {'name': name.trim(), 'email_or_phone': login}, where: 'id = ?', whereArgs: [id]);
    return (await getById(id))!;
  }
}
