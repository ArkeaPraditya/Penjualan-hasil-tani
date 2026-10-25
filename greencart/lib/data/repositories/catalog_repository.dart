import 'package:sqflite/sqflite.dart';

import '../../core/errors.dart';
import '../models/models.dart';

class CatalogRepository {
  CatalogRepository(this._db);
  final Database _db;

  static const _select = '''
    SELECT p.*, u.name AS seller_name FROM products p
    JOIN users u ON u.id = p.seller_id''';

  Future<List<Category>> categories() async {
    final rows = await _db.query('categories', orderBy: 'sort_order');
    return rows.map(Category.fromMap).toList();
  }

  /// Produk aktif untuk pembeli.
  Future<List<Product>> activeProducts() async {
    final rows = await _db.rawQuery('$_select WHERE p.is_active = 1 ORDER BY p.id');
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> productsBySeller(int sellerId) async {
    final rows = await _db.rawQuery('$_select WHERE p.seller_id = ? ORDER BY p.id DESC', [sellerId]);
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProduct(int id) async {
    final rows = await _db.rawQuery('$_select WHERE p.id = ?', [id]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  void _validate(Product p) {
    if (p.name.trim().length < 3) throw AppException('Nama produk minimal 3 karakter.');
    if (p.price <= 0) throw AppException('Harga harus lebih dari 0.');
    if (p.stock < 0) throw AppException('Stok tidak boleh negatif.');
    if (p.unit.trim().isEmpty) throw AppException('Satuan wajib diisi.');
  }

  Future<int> saveProduct(Product p) async {
    _validate(p);
    if (p.id == null) return _db.insert('products', p.toMap());
    await _db.update('products', p.toMap(), where: 'id = ? AND seller_id = ?', whereArgs: [p.id, p.sellerId]);
    return p.id!;
  }

  Future<void> setActive(int productId, bool active) =>
      _db.update('products', {'is_active': active ? 1 : 0}, where: 'id = ?', whereArgs: [productId]);

  Future<void> deleteProduct(int productId) => _db.delete('products', where: 'id = ?', whereArgs: [productId]);
}
