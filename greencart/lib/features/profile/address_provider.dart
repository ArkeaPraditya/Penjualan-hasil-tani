import '../../core/errors.dart';
import '../../core/state/owner_scoped_notifier.dart';
import '../../data/models/models.dart';
import '../../data/repositories/address_repository.dart';

class AddressProvider extends OwnerScopedNotifier {
  AddressProvider(this._repo);
  final AddressRepository _repo;

  List<Address> items = const [];

  Address? get defaultAddress {
    for (final a in items) {
      if (a.isDefault) return a;
    }
    return items.isEmpty ? null : items.first;
  }

  @override
  Future<void> reload() async {
    items = ownerId == 0 ? const [] : await _repo.list(ownerId);
    safeNotify();
  }

  Future<String?> save(Address a) async {
    try {
      await _repo.save(a);
      await reload();
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Alamat gagal disimpan.';
    }
  }

  Future<void> delete(Address a) async {
    await _repo.delete(a.id!);
    await reload();
  }
}
