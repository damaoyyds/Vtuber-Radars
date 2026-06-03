import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vtuber_radar_f/models/organization.dart';
import 'package:vtuber_radar_f/models/search_result.dart';

class SearchApi {
  static Future<SearchResult> fetchSearchResults(
    String keyword,
    List<String> orgIds, {
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
  }) async {
    if (orgIds.isEmpty) {
      throw Exception('请至少选择一个组织');
    }

    DateTime today = DateTime.now();
    if (endDate == null || endDate.isEmpty) {
      endDate = today.toIso8601String().split('T')[0];
    }
    if (startDate == null || startDate.isEmpty) {
      startDate = today.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
    }

    List<ClipItem> results = [];

    for (String orgId in orgIds) {
      Organization? orgInfo = organizations[orgId];
      if (orgInfo == null) continue;

      String url = "https://api.zimu.live:7443/organizations/$orgId/clips";

      Map<String, String> params = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'author_ids': orgInfo.authorIds,
        'keyword': keyword,
        'start_date': startDate,
        'end_date': endDate,
      };

      Map<String, String> headers = {
        'Accept': 'application/json, text/plain, */*',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36',
      };

      try {
        Uri uri = Uri.parse(url);
        uri = uri.replace(queryParameters: params);
        
        http.Response response = await http.get(uri, headers: headers);
        
        if (response.statusCode != 200) {
          throw Exception('HTTP request failed with status ${response.statusCode}');
        }

        Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data.containsKey('data') && data['data'].containsKey('items')) {
          List<dynamic> items = data['data']['items'];
          
          for (dynamic item in items) {
            Map<String, dynamic> itemMap = item as Map<String, dynamic>;
            itemMap['org_name'] = orgInfo.name;
            itemMap['org_id'] = orgId;
            itemMap['bilibili_url'] = _parseBilibiliUrl(itemMap['play_url']?.toString());
            
            String clipId = itemMap['id']?.toString() ?? '';
            List<Subtitle> subtitles = await _findMatchingSubtitles(clipId, keyword);
            itemMap['subtitles'] = subtitles.map((s) => s.toJson()).toList();
            
            results.add(ClipItem.fromJson(itemMap));
          }
        }
      } catch (e) {
        throw Exception('请求失败: $e');
      }
    }

    results.sort((a, b) => b.datetime.compareTo(a.datetime));

    return SearchResult(
      items: results,
      pagination: Pagination(
        page: page,
        totalPages: 1,
        total: results.length,
      ),
    );
  }

  static String? _parseBilibiliUrl(String? playUrl) {
    if (playUrl == null || playUrl.isEmpty) return null;

    if (!playUrl.startsWith('http')) {
      playUrl = 'http://$playUrl';
    }

    Uri parsed = Uri.parse(playUrl);
    String? bvid = parsed.queryParameters['bvid'];
    String? p = parsed.queryParameters['p'];

    if (bvid != null) {
      if (p != null && _isNumeric(p)) {
        String strippedP = p.replaceFirst(RegExp(r'^0+'), '');
        if (strippedP.isEmpty) strippedP = '1';
        return 'https://www.bilibili.com/video/$bvid/?p=$strippedP';
      } else {
        return 'https://www.bilibili.com/video/$bvid/';
      }
    }

    return null;
  }

  static bool _isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  static Future<List<Subtitle>> _findMatchingSubtitles(String clipId, String keyword) async {
    List<Subtitle> matches = [];
    
    try {
      String url = "https://api.zimu.live:7443/clips/$clipId/subtitles";
      
      Map<String, String> params = {'keyword': keyword};
      Map<String, String> headers = {
        'Accept': 'application/json, text/plain, */*',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36',
      };

      Uri uri = Uri.parse(url);
      uri = uri.replace(queryParameters: params);
      
      http.Response response = await http.get(uri, headers: headers);
      
      if (response.statusCode != 200) {
        return matches;
      }

      Map<String, dynamic> data = jsonDecode(response.body);
      
      if (data.containsKey('data') && data['data'].containsKey('subtitles')) {
        List<dynamic> subtitles = data['data']['subtitles'];
        
        for (dynamic subtitle in subtitles) {
          Map<String, dynamic> subMap = subtitle as Map<String, dynamic>;
          String markedContent = subMap['marked_content'] as String;
          int start = subMap['start'] as int;
          int end = subMap['end'] as int;

          RegExp pinyinRegex = RegExp(r'<pinyin>(.*?)</pinyin>');
          RegExp textRegex = RegExp(r'<text>(.*?)</text>');

          Match? pinyinMatch = pinyinRegex.firstMatch(markedContent);
          Match? textMatch = textRegex.firstMatch(markedContent);

          if (pinyinMatch != null || textMatch != null) {
            String cleanContent = markedContent;
            String pinyin = '';
            String text = '';

            if (pinyinMatch != null) {
              pinyin = pinyinMatch.group(1) ?? '';
              cleanContent = cleanContent.replaceAll(RegExp(r'<pinyin>.*?</pinyin>'), pinyin);
            }
            if (textMatch != null) {
              text = textMatch.group(1) ?? '';
              cleanContent = cleanContent.replaceAll(RegExp(r'<text>.*?</text>'), text);
            }

            matches.add(Subtitle(
              clipId: clipId,
              start: start,
              end: end,
              markedContent: markedContent,
              cleanContent: cleanContent,
              pinyin: pinyin,
              text: text,
            ));
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return matches;
  }
}
