import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

import '../../../config/app_constants.dart';
import '../../../config/supabase_config.dart';
import '../../../core/security/file_encryption_service.dart';
import '../models/secure_file.dart';

class FileService {
  SupabaseClient get _client => Supabase.instance.client;
  final _encryption = FileEncryptionService();

  Stream<List<SecureFile>> watchFiles(String userId) {
    if (!SupabaseConfig.isConfigured) {
      return Stream.value(demoFiles);
    }
    return _client
        .from('files')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map<SecureFile>(SecureFile.fromMap)
              .where((file) => file.status != 'deleted')
              .toList(),
        );
  }

  Future<List<SecureFile>> listFiles(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      return demoFiles;
    }
    final rows = await _client
        .from('files')
        .select()
        .eq('user_id', userId)
        .neq('status', 'deleted')
        .order('created_at', ascending: false);
    return rows.map<SecureFile>((row) => SecureFile.fromMap(row)).toList();
  }

  Future<SecureFile?> upload(String userId, PlatformFile file) async {
    final extension = (file.extension ?? '').toLowerCase();
    if (!AppConstants.allowedExtensions.contains(extension)) {
      throw Exception('Tipe file .$extension tidak didukung.');
    }
    if (file.size > AppConstants.maxUploadBytes) {
      throw Exception('Ukuran file maksimal 50 MB.');
    }
    if (!SupabaseConfig.isConfigured) {
      return null;
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('File tidak dapat dibaca di platform ini.');
    }

    final encrypted = await _encryption.encrypt(bytes);
    final storedName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name}.enc';
    final path = '$userId/$storedName';
    await _client.storage
        .from(AppConstants.storageBucket)
        .uploadBinary(path, encrypted.cipherBytes);
    final inserted = await _client
        .from('files')
        .insert({
          'user_id': userId,
          'original_name': file.name,
          'stored_name': storedName,
          'file_path': path,
          'file_type': extension,
          'file_size': file.size,
          'status': 'private',
          'is_encrypted': true,
          'encryption_algorithm': FileEncryptionService.algorithmName,
          'encryption_key': encrypted.keyBase64,
          'encryption_nonce': encrypted.nonceBase64,
          'encryption_mac': encrypted.macBase64,
        })
        .select()
        .single();
    try {
      await _client.from('activity_logs').insert({
        'user_id': userId,
        'file_id': inserted['id'],
        'action': 'upload_file',
        'status': 'success',
        'platform': 'web',
      });
    } catch (_) {
      // Upload visibility should not depend on optional activity logging.
    }
    return SecureFile.fromMap(inserted);
  }

  Future<void> rename(String fileId, String name) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    await _client
        .from('files')
        .update({
          'original_name': name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', fileId);
  }

  Future<void> delete(String fileId) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    await _client
        .from('files')
        .update({
          'status': 'deleted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', fileId);
  }

  Future<FilePreviewData> preview(SecureFile file) async {
    if (!SupabaseConfig.isConfigured) {
      return FilePreviewData(
        fileName: file.originalName,
        fileType: file.fileType,
        bytes: Uint8List.fromList(utf8.encode('Preview demo SecureShare')),
      );
    }
    final signed = await _client.storage
        .from(AppConstants.storageBucket)
        .createSignedUrl(file.filePath, 120);
    final response = await http.get(Uri.parse(signed));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('File gagal diambil dari storage.');
    }

    final plainBytes = file.isEncrypted
        ? await _decryptFile(file, response.bodyBytes)
        : Uint8List.fromList(response.bodyBytes);
    final objectUrl = _objectUrlFor(file, plainBytes);
    return FilePreviewData(
      fileName: file.originalName,
      fileType: file.fileType,
      bytes: plainBytes,
      objectUrl: objectUrl,
    );
  }

  Future<Uint8List> _decryptFile(SecureFile file, List<int> cipherBytes) {
    final key = file.encryptionKey;
    final nonce = file.encryptionNonce;
    final mac = file.encryptionMac;
    if (key == null || nonce == null || mac == null) {
      throw Exception('Metadata enkripsi file tidak lengkap.');
    }
    return _encryption.decrypt(
      cipherBytes: Uint8List.fromList(cipherBytes),
      keyBase64: key,
      nonceBase64: nonce,
      macBase64: mac,
    );
  }

  String _objectUrlFor(SecureFile file, Uint8List bytes) {
    final blob = html.Blob([bytes], _mimeType(file.fileType));
    return html.Url.createObjectUrlFromBlob(blob);
  }

  String _mimeType(String extension) {
    return switch (extension.toLowerCase()) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'txt' => 'text/plain',
      'zip' => 'application/zip',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      _ => 'application/octet-stream',
    };
  }
}

class FilePreviewData {
  const FilePreviewData({
    required this.fileName,
    required this.fileType,
    required this.bytes,
    this.objectUrl,
  });

  final String fileName;
  final String fileType;
  final Uint8List bytes;
  final String? objectUrl;
}

final demoFiles = [
  SecureFile(
    id: 'f1',
    userId: 'demo-user',
    originalName: 'Proposal Kegiatan.pdf',
    storedName: 'proposal.pdf',
    filePath: 'demo/proposal.pdf',
    fileType: 'pdf',
    fileSize: 1240000,
    status: 'shared',
    downloadCount: 12,
    isEncrypted: true,
    encryptionAlgorithm: FileEncryptionService.algorithmName,
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  SecureFile(
    id: 'f2',
    userId: 'demo-user',
    originalName: 'Source Code Final.zip',
    storedName: 'source.zip',
    filePath: 'demo/source.zip',
    fileType: 'zip',
    fileSize: 18240000,
    status: 'private',
    downloadCount: 3,
    isEncrypted: true,
    encryptionAlgorithm: FileEncryptionService.algorithmName,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  SecureFile(
    id: 'f3',
    userId: 'demo-user',
    originalName: 'Materi Presentasi.pptx',
    storedName: 'materi.pptx',
    filePath: 'demo/materi.pptx',
    fileType: 'pptx',
    fileSize: 6500000,
    status: 'shared',
    downloadCount: 28,
    isEncrypted: true,
    encryptionAlgorithm: FileEncryptionService.algorithmName,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];
