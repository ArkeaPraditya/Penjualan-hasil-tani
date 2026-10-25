import 'package:flutter/foundation.dart';

enum ShellTab { home, categories, cart, orders, profile }

class ShellTabProvider extends ChangeNotifier {
  ShellTab _tab = ShellTab.home;
  ShellTab get tab => _tab;

  void go(ShellTab t) {
    if (t == _tab) return;
    _tab = t;
    notifyListeners();
  }
}
