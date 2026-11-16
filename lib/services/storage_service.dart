import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';
import '../models/forecast.dart';

/// Persistência local com shared_preferences (pares chave/valor, JSON).
/// Toda operação é protegida: falhas de leitura/escrita nunca derrubam o app.
class StorageService {
  static const _recentKey = 'recent_cities';
  static const _forecastPrefix = 'forecast_cache_';
  static const _maxRecent = 8;

  /// Cidades consultadas, da mais recente para a mais antiga.
  /// O primeiro item é a última cidade consultada.
  Future<List<City>> loadRecentCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentKey);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(City.fromJson).whereType<City>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentCity(City city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await loadRecentCities();
      list.removeWhere((c) => c.id == city.id);
      list.insert(0, city);
      final trimmed = list.take(_maxRecent).map((c) => c.toJson()).toList();
      await prefs.setString(_recentKey, jsonEncode(trimmed));
    } catch (_) {}
  }

  Future<void> clearRecentCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {}
  }

  /// Última previsão obtida com sucesso, por cidade (usada se a rede falhar).
  Future<void> saveForecast(int cityId, Forecast forecast) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_forecastPrefix$cityId', jsonEncode(forecast.toJson()));
    } catch (_) {}
  }

  Future<Forecast?> loadForecast(int cityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_forecastPrefix$cityId');
      if (raw == null) return null;
      return Forecast.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
