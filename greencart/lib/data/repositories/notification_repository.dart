import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class NotificationRepository {
  NotificationRepository(this._db);
  final Database _db;

  Future<List<AppNotification>> list(int userId) async {
    final rows = await _db.query('notifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC, id DESC');
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markRead(int id) => _db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);

  Future<void> markAllRead(int userId) =>
      _db.update('notifications', {'is_read': 1}, where: 'user_id = ?', whereArgs: [userId]);
}
