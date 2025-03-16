import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car.dart';

class PreferencesService {
  static const String _favoritesCarsKey = 'favorite_cars';
  static const String _recentViewedCarsKey = 'recent_viewed_cars';
  static const String _userSettingsKey = 'user_settings';
  static const String _lastFiltersKey = 'last_filters';

  // Favori arabaları kaydetme
  Future<void> saveFavoriteCars(List<Car> cars) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonCars = cars.map((car) => jsonEncode(car.toMap())).toList();
    await prefs.setStringList(_favoritesCarsKey, jsonCars);
  }

  // Favori arabaları getirme
  Future<List<Car>> getFavoriteCars() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonCars = prefs.getStringList(_favoritesCarsKey);
    if (jsonCars == null) return [];

    return jsonCars.map((jsonCar) => Car.fromMap(jsonDecode(jsonCar))).toList();
  }

  // Son bakılan arabaları kaydetme
  Future<void> saveRecentViewedCars(List<Car> cars) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonCars = cars.map((car) => jsonEncode(car.toMap())).toList();
    await prefs.setStringList(_recentViewedCarsKey, jsonCars);
  }

  // Son bakılan arabaları getirme
  Future<List<Car>> getRecentViewedCars() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonCars = prefs.getStringList(_recentViewedCarsKey);
    if (jsonCars == null) return [];

    return jsonCars.map((jsonCar) => Car.fromMap(jsonDecode(jsonCar))).toList();
  }

  // Kullanıcı ayarlarını kaydetme
  Future<bool> saveUserSettings(Map<String, dynamic> settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_userSettingsKey, jsonEncode(settings));
  }

  // Kullanıcı ayarlarını getirme
  Future<Map<String, dynamic>> getUserSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_userSettingsKey);

    if (settingsJson == null || settingsJson.isEmpty) {
      return {};
    }

    return jsonDecode(settingsJson);
  }

  // Son kullanılan filtreleri kaydetme
  Future<void> saveLastFilters(Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFiltersKey, jsonEncode(filters));
  }

  // Son kullanılan filtreleri getirme
  Future<Map<String, dynamic>> getLastFilters() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonFilters = prefs.getString(_lastFiltersKey);
    if (jsonFilters == null) return {};

    try {
      return jsonDecode(jsonFilters);
    } catch (e) {
      return {};
    }
  }

  // Verileri temizleme
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Son görüntülenen arabaları temizle
  Future<void> clearRecentViewedCars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentViewedCarsKey);
  }

  // Filtreleme için eklenen metotlar
  Future<void> clearLastFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastFiltersKey);
  }
}
