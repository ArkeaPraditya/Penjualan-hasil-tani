import 'package:flutter/foundation.dart';

import '../../core/utils/product_filter.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repo);
  final CatalogRepository _repo;

  List<Category> categories = const [];
  List<Product> products = const [];
  bool loading = true;
  String? error;

  String query = '';
  int? categoryId;
  bool onlyAvailable = false;
  SortOrder sort = SortOrder.none;

  Future<void> reload() async {
    try {
      categories = await _repo.categories();
      products = await _repo.activeProducts();
      error = null;
    } catch (_) {
      error = 'Gagal memuat produk. Coba lagi.';
    }
    loading = false;
    notifyListeners();
  }

  List<Product> get filtered => filterProducts(
        products,
        query: query,
        categoryId: categoryId,
        onlyAvailable: onlyAvailable,
        sort: sort,
      );

  bool get hasActiveFilter => query.isNotEmpty || categoryId != null || onlyAvailable || sort != SortOrder.none;

  Product? byId(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setCategory(int? id) {
    categoryId = id;
    notifyListeners();
  }

  void setOnlyAvailable(bool v) {
    onlyAvailable = v;
    notifyListeners();
  }

  void setSort(SortOrder s) {
    sort = s;
    notifyListeners();
  }

  void clearFilters() {
    query = '';
    categoryId = null;
    onlyAvailable = false;
    sort = SortOrder.none;
    notifyListeners();
  }
}
