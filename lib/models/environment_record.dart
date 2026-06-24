class EnvironmentRecord {
  const EnvironmentRecord({
    required this.id,
    required this.projectId,
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.responseTime,
    this.uptime = '',
  });

  final int id;
  final String projectId;
  final DateTime timestamp;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final int responseTime;
  final String uptime;

  factory EnvironmentRecord.fromJson(Map<String, dynamic> json) {
    return EnvironmentRecord(
      id: _toInt(json['id']),
      projectId: (json['project_id'] ?? '').toString(),
      timestamp: _toDateTime(json['timestamp']) ?? DateTime.now(),
      cpuUsage: _toDouble(json['cpu_usage']) ?? 0,
      memoryUsage: _toDouble(json['memory_usage']) ?? 0,
      diskUsage: _toDouble(json['disk_usage']) ?? 0,
      responseTime: _toInt(json['response_time']),
      uptime: (json['uptime'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse('$value') ?? 0;
  }

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
