import 'package:sqflite/sqflite.dart';

import '../../core/errors.dart';
import '../../core/utils/order_status.dart';
import '../../core/utils/pricing.dart';
import '../models/models.dart';

class OrderRepository {
  OrderRepository(this._db, {this.policy = defaultDeliveryPolicy});
  final Database _db;
  final DeliveryPolicy policy;

  static const paymentCod = 'Bayar di Tempat (COD)';
  static const paymentTransfer = 'Transfer Bank (Simulasi)';

  static const _statusMessages = {
    OrderStatus.pending: 'Pesanan berhasil dibuat dan menunggu konfirmasi penjual.',
    OrderStatus.processing: 'Pesanan mulai diproses oleh penjual.',
    OrderStatus.packed: 'Pesanan sedang dikemas.',
    OrderStatus.shipped: 'Pesanan sedang dikirim ke alamat Anda.',
    OrderStatus.completed: 'Pesanan selesai. Terima kasih sudah berbelanja!',
    OrderStatus.cancelled: 'Pesanan dibatalkan.',
  };

  static const _statusTitles = {
    OrderStatus.pending: 'Pesanan berhasil dibuat',
    OrderStatus.processing: 'Pesanan diproses',
    OrderStatus.packed: 'Pesanan dikemas',
    OrderStatus.shipped: 'Pesanan dikirim',
    OrderStatus.completed: 'Pesanan selesai',
    OrderStatus.cancelled: 'Pesanan dibatalkan',
  };

  /// Membuat pesanan dari isi keranjang dalam SATU transaksi database:
  /// stok diperiksa ulang, harga dibaca dari database (bukan dari UI),
  /// stok dikurangi, keranjang dikosongkan, riwayat & notifikasi dicatat.
  Future<Order> createOrder({
    required int userId,
    required String recipientName,
    required String phone,
    required String addressLine,
    required String note,
    required String paymentMethod,
  }) async {
    final orderId = await _db.transaction<int>((txn) async {
      final rows = await txn.rawQuery('''
        SELECT c.quantity AS qty, p.* FROM cart_items c
        JOIN products p ON p.id = c.product_id
        WHERE c.user_id = ? ORDER BY c.added_at''', [userId]);
      if (rows.isEmpty) throw AppException('Keranjang masih kosong.');

      var subtotal = 0;
      for (final r in rows) {
        final qty = r['qty'] as int;
        final stock = r['stock'] as int;
        final name = r['name'] as String;
        if ((r['is_active'] as int) != 1) throw AppException('$name sudah tidak dijual. Hapus dari keranjang.');
        if (qty > stock) {
          throw AppException(stock == 0
              ? '$name sudah habis. Hapus dari keranjang.'
              : 'Stok $name berubah, tersisa $stock ${r['unit']}. Ubah jumlahnya.');
        }
        subtotal += (r['price'] as int) * qty;
      }
      final fee = policy.feeFor(subtotal);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final seq = (Sqflite.firstIntValue(
                  await txn.rawQuery('SELECT COUNT(*) FROM orders WHERE created_at >= ?', [start])) ??
              0) +
          1;
      final id = await txn.insert('orders', {
        'order_number': buildOrderNumber(now, seq),
        'user_id': userId,
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'address_line': addressLine.trim(),
        'note': note.trim(),
        'subtotal': subtotal,
        'delivery_fee': fee,
        'total': subtotal + fee,
        'payment_method': paymentMethod,
        'status': OrderStatus.pending.dbValue,
        'created_at': now.millisecondsSinceEpoch,
      });
      for (final r in rows) {
        await txn.insert('order_items', {
          'order_id': id,
          'product_id': r['id'],
          'seller_id': r['seller_id'],
          'name': r['name'],
          'unit': r['unit'],
          'price': r['price'],
          'quantity': r['qty'],
        });
        await txn.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [r['qty'], r['id']]);
      }
      await _addEvent(txn, id, userId, OrderStatus.pending, notifyBuyer: true);
      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      return id;
    });
    return (await getOrder(orderId))!;
  }

  Future<void> _addEvent(DatabaseExecutor txn, int orderId, int buyerId, OrderStatus status,
      {bool notifyBuyer = true}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await txn.insert('order_status_events', {
      'order_id': orderId,
      'status': status.dbValue,
      'note': _statusMessages[status]!,
      'timestamp': now,
    });
    if (notifyBuyer) {
      await txn.insert('notifications', {
        'user_id': buyerId,
        'title': _statusTitles[status]!,
        'message': _statusMessages[status]!,
        'is_read': 0,
        'order_id': orderId,
        'created_at': now,
      });
    }
  }

  /// Mengubah status mengikuti aturan transisi. Pembatalan mengembalikan stok.
  Future<void> updateStatus(int orderId, OrderStatus to, {required bool bySeller}) async {
    await _db.transaction((txn) async {
      final rows = await txn.query('orders', where: 'id = ?', whereArgs: [orderId], limit: 1);
      if (rows.isEmpty) throw AppException('Pesanan tidak ditemukan.');
      final from = OrderStatus.fromDb(rows.first['status'] as String);
      if (!OrderStatusRules.isValidTransition(from, to, bySeller: bySeller)) {
        throw AppException(to == OrderStatus.cancelled
            ? 'Pesanan dengan status "${from.label}" tidak dapat dibatalkan.'
            : 'Status tidak dapat diubah dari "${from.label}" ke "${to.label}".');
      }
      await txn.update('orders', {'status': to.dbValue}, where: 'id = ?', whereArgs: [orderId]);
      if (to == OrderStatus.cancelled) {
        final items = await txn.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
        for (final i in items) {
          await txn.rawUpdate('UPDATE products SET stock = stock + ? WHERE id = ?', [i['quantity'], i['product_id']]);
        }
      }
      await _addEvent(txn, orderId, rows.first['user_id'] as int, to);
    });
  }

  Future<Order?> getOrder(int id) async {
    final rows = await _db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _hydrate(rows.first);
  }

  Future<List<Order>> ordersForUser(int userId) async {
    final rows = await _db.query('orders', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC, id DESC');
    return Future.wait(rows.map(_hydrate));
  }

  Future<List<Order>> ordersForSeller(int sellerId) async {
    final rows = await _db.rawQuery('''
      SELECT * FROM orders WHERE id IN (SELECT order_id FROM order_items WHERE seller_id = ?)
      ORDER BY created_at DESC, id DESC''', [sellerId]);
    return Future.wait(rows.map(_hydrate));
  }

  Future<Order> _hydrate(Map<String, Object?> r) async {
    final id = r['id'] as int;
    final items = await _db.query('order_items', where: 'order_id = ?', whereArgs: [id], orderBy: 'id');
    final events = await _db.query('order_status_events', where: 'order_id = ?', whereArgs: [id], orderBy: 'id');
    return Order(
      id: id,
      orderNumber: r['order_number'] as String,
      userId: r['user_id'] as int,
      recipientName: r['recipient_name'] as String,
      phone: r['phone'] as String,
      addressLine: r['address_line'] as String,
      note: r['note'] as String,
      items: items.map(OrderItem.fromMap).toList(),
      subtotal: r['subtotal'] as int,
      deliveryFee: r['delivery_fee'] as int,
      total: r['total'] as int,
      paymentMethod: r['payment_method'] as String,
      status: OrderStatus.fromDb(r['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      events: events
          .map((e) => OrderStatusEvent(
                status: OrderStatus.fromDb(e['status'] as String),
                note: e['note'] as String,
                timestamp: DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int),
              ))
          .toList(),
    );
  }
}
