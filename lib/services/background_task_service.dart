import 'package:workmanager/workmanager.dart';
import './radar_storage.dart';
import './search_api.dart';
import './data_store_service.dart';
import './message_storage.dart';
import './notification_service.dart';
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

  static Future<void> scheduleAutoSearch() async {
    await Workmanager().cancelByUniqueName(autoSearchTask);
    
    DateTime nextRunTime = await _calculateNextRunTime();
    Duration delay = nextRunTime.difference(DateTime.now());
    
    if (delay.isNegative) {
      delay = Duration.zero;
    }
    
    await Workmanager().registerOneOffTask(
      autoSearchTask,
      autoSearchTask,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresDeviceIdle: false,
        requiresCharging: false,
      ),
    );
  }
  
  static Future<DateTime> _calculateNextRunTime() async {
    final configs = await RadarStorage.getRadarConfigs();
    DateTime now = DateTime.now();
    DateTime nextRunTime = now.add(const Duration(days: 1));
    
    for (var radar in configs) {
      if (radar.isAutoSearch && radar.isAutoSearchEnabled) {
        for (var scheduleTime in radar.scheduleTimes) {
          DateTime scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            scheduleTime.hour,
            scheduleTime.minute,
          ).subtract(const Duration(minutes: 1));
          
          if (scheduledTime.isAfter(now)) {
            if (scheduledTime.isBefore(nextRunTime)) {
              nextRunTime = scheduledTime;
            }
          } else {
            DateTime tomorrowScheduledTime = scheduledTime.add(const Duration(days: 1));
            if (tomorrowScheduledTime.isBefore(nextRunTime)) {
              nextRunTime = tomorrowScheduledTime;
            }
          }
        }
      }
    }
    
    return nextRunTime;
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
        await NotificationService().initialize();
        await _performBackgroundSearch();
        await BackgroundTaskService.scheduleAutoSearch();
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
          DateTime todayScheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            scheduleTime.hour,
            scheduleTime.minute,
          );
          
          final lastAutoSearchTime = await RadarStorage.getLastAutoSearchTime(radar.id, scheduleTime);
          
          bool hasRunToday = false;
          if (lastAutoSearchTime != null) {
            hasRunToday = lastAutoSearchTime.year == now.year &&
                lastAutoSearchTime.month == now.month &&
                lastAutoSearchTime.day == now.day;
          }
          
          DateTime timeToCheck = todayScheduledTime.subtract(const Duration(minutes: 1));
          bool isAfterSearchTime = now.isAfter(timeToCheck) || 
              now.isAtSameMomentAs(timeToCheck);
          
          bool shouldRun = isAfterSearchTime && !hasRunToday;
          
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
          avatarUrl: item.author.avatar,
          authorId: item.author.name,
        ));
      }
    }
  }

  List<Message> existingMessages = await MessageStorage.loadMessages();
  existingMessages.insertAll(0, newMessages);
  await MessageStorage.saveMessages(existingMessages);
  
  if (allNewItems.isNotEmpty) {
    await NotificationService().showNotification(
      'Vtuber Radar',
      '${radar.name} 搜索到 ${allNewItems.length} 条新数据',
    );
  }
}