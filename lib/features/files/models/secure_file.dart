class SecureFile {
  const SecureFile({
    required this.id,
    required this.userId,
    required this.originalName,
    required this.storedName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.status,
    required this.downloadCount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String originalName;
  final String storedName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String status;
  final int downloadCount;
  final DateTime createdAt;

  factory SecureFile.fromMap(Map<String, dynamic> map) {
    return SecureFile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      originalName: map['original_name'] as String,
      storedName: map['stored_name'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      fileSize: (map['file_size'] as num).toInt(),
      status: map['status'] as String? ?? 'private',
      downloadCount: (map['download_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
