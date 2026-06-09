import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_store.dart';
import '../models/search_result.dart';

class DataStoreService {
  static const String _key = 'vtuber_radar_data_store';

  static Future<DataStore> getDataStore(String radarId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return DataStore(radarId: radarId, items: []);
    }
    final Map<String, dynamic> data = json.decode(jsonString);
    if (data.containsKey(radarId)) {
      return DataStore.fromJson(data[radarId]);
    }
    return DataStore(radarId: radarId, items: []);
  }

  static Future<void> saveDataStore(DataStore store) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    Map<String, dynamic> allStores = jsonString != null ? json.decode(jsonString) : {};
    allStores[store.radarId] = store.toJson();
    await prefs.setString(_key, json.encode(allStores));
  }

  static Future<List<ClipItem>> findNewItems(String radarId, List<ClipItem> searchResults) async {
    final store = await getDataStore(radarId);
    final existingClipIds = store.items.map((item) => item.clipId).toSet();
    return searchResults.where((item) => !existingClipIds.contains(item.id)).toList();
  }

  static Future<void> addItemsToStore(String radarId, List<ClipItem> items) async {
    final store = await getDataStore(radarId);
    for (var item in items) {
      final existingItem = store.items.firstWhere(
        (stored) => stored.clipId == item.id,
        orElse: () => DataStoreItem(clipId: '', radarId: '', title: '', author: '', orgName: '', datetime: '', subtitles: [], storedAt: DateTime.now()),
      );
      if (existingItem.clipId.isEmpty) {
        store.items.add(DataStoreItem.fromClipItem(item, radarId));
      }
    }
    await saveDataStore(store);
  }

  static Future<int> getStoredItemCount(String radarId) async {
    final store = await getDataStore(radarId);
    return store.items.length;
  }

  static Future<void> clearDataStore(String radarId) async {
    final store = DataStore(radarId: radarId, items: []);
    await saveDataStore(store);
  }

  static Future<void> clearAllDataStores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<String> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    
    int totalBytes = 0;
    if (jsonString != null) {
      totalBytes += jsonString.length * 2;
    }
    
    final cacheDir = await getTemporaryDirectory();
    if (await cacheDir.exists()) {
      List<FileSystemEntity> files = cacheDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.png')) {
          totalBytes += await file.length();
        }
      }
    }
    
    if (totalBytes < 1024) {
      return '${totalBytes} B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
  }
}
