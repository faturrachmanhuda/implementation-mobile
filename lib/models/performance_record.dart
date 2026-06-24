class PerformanceRecord {
  const PerformanceRecord({
    required this.id,
    required this.projectId,
    required this.systemName,
    required this.status,
    required this.createdAt,
    this.evaluatedAt,
    this.accuracy,
    this.precision,
    this.recall,
    this.f1Score,
    this.latencyMs,
    this.throughput,
    this.errorRate,
    this.note = '',
  });

  final int id;
  final String projectId;
  final String systemName;
  final String status;
  final DateTime createdAt;
  final DateTime? evaluatedAt;
  final double? accuracy;
  final double? precision;
  final double? recall;
  final double? f1Score;
  final int? latencyMs;
  final double? throughput;
  final double? errorRate;
  final String note;

  DateTime get timeline => evaluatedAt ?? createdAt;

  factory PerformanceRecord.fromJson(Map<String, dynamic> json) {
    return PerformanceRecord(
      id: _toInt(json['id']),
      projectId: (json['project_id'] ?? '').toString(),
      systemName: (json['nama_sistem'] ?? '').toString(),
      status: (json['status_sistem'] ?? 'baik').toString(),
      createdAt: _toDateTime(json['created_at']) ?? DateTime.now(),
      evaluatedAt: _toDateOnly(json['tanggal_evaluasi']),
      accuracy: _toDouble(json['akurasi']),
      precision: _toDouble(json['presisi']),
      recall: _toDouble(json['recall']),
      f1Score: _toDouble(json['f1_score']),
      latencyMs: _toIntNullable(json['latency_ms']),
      throughput: _toDouble(json['throughput']),
      errorRate: _toDouble(json['error_rate']),
      note: (json['catatan'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  static int? _toIntNullable(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse('$value');
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

  static DateTime? _toDateOnly(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse('${value.toString().trim()}T00:00:00');
  }
}
