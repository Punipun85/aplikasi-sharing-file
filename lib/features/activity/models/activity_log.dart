class ActivityLog {
  const ActivityLog({
    required this.id,
    this.fileId,
    required this.action,
    required this.status,
    required this.platform,
    required this.createdAt,
  });

  final String id;
  final String? fileId;
  final String action;
  final String status;
  final String platform;
  final DateTime createdAt;

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as String,
      fileId: map['file_id'] as String?,
      action: map['action'] as String,
      status: map['status'] as String,
      platform: map['platform'] as String? ?? 'web',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
