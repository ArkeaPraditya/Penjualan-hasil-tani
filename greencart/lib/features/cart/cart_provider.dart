import '../../core/errors.dart';
import '../../core/state/owner_scoped_notifier.dart';
import '../../core/utils/pricing.dart';
import '../../data/models/models.dart';
import '../../data/repositories/cart_repository.dart';

class CartProvider extends OwnerScopedNotifier {
  CartProvider(this._repo, {this.policy = defaultDeliveryPolicy});
  final CartRepository _repo;
  final DeliveryPolicy policy;

  List<CartLine> lines = const [];
  bool loading = true;

  int get itemCount => lines.fold(0, (s, l) => s + l.quantity);
  int get subtotal => lines.fold(0, (s, l) => s + l.subtotal);
  int get deliveryFee => policy.feeFor(subtotal);
  int get total => subtotal + deliveryFee;
  int quantityOf(int productId) {
    for (final l in lines) {
      if (l.item.productId == productId) return l.quantity;
    }
    return 0;
  }

  @override
  Future<void> reload() async {
    lines = await _repo.lines(ownerId);
    loading = false;
    safeNotify();
  }

  /// Mengembalikan pesan kesalahan, atau null bila berhasil.
  Future<String?> add(Product product, {int quantity = 1}) => _run(() => _repo.add(ownerId, product, quantity: quantity));

  Future<String?> setQuantity(Product product, int quantity) => _run(() => _repo.setQuantity(ownerId, product, quantity));

  Future<String?> remove(Product product) => _run(() => _repo.remove(ownerId, product.id!));

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      await reload();
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Data gagal disimpan. Coba lagi.';
    }
  }
}
