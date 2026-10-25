import '../../data/models/models.dart';

enum SortOrder { none, priceAsc, priceDesc }

List<Product> filterProducts(
  List<Product> all, {
  String query = '',
  int? categoryId,
  bool onlyAvailable = false,
  SortOrder sort = SortOrder.none,
}) {
  final q = query.trim().toLowerCase();
  final result = all.where((p) {
    if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
    if (categoryId != null && p.categoryId != categoryId) return false;
    if (onlyAvailable && !p.isAvailable) return false;
    return true;
  }).toList();
  switch (sort) {
    case SortOrder.priceAsc:
      result.sort((a, b) => a.price.compareTo(b.price));
    case SortOrder.priceDesc:
      result.sort((a, b) => b.price.compareTo(a.price));
    case SortOrder.none:
      break;
  }
  return result;
}
