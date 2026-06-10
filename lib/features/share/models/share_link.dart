class ShareLink {
  const ShareLink({
    required this.id,
    required this.fileId,
    required this.token,
    required this.accessType,
    this.expiredAt,
    required this.isActive,
    required this.canView,
    required this.canDownload,
    required this.createdAt,
  });

  final String id;
  final String fileId;
  final String token;
  final String accessType;
  final DateTime? expiredAt;
  final bool isActive;
  final bool canView;
  final bool canDownload;
  final DateTime createdAt;

  factory ShareLink.fromMap(Map<String, dynamic> map) {
    return ShareLink(
      id: map['id'] as String,
      fileId: map['file_id'] as String,
      token: map['token'] as String,
      accessType: map['access_type'] as String,
      expiredAt: map['expired_at'] == null
          ? null
          : DateTime.parse(map['expired_at'] as String),
      isActive: map['is_active'] as bool? ?? true,
      canView: map['can_view'] as bool? ?? true,
      canDownload: map['can_download'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
