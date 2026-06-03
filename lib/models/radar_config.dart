class RadarConfig {
  final String id;
  final String name;
  final String keyword;
  final List<String> selectedOrgIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  RadarConfig({
    required this.id,
    required this.name,
    required this.keyword,
    required this.selectedOrgIds,
    this.startDate,
    this.endDate,
    required this.createdAt,
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
    );
  }
}