import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radar_config.dart';

class RadarStorage {
  static const String _key = 'vtuber_radar_configs';
  static const String _lastAutoSearchKey = 'last_auto_search_time';

  static Future<List<RadarConfig>> getRadarConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => RadarConfig.fromJson(json)).toList();
  }

  static Future<void> saveRadarConfig(RadarConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getRadarConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }
    final jsonString = json.encode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> deleteRadarConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getRadarConfigs();
    configs.removeWhere((c) => c.id == id);
    final jsonString = json.encode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<DateTime?> getLastAutoSearchTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastAutoSearchKey);
    if (timeString == null) {
      return null;
    }
    return DateTime.parse(timeString);
  }

  static Future<void> setLastAutoSearchTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAutoSearchKey, time.toIso8601String());
  }
}