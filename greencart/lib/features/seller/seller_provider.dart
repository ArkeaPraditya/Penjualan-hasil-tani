import '../../core/errors.dart';
import '../../core/state/owner_scoped_notifier.dart';
import '../../core/utils/order_status.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../products/catalog_provider.dart';
import '../notifications/notifications_provider.dart';
import '../orders/orders_provider.dart';

/// State dashboard penjual. Mode ini berbagi database dengan sisi pembeli di
/// perangkat yang sama (tanpa sinkronisasi antarperangkat).
class SellerProvider extends OwnerScopedNotifier {
  SellerProvider(this._catalogRepo, this._orderRepo, this._catalog, this._orders, this._notifications);
  final CatalogRepository _catalogRepo;
  final OrderRepository _orderRepo;
  final CatalogProvider _catalog;
  final OrdersProvider _orders;
  final NotificationsProvider _notifications;

  List<Product> products = const [];
  List<Order> incoming = const [];

  int get activeOrderCount => incoming.where((o) => o.status.isActive).length;
  int get lowStockCount => products.where((p) => p.isActive && p.stock <= 5).length;

  @override
  Future<void> reload() async {
    if (ownerId == 0) {
      products = const [];
      incoming = const [];
    } else {
      products = await _catalogRepo.productsBySeller(ownerId);
      incoming = await _orderRepo.ordersForSeller(ownerId);
    }
    safeNotify();
  }

  Future<void> _afterChange() async {
    await reload();
    await _catalog.reload();
    await _orders.reload();
    await _notifications.reload();
  }

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      await _afterChange();
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Data gagal disimpan. Coba lagi.';
    }
  }

  Future<String?> saveProduct(Product p) => _run(() => _catalogRepo.saveProduct(p));
  Future<String?> setActive(Product p, bool active) => _run(() => _catalogRepo.setActive(p.id!, active));
  Future<String?> deleteProduct(Product p) => _run(() => _catalogRepo.deleteProduct(p.id!));
  Future<String?> advance(Order o, OrderStatus to) => _run(() => _orderRepo.updateStatus(o.id, to, bySeller: true));
}
