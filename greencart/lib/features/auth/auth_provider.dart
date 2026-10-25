import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._cart);
  final AuthRepository _auth;
  final CartRepository _cart;

  static const _kUser = 'session_user_id';
  static const _kGuest = 'session_guest';

  AppUser? _user;
  bool _guest = false;
  bool _ready = false;

  AppUser? get user => _user;
  bool get isGuest => _guest && _user == null;
  bool get isLoggedIn => _user != null;
  bool get hasSession => _user != null || _guest;
  bool get ready => _ready;

  /// Pemilik data keranjang/pesanan. 0 = tamu.
  int get ownerId => _user?.id ?? 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kUser);
    if (id != null) _user = await _auth.getById(id);
    _guest = _user == null && (prefs.getBool(_kGuest) ?? false);
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setInt(_kUser, _user!.id);
      await prefs.remove(_kGuest);
    } else {
      await prefs.remove(_kUser);
      await prefs.setBool(_kGuest, _guest);
    }
  }

  Future<void> login(String emailOrPhone, String password) async {
    _user = await _auth.login(emailOrPhone, password);
    _guest = false;
    await _cart.mergeGuestCart(_user!.id);
    await _persist();
    notifyListeners();
  }

  Future<void> register(String name, String emailOrPhone, String password, {bool asSeller = false}) async {
    _user = await _auth.register(
      name: name,
      emailOrPhone: emailOrPhone,
      password: password,
      role: asSeller ? UserRole.seller : UserRole.buyer,
    );
    _guest = false;
    await _cart.mergeGuestCart(_user!.id);
    await _persist();
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    _guest = true;
    _user = null;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _guest = false;
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile(String name, String emailOrPhone) async {
    _user = await _auth.updateProfile(_user!.id, name: name, emailOrPhone: emailOrPhone);
    notifyListeners();
  }

  /// Dipanggil setelah data demo direset: sesi lama tidak lagi valid.
  Future<void> handleDataReset() => logout();
}
