import 'package:flutter/foundation.dart';

/// Dasar untuk state yang datanya bergantung pada pengguna aktif
/// (0 = tamu). Data dimuat ulang otomatis saat pemilik berganti.
abstract class OwnerScopedNotifier extends ChangeNotifier {
  int _ownerId = -1;
  bool _disposed = false;

  int get ownerId => _ownerId;

  void setOwner(int id) {
    if (id == _ownerId) return;
    _ownerId = id;
    Future.microtask(reload);
  }

  Future<void> reload();

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
