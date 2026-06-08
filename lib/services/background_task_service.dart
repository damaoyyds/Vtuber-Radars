import 'package:workmanager/workmanager.dart';
import './radar_storage.dart';
import './search_api.dart';
import './data_store_service.dart';
import './message_storage.dart';
import '../models/radar_config.dart';
import '../models/message.dart';
import '../models/search_result.dart';
import 'package:uuid/uuid.dart';

const autoSearchTask = "vtuber_radar_auto_search_task";

class BackgroundTaskService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  static Future<void> scheduleAutoSearch(int hour, int minute) async {
    await Workmanager().cancelByUniqueName(autoSearchTask);
    
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    Duration delay = scheduledTime.difference(now);
    
    await Workmanager().registerOneOffTask(
      autoSearchTask,
      autoSearchTask,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelAutoSearch() async {
    await Workmanager().cancelByUniqueName(autoSearchTask);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case autoSearchTask:
        await _performBackgroundSearch();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _performBackgroundSearch() async {
  try {
    final configs = await RadarStorage.getRadarConfigs();
    
    for (var radar in configs) {
      if (radar.isAutoSearch && radar.isAutoSearchEnabled) {
        final now = DateTime.now();
        
        for (var scheduleTime in radar.scheduleTimes) {
          final todayScheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );
          
          final lastAutoSearchTime = await RadarStorage.getLastAutoSearchTime(radar.id, scheduleTime);
          
          bool alreadyRanToday = false;
          if (lastAutoSearchTime != null) {
            alreadyRanToday = lastAutoSearchTime.year == now.year &&
                lastAutoSearchTime.month == now.month &&
                lastAutoSearchTime.day == now.day;
          }
          
          bool shouldRun = !alreadyRanToday && 
              now.isAfter(todayScheduledTime) &&
              now.difference(todayScheduledTime).inMinutes >= 1;
          
          if (shouldRun) {
            await _executeSearch(radar);
            await RadarStorage.setLastAutoSearchTime(radar.id, scheduleTime, now);
          }
        }
      }
    }
  } catch (e) {
    print('Background search error: $e');
  }
}

Future<void> _executeSearch(RadarConfig radar) async {
  DateTime now = DateTime.now();
  DateTime effectiveStartDate;
  DateTime effectiveEndDate;

  switch (radar.timeRangeType) {
    case TimeRangeType.lastDay:
      effectiveStartDate = now.subtract(const Duration(days: 1));
      effectiveEndDate = now;
      break;
    case TimeRangeType.lastThreeDays:
      effectiveStartDate = now.subtract(const Duration(days: 3));
      effectiveEndDate = now;
      break;
    case TimeRangeType.lastSevenDays:
      effectiveStartDate = now.subtract(const Duration(days: 7));
      effectiveEndDate = now;
      break;
    case TimeRangeType.lastMonth:
      effectiveStartDate = now.subtract(const Duration(days: 30));
      effectiveEndDate = now;
      break;
    default:
      effectiveStartDate = radar.startDate ?? now.subtract(const Duration(days: 30));
      effectiveEndDate = radar.endDate ?? now;
  }

  String? startDateStr = effectiveStartDate.toIso8601String().split('T')[0];
  String? endDateStr = effectiveEndDate.toIso8601String().split('T')[0];

  List<ClipItem> allNewItems = [];
  Map<String, List<ClipItem>> itemsByKeyword = {};

  for (String keyword in radar.keywords) {
    SearchResult result = await SearchApi.fetchSearchResults(
      keyword,
      radar.selectedOrgIds,
      startDate: startDateStr,
      endDate: endDateStr,
    );

    List<ClipItem> newItems = await DataStoreService.findNewItems(radar.id, result.items);
    await DataStoreService.addItemsToStore(radar.id, newItems);
    
    allNewItems.addAll(newItems);
    itemsByKeyword[keyword] = newItems;
  }

  List<Message> newMessages = [];
  if (allNewItems.isEmpty) {
    newMessages.add(Message(
      id: const Uuid().v4(),
      radarName: radar.name,
      timestamp: DateTime.now(),
      type: MessageType.searchComplete,
      text: '搜索完成，没有新数据',
    ));
  } else {
    Set<String> authorNames = allNewItems.map((item) => item.author.name).toSet();
    String authorsText = authorNames.join('、');
    String firstKeyword = radar.keywords.isNotEmpty ? radar.keywords.first : '';
    
    newMessages.add(Message(
      id: const Uuid().v4(),
      radarName: radar.name,
      timestamp: DateTime.now(),
      type: MessageType.searchComplete,
      text: '$authorsText 提到了 $firstKeyword',
    ));
    
    for (var entry in itemsByKeyword.entries) {
      String keyword = entry.key;
      List<ClipItem> items = entry.value;
      
      for (var item in items) {
        newMessages.add(Message(
          id: const Uuid().v4(),
          radarName: radar.name,
          timestamp: DateTime.now(),
          type: MessageType.searchComplete,
          clipItem: item,
          keyword: keyword,
        ));
      }
    }
  }

  List<Message> existingMessages = await MessageStorage.loadMessages();
  existingMessages.insertAll(0, newMessages);
  await MessageStorage.saveMessages(existingMessages);
}