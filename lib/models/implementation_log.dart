class ImplementationLog {
  const ImplementationLog({
    required this.id,
    required this.tanggal,
    required this.aktivitas,
    required this.penanggungJawab,
    required this.status,
    required this.versi,
    required this.hasil,
    required this.catatan,
    required this.lokasiDeployment,
    required this.namaSistem,
  });

  final int id;
  final String tanggal;
  final String aktivitas;
  final String penanggungJawab;
  final String status;
  final String versi;
  final String hasil;
  final String catatan;
  final String lokasiDeployment;
  final String namaSistem;

  factory ImplementationLog.fromJson(Map<String, dynamic> json) {
    return ImplementationLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tanggal: (json['tanggal'] ?? '').toString(),
      aktivitas: (json['aktivitas'] ?? '').toString(),
      penanggungJawab: (json['penanggung_jawab'] ?? '').toString(),
      status: (json['status'] ?? 'proses').toString(),
      versi: (json['versi'] ?? 'v1.0').toString(),
      hasil: (json['hasil'] ?? 'berhasil').toString(),
      catatan: (json['catatan'] ?? '').toString(),
      lokasiDeployment: (json['lokasi_deployment'] ?? '').toString(),
      namaSistem: (json['nama_sistem'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tanggal': tanggal,
    'aktivitas': aktivitas,
    'penanggung_jawab': penanggungJawab,
    'status': status,
    'versi': versi,
    'hasil': hasil,
    'catatan': catatan,
    'lokasi_deployment': lokasiDeployment,
    'nama_sistem': namaSistem,
  };
}
