class Project {
  const Project({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.description,
    this.updatedAt = '',
    this.refinedAt = '',
    this.refinedBy = '',
    this.refinementStatus = '',
  });

  final String id;
  final String createdAt;
  final String name;
  final String description;
  final String updatedAt;
  final String refinedAt;
  final String refinedBy;
  final String refinementStatus;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '-').toString(),
      name: (json['nama'] ?? json['name'] ?? json['project_name'] ?? '-')
          .toString(),
      description: (json['deskripsi'] ?? json['description'] ?? '')
          .toString()
          .trim(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
      refinedAt:
          (json['refined_at'] ??
                  json['refinedAt'] ??
                  json['last_refined_at'] ??
                  json['refinement_at'] ??
                  '')
              .toString(),
      refinedBy:
          (json['refined_by'] ??
                  json['refinedBy'] ??
                  json['division'] ??
                  json['source_division'] ??
                  '')
              .toString(),
      refinementStatus:
          (json['refinement_status'] ??
                  json['refinementStatus'] ??
                  json['refining_status'] ??
                  json['refiningStatus'] ??
                  '')
              .toString(),
    );
  }

  String get refinementMarker {
    final explicitMarker = refinedAt.trim().isNotEmpty
        ? refinedAt.trim()
        : updatedAt.trim();
    if (explicitMarker.isNotEmpty) {
      return explicitMarker;
    }
    return refinementStatus.trim();
  }

  bool get hasRefinementNotification {
    final marker = refinementMarker;
    if (marker.isEmpty) {
      return false;
    }

    final source = '$refinedBy $refinementStatus'.toLowerCase();
    return source.isEmpty ||
        source.contains('intelligence') ||
        source.contains('intelegence') ||
        source.contains('creation') ||
        source.contains('refin');
  }

  String get notificationFingerprint {
    if (!hasRefinementNotification) {
      return '';
    }
    return '$id|$refinementMarker|$refinedBy|$refinementStatus';
  }

  String get notificationMessage {
    final source = refinedBy.trim().isEmpty
        ? 'Divisi Intelligence Creation'
        : refinedBy.trim();
    return '$source melakukan refining project. Ada data baru yang masuk ke endpoint untuk project ini.';
  }

  Map<String, String> toRouteData() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'description': description.isEmpty ? 'Tidak ada deskripsi' : description,
      'notificationFingerprint': notificationFingerprint,
      'notificationMessage': notificationMessage,
    };
  }
}
