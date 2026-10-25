import 'package:sqflite/sqflite.dart';

import '../../core/errors.dart';
import '../../core/utils/validators.dart';
import '../models/models.dart';

class AddressRepository {
  AddressRepository(this._db);
  final Database _db;

  Future<List<Address>> list(int userId) async {
    final rows = await _db.query('addresses', where: 'user_id = ?', whereArgs: [userId], orderBy: 'is_default DESC, id');
    return rows.map(Address.fromMap).toList();
  }

  Future<void> save(Address a) async {
    final err = Validators.name(a.recipientName) ?? Validators.phone(a.phone) ?? Validators.address(a.addressLine);
    if (err != null) throw AppException(err);
    await _db.transaction((txn) async {
      final count = Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM addresses WHERE user_id = ?', [a.userId])) ??
          0;
      final makeDefault = a.isDefault || (a.id == null && count == 0);
      if (makeDefault) await txn.update('addresses', {'is_default': 0}, where: 'user_id = ?', whereArgs: [a.userId]);
      final map = Address(
        id: a.id,
        userId: a.userId,
        recipientName: a.recipientName.trim(),
        phone: a.phone.trim(),
        addressLine: a.addressLine.trim(),
        areaNote: a.areaNote.trim(),
        isDefault: makeDefault,
      ).toMap();
      if (a.id == null) {
        await txn.insert('addresses', map);
      } else {
        await txn.update('addresses', map, where: 'id = ?', whereArgs: [a.id]);
      }
    });
  }

  Future<void> delete(int id) => _db.delete('addresses', where: 'id = ?', whereArgs: [id]);
}
