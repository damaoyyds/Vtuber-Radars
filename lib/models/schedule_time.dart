class ScheduleTime {
  final int hour;
  final int minute;

  ScheduleTime({
    required this.hour,
    required this.minute,
  });

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  factory ScheduleTime.fromJson(Map<String, dynamic> json) {
    return ScheduleTime(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleTime &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}