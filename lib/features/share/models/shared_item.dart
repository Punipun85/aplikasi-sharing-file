class SharedItem {
  const SharedItem({
    required this.shareLinkId,
    required this.token,
    required this.accessType,
    required this.fileName,
    required this.fileType,
    required this.ownerEmail,
    required this.canView,
    required this.canDownload,
    required this.createdAt,
    this.expiredAt,
  });

  final String shareLinkId;
  final String token;
  final String accessType;
  final String fileName;
  final String fileType;
  final String ownerEmail;
  final bool canView;
  final bool canDownload;
  final DateTime createdAt;
  final DateTime? expiredAt;

  factory SharedItem.fromRecipientMap(Map<String, dynamic> map) {
    final link = map['share_links'] as Map<String, dynamic>? ?? {};
    final file = link['files'] as Map<String, dynamic>? ?? {};
    final profile = file['profiles'] as Map<String, dynamic>? ?? {};
    return SharedItem(
      shareLinkId: link['id'] as String? ?? map['share_link_id'] as String,
      token: link['token'] as String? ?? '',
      accessType: link['access_type'] as String? ?? 'specific_user',
      fileName: file['original_name'] as String? ?? 'Shared file',
      fileType: file['file_type'] as String? ?? '-',
      ownerEmail: profile['email'] as String? ?? '-',
      canView: map['can_view'] as bool? ?? link['can_view'] as bool? ?? true,
      canDownload:
          map['can_download'] as bool? ?? link['can_download'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiredAt: link['expired_at'] == null
          ? null
          : DateTime.parse(link['expired_at'] as String),
    );
  }

  factory SharedItem.fromLinkMap(Map<String, dynamic> map) {
    final file = map['files'] as Map<String, dynamic>? ?? {};
    final profile = file['profiles'] as Map<String, dynamic>? ?? {};
    return SharedItem(
      shareLinkId: map['id'] as String,
      token: map['token'] as String? ?? '',
      accessType: map['access_type'] as String? ?? 'public',
      fileName: file['original_name'] as String? ?? 'Shared file',
      fileType: file['file_type'] as String? ?? '-',
      ownerEmail: profile['email'] as String? ?? '-',
      canView: map['can_view'] as bool? ?? true,
      canDownload: map['can_download'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiredAt: map['expired_at'] == null
          ? null
          : DateTime.parse(map['expired_at'] as String),
    );
  }
}
