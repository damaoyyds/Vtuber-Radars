import './schedule_time.dart';

enum TimeRangeType {
  custom,
  lastDay,
  lastThreeDays,
  lastSevenDays,
  lastMonth,
}

class RadarConfig {
  final String id;
  final String name;
  final String keyword;
  final List<String> selectedOrgIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final bool isAutoSearch;
  final List<ScheduleTime> scheduleTimes;
  final bool isAutoSearchEnabled;
  final String? avatarPath;
  final TimeRangeType timeRangeType;

  RadarConfig({
    required this.id,
    required this.name,
    required this.keyword,
    required this.selectedOrgIds,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.isAutoSearch = false,
    List<ScheduleTime>? scheduleTimes,
    this.isAutoSearchEnabled = false,
    this.avatarPath,
    this.timeRangeType = TimeRangeType.custom,
  }) : scheduleTimes = scheduleTimes ?? [ScheduleTime(hour: 9, minute: 0)];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keyword': keyword,
      'selectedOrgIds': selectedOrgIds,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isAutoSearch': isAutoSearch,
      'scheduleTimes': scheduleTimes.map((time) => time.toJson()).toList(),
      'isAutoSearchEnabled': isAutoSearchEnabled,
      'avatarPath': avatarPath,
      'timeRangeType': timeRangeType.index,
    };
  }

  factory RadarConfig.fromJson(Map<String, dynamic> json) {
    List<ScheduleTime> times;
    if (json.containsKey('scheduleTimes') && json['scheduleTimes'] != null) {
      times = (json['scheduleTimes'] as List)
          .map((item) => ScheduleTime.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      int hour = json['autoSearchHour'] as int? ?? 9;
      int minute = json['autoSearchMinute'] as int? ?? 0;
      times = [ScheduleTime(hour: hour, minute: minute)];
    }

    int timeRangeIndex = json['timeRangeType'] as int? ?? 0;
    TimeRangeType timeRangeType = TimeRangeType.values[timeRangeIndex];

    return RadarConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      keyword: json['keyword'] as String,
      selectedOrgIds: List<String>.from(json['selectedOrgIds'] as List),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAutoSearch: json['isAutoSearch'] as bool? ?? false,
      scheduleTimes: times,
      isAutoSearchEnabled: json['isAutoSearchEnabled'] as bool? ?? false,
      avatarPath: json['avatarPath'] as String?,
      timeRangeType: timeRangeType,
    );
  }

  RadarConfig copyWith({
    bool? isAutoSearchEnabled,
    List<ScheduleTime>? scheduleTimes,
    String? avatarPath,
    TimeRangeType? timeRangeType,
  }) {
    return RadarConfig(
      id: id,
      name: name,
      keyword: keyword,
      selectedOrgIds: selectedOrgIds,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      isAutoSearch: isAutoSearch,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      isAutoSearchEnabled: isAutoSearchEnabled ?? this.isAutoSearchEnabled,
      avatarPath: avatarPath ?? this.avatarPath,
      timeRangeType: timeRangeType ?? this.timeRangeType,
    );
  }
}