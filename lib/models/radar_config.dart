class RadarConfig {
  final String id;
  final String name;
  final String keyword;
  final List<String> selectedOrgIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final bool isAutoSearch;
  final int autoSearchHour;
  final int autoSearchMinute;
  final bool isAutoSearchEnabled;

  RadarConfig({
    required this.id,
    required this.name,
    required this.keyword,
    required this.selectedOrgIds,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.isAutoSearch = false,
    this.autoSearchHour = 9,
    this.autoSearchMinute = 0,
    this.isAutoSearchEnabled = false,
  });

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
      'autoSearchHour': autoSearchHour,
      'autoSearchMinute': autoSearchMinute,
      'isAutoSearchEnabled': isAutoSearchEnabled,
    };
  }

  factory RadarConfig.fromJson(Map<String, dynamic> json) {
    return RadarConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      keyword: json['keyword'] as String,
      selectedOrgIds: List<String>.from(json['selectedOrgIds'] as List),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAutoSearch: json['isAutoSearch'] as bool? ?? false,
      autoSearchHour: json['autoSearchHour'] as int? ?? 9,
      autoSearchMinute: json['autoSearchMinute'] as int? ?? 0,
      isAutoSearchEnabled: json['isAutoSearchEnabled'] as bool? ?? false,
    );
  }

  RadarConfig copyWith({
    bool? isAutoSearchEnabled,
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
      autoSearchHour: autoSearchHour,
      autoSearchMinute: autoSearchMinute,
      isAutoSearchEnabled: isAutoSearchEnabled ?? this.isAutoSearchEnabled,
    );
  }
}