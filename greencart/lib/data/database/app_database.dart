import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../seed/seed_data.dart';

/// Pembungkus database SQLite lokal: skema, versi migrasi, dan reset data demo.
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  static const schemaVersion = 1;

  /// [path] opsional; gunakan [inMemoryDatabasePath] untuk pengujian.
  static Future<AppDatabase> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'greencart.db');
    final db = await openDatabase(
      dbPath,
      version: schemaVersion,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await _createSchema(d);
        await SeedData.insert(d);
      },
      onUpgrade: (d, oldV, newV) async {
        // Tambahkan migrasi bertahap di sini saat schemaVersion naik.
      },
    );
    return AppDatabase._(db);
  }

  /// Menghapus seluruh data lalu mengisi ulang data demo.
  Future<void> resetDemoData() async {
    await db.transaction((txn) async {
      for (final t in _tablesInDropOrder) {
        await txn.execute('DROP TABLE IF EXISTS $t');
      }
      await _createSchema(txn);
      await SeedData.insert(txn);
    });
  }

  Future<void> close() => db.close();

  static const _tablesInDropOrder = [
    'notifications',
    'order_status_events',
    'order_items',
    'orders',
    'addresses',
    'cart_items',
    'products',
    'categories',
    'users',
  ];

  static Future<void> _createSchema(DatabaseExecutor d) async {
    await d.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email_or_phone TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('buyer','seller')),
        created_at INTEGER NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL REFERENCES categories(id),
        description TEXT NOT NULL,
        price INTEGER NOT NULL CHECK(price > 0),
        unit TEXT NOT NULL,
        stock INTEGER NOT NULL CHECK(stock >= 0),
        image_asset_path TEXT NOT NULL,
        seller_id INTEGER NOT NULL REFERENCES users(id),
        origin TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 1
      )''');
    await d.execute('''
      CREATE TABLE cart_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        added_at INTEGER NOT NULL,
        UNIQUE(user_id, product_id)
      )''');
    await d.execute('''
      CREATE TABLE addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        recipient_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address_line TEXT NOT NULL,
        area_note TEXT NOT NULL DEFAULT '',
        is_default INTEGER NOT NULL DEFAULT 0
      )''');
    await d.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL UNIQUE,
        user_id INTEGER NOT NULL REFERENCES users(id),
        recipient_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address_line TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        subtotal INTEGER NOT NULL,
        delivery_fee INTEGER NOT NULL,
        total INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        product_id INTEGER NOT NULL,
        seller_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0)
      )''');
    await d.execute('''
      CREATE TABLE order_status_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        status TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL
      )''');
    await d.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        order_id INTEGER,
        created_at INTEGER NOT NULL
      )''');
    await d.execute('CREATE INDEX idx_orders_user ON orders(user_id)');
    await d.execute('CREATE INDEX idx_items_order ON order_items(order_id)');
    await d.execute('CREATE INDEX idx_items_seller ON order_items(seller_id)');
    await d.execute('CREATE INDEX idx_notif_user ON notifications(user_id)');
  }
}
