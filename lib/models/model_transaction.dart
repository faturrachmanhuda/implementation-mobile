class ModelTransaction {
  const ModelTransaction({
    required this.id,
    required this.projectId,
    required this.modelId,
    required this.idTransaksi,
    required this.idSistem,
    required this.tipeDataInput,
    required this.prediksiModel,
    required this.labelOutput,
    this.probabilitasSkor,
    required this.groundTruth,
    required this.sumberData,
    this.waktuInferensiMs,
    required this.konteksPermintaan,
    this.timestampTransaksi,
    required this.timestamp,
  });

  final int id;
  final String projectId;
  final String modelId;
  final String idTransaksi;
  final String idSistem;
  final String tipeDataInput;
  final String prediksiModel;
  final String labelOutput;
  final double? probabilitasSkor;
  final String groundTruth;
  final String sumberData;
  final int? waktuInferensiMs;
  final String konteksPermintaan;
  final DateTime? timestampTransaksi;
  final DateTime timestamp;

  factory ModelTransaction.fromJson(Map<String, dynamic> json) {
    return ModelTransaction(
      id: _toInt(json['id']),
      projectId: (json['project_id'] ?? '').toString(),
      modelId: (json['model_id'] ?? '').toString(),
      idTransaksi: (json['id_transaksi'] ?? '').toString(),
      idSistem: (json['id_sistem'] ?? '').toString(),
      tipeDataInput: (json['tipe_data_input'] ?? '').toString(),
      prediksiModel: (json['prediksi_model'] ?? '').toString(),
      labelOutput: (json['label_output'] ?? '').toString(),
      probabilitasSkor: _toDouble(json['probabilitas_skor']),
      groundTruth: (json['ground_truth'] ?? '').toString(),
      sumberData: (json['sumber_data'] ?? '').toString(),
      waktuInferensiMs: _toIntOrNull(json['waktu_inferensi_ms']),
      konteksPermintaan: (json['konteks_permintaan'] ?? '').toString(),
      timestampTransaksi: _toDateTime(json['timestamp_transaksi']),
      timestamp: _toDateTime(json['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_id': modelId,
      'id_transaksi': idTransaksi,
      'id_sistem': idSistem,
      'tipe_data_input': tipeDataInput,
      'prediksi_model': prediksiModel,
      'label_output': labelOutput,
      'probabilitas_skor': probabilitasSkor,
      'ground_truth': groundTruth,
      'sumber_data': sumberData,
      'waktu_inferensi_ms': waktuInferensiMs,
      'konteks_permintaan': konteksPermintaan,
      if (timestampTransaksi != null)
        'timestamp_transaksi': timestampTransaksi!.toIso8601String(),
    };
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

  static int? _toIntOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
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
}
