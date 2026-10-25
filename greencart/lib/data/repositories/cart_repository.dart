import 'package:sqflite/sqflite.dart';

import '../../core/errors.dart';
import '../models/models.dart';

/// Keranjang per pengguna. userId 0 dipakai untuk tamu.
class CartRepository {
  CartRepository(this._db);
  final Database _db;

  Future<List<CartLine>> lines(int userId) async {
    final rows = await _db.rawQuery('''
      SELECT c.id AS cart_id, c.quantity, c.added_at, p.*, u.name AS seller_name
      FROM cart_items c
      JOIN products p ON p.id = c.product_id
      JOIN users u ON u.id = p.seller_id
      WHERE c.user_id = ? ORDER BY c.added_at''', [userId]);
    return rows
        .map((r) => CartLine(
              item: CartItem(
                id: r['cart_id'] as int,
                productId: r['id'] as int,
                quantity: r['quantity'] as int,
                addedAt: DateTime.fromMillisecondsSinceEpoch(r['added_at'] as int),
              ),
              product: Product.fromMap(r),
            ))
        .toList();
  }

  Future<void> add(int userId, Product product, {int quantity = 1}) async {
    if (!product.isAvailable) throw AppException('${product.name} sedang tidak tersedia.');
    final existing = await _db.query('cart_items',
        where: 'user_id = ? AND product_id = ?', whereArgs: [userId, product.id], limit: 1);
    final current = existing.isEmpty ? 0 : existing.first['quantity'] as int;
    final target = current + quantity;
    if (target > product.stock) {
      throw AppException('Stok ${product.name} hanya ${product.stock} ${product.unit}.');
    }
    if (existing.isEmpty) {
      await _db.insert('cart_items', {
        'user_id': userId,
        'product_id': product.id,
        'quantity': target,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await _db.update('cart_items', {'quantity': target}, where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }

  Future<void> setQuantity(int userId, Product product, int quantity) async {
    if (quantity <= 0) return remove(userId, product.id!);
    if (quantity > product.stock) {
      throw AppException('Stok ${product.name} hanya ${product.stock} ${product.unit}.');
    }
    await _db.update('cart_items', {'quantity': quantity},
        where: 'user_id = ? AND product_id = ?', whereArgs: [userId, product.id]);
  }

  Future<void> remove(int userId, int productId) =>
      _db.delete('cart_items', where: 'user_id = ? AND product_id = ?', whereArgs: [userId, productId]);

  Future<void> clear(int userId) => _db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);

  /// Memindahkan keranjang tamu ke akun yang baru masuk (jumlah digabung, dibatasi stok).
  Future<void> mergeGuestCart(int userId) async {
    await _db.transaction((txn) async {
      final guest = await txn.rawQuery('''
        SELECT c.product_id, c.quantity, p.stock FROM cart_items c
        JOIN products p ON p.id = c.product_id WHERE c.user_id = 0''');
      for (final g in guest) {
        final pid = g['product_id'] as int;
        final stock = g['stock'] as int;
        final mine = await txn.query('cart_items', where: 'user_id = ? AND product_id = ?', whereArgs: [userId, pid]);
        final have = mine.isEmpty ? 0 : mine.first['quantity'] as int;
        final qty = (have + (g['quantity'] as int)).clamp(0, stock).toInt();
        if (qty <= 0) continue;
        if (mine.isEmpty) {
          await txn.insert('cart_items', {
            'user_id': userId,
            'product_id': pid,
            'quantity': qty,
            'added_at': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          await txn.update('cart_items', {'quantity': qty}, where: 'id = ?', whereArgs: [mine.first['id']]);
        }
      }
      await txn.delete('cart_items', where: 'user_id = 0');
    });
  }
}
