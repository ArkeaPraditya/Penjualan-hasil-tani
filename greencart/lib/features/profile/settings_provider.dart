import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const areas = ['Tembalang', 'Banyumanik', 'Gunungpati', 'Ngaliyan', 'Semarang Tengah', 'Genuk'];
  static const _kArea = 'service_area';

  String _area = areas.first;
  String get serviceArea => _area;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _area = prefs.getString(_kArea) ?? areas.first;
    notifyListeners();
  }

  Future<void> setArea(String area) async {
    _area = area;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kArea, area);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _area = areas.first;
    notifyListeners();
  }
}
