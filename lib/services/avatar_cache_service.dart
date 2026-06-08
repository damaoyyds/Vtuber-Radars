import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class AvatarCacheService {
  static final AvatarCacheService _instance = AvatarCacheService._internal();
  factory AvatarCacheService() => _instance;
  AvatarCacheService._internal();

  Map<String, Uint8List> _memoryCache = {};
  late Directory _cacheDir;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _cacheDir = await getTemporaryDirectory();
    _initialized = true;
  }

  Future<Uint8List?> getAvatar(String authorId, String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    await init();

    String cacheKey = _generateCacheKey(authorId, avatarUrl);

    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    Uint8List? fileCache = await _readFromFileCache(cacheKey);
    if (fileCache != null) {
      _memoryCache[cacheKey] = fileCache;
      return fileCache;
    }

    Uint8List? networkData = await _fetchFromNetwork(avatarUrl);
    if (networkData != null) {
      _memoryCache[cacheKey] = networkData;
      await _saveToFileCache(cacheKey, networkData);
      return networkData;
    }

    return null;
  }

  String _generateCacheKey(String authorId, String avatarUrl) {
    return '${authorId}_${Uri.encodeComponent(avatarUrl)}';
  }

  Future<Uint8List?> _readFromFileCache(String cacheKey) async {
    try {
      File cacheFile = File('${_cacheDir.path}/avatar_${_hashKey(cacheKey)}.png');
      if (await cacheFile.exists()) {
        return await cacheFile.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading avatar from file cache: $e');
    }
    return null;
  }

  Future<void> _saveToFileCache(String cacheKey, Uint8List data) async {
    try {
      File cacheFile = File('${_cacheDir.path}/avatar_${_hashKey(cacheKey)}.png');
      await cacheFile.writeAsBytes(data);
    } catch (e) {
      debugPrint('Error saving avatar to file cache: $e');
    }
  }

  Future<Uint8List?> _fetchFromNetwork(String url) async {
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error fetching avatar from network: $e');
    }
    return null;
  }

  String _hashKey(String key) {
    return key.hashCode.toString();
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }

  Future<void> clearAllCache() async {
    _memoryCache.clear();
    try {
      await init();
      List<FileSystemEntity> files = _cacheDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.png')) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing avatar cache: $e');
    }
  }
}
