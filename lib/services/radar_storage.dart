import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radar_config.dart';
import '../models/schedule_time.dart';

class RadarStorage {
  static const String _key = 'vtuber_radar_configs';
  static const String _lastAutoSearchKeyPrefix = 'last_auto_search_time_';

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

  static String _getAutoSearchKey(String radarId, ScheduleTime scheduleTime) {
    return '${_lastAutoSearchKeyPrefix}${radarId}_${scheduleTime.hour}_${scheduleTime.minute}';
  }

  static Future<DateTime?> getLastAutoSearchTime(String radarId, ScheduleTime scheduleTime) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getAutoSearchKey(radarId, scheduleTime);
    final timeString = prefs.getString(key);
    if (timeString == null) {
      return null;
    }
    return DateTime.parse(timeString);
  }

  static Future<void> setLastAutoSearchTime(String radarId, ScheduleTime scheduleTime, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getAutoSearchKey(radarId, scheduleTime);
    await prefs.setString(key, time.toIso8601String());
  }
}