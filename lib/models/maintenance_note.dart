class MaintenanceNoteAttachment {
  const MaintenanceNoteAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.isImage,
  });

  final int id;
  final String name;
  final String url;
  final bool isImage;

  factory MaintenanceNoteAttachment.fromJson(Map<String, dynamic> json) {
    return MaintenanceNoteAttachment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? 'Lampiran').toString(),
      url: (json['url'] ?? '').toString(),
      isImage: (json['is_image'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'is_image': isImage,
  };
}

class MaintenanceNote {
  const MaintenanceNote({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.staff,
    required this.status,
    required this.createdAt,
    required this.createdAtIso,
    required this.attachmentCount,
    required this.attachments,
    this.fungsi = const [],
  });

  final int id;
  final String judul;
  final String deskripsi;
  final String staff;
  final String status;
  final String createdAt;
  final String createdAtIso;
  final int attachmentCount;
  final List<MaintenanceNoteAttachment> attachments;
  final List<String> fungsi;

  factory MaintenanceNote.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments
              .whereType<Map>()
              .map(
                (a) => MaintenanceNoteAttachment.fromJson(
                  a.cast<String, dynamic>(),
                ),
              )
              .toList()
        : <MaintenanceNoteAttachment>[];

    final rawFungsi = json['fungsi'];
    final fungsi = rawFungsi is List
        ? rawFungsi.map((e) => e.toString()).toList()
        : <String>[];

    return MaintenanceNote(
      id: (json['id'] as num?)?.toInt() ?? 0,
      judul: (json['judul'] ?? '').toString(),
      deskripsi: (json['deskripsi'] ?? '').toString(),
      staff: (json['staff'] ?? '').toString(),
      status: (json['status'] ?? 'scheduled').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdAtIso: (json['created_at_iso'] ?? '').toString(),
      attachmentCount: (json['attachment_count'] as num?)?.toInt() ?? 0,
      attachments: attachments,
      fungsi: fungsi,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'judul': judul,
    'deskripsi': deskripsi,
    'staff': staff,
    'status': status,
    'created_at': createdAt,
    'created_at_iso': createdAtIso,
    'attachment_count': attachmentCount,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'fungsi': fungsi,
  };
}
