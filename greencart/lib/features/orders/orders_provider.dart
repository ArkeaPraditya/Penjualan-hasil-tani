import '../../core/errors.dart';
import '../../core/state/owner_scoped_notifier.dart';
import '../../core/utils/order_status.dart';
import '../../data/models/models.dart';
import '../../data/repositories/order_repository.dart';

class OrdersProvider extends OwnerScopedNotifier {
  OrdersProvider(this._repo);
  final OrderRepository _repo;

  List<Order> orders = const [];
  bool loading = true;
  bool submitting = false;

  List<Order> get active => orders.where((o) => o.status.isActive).toList();
  List<Order> get history => orders.where((o) => !o.status.isActive).toList();

  Order? byId(int id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<void> reload() async {
    orders = ownerId == 0 ? const [] : await _repo.ordersForUser(ownerId);
    loading = false;
    safeNotify();
  }

  /// Mencegah pesanan ganda: panggilan saat [submitting] aktif diabaikan.
  Future<({Order? order, String? error})> checkout({
    required String recipientName,
    required String phone,
    required String addressLine,
    required String note,
    required String paymentMethod,
  }) async {
    if (submitting) return (order: null, error: 'Pesanan sedang diproses...');
    submitting = true;
    safeNotify();
    try {
      final o = await _repo.createOrder(
        userId: ownerId,
        recipientName: recipientName,
        phone: phone,
        addressLine: addressLine,
        note: note,
        paymentMethod: paymentMethod,
      );
      await reload();
      return (order: o, error: null);
    } on AppException catch (e) {
      return (order: null, error: e.message);
    } catch (_) {
      return (order: null, error: 'Pesanan gagal disimpan. Coba lagi.');
    } finally {
      submitting = false;
      safeNotify();
    }
  }

  Future<String?> cancel(Order o) async {
    try {
      await _repo.updateStatus(o.id, OrderStatus.cancelled, bySeller: false);
      await reload();
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Pesanan gagal dibatalkan.';
    }
  }
}
