import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_constants.dart';
import '../../../config/supabase_config.dart';
import '../models/secure_file.dart';

class FileService {
  SupabaseClient get _client => Supabase.instance.client;

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

  Future<void> upload(String userId, PlatformFile file) async {
    final extension = (file.extension ?? '').toLowerCase();
    if (!AppConstants.allowedExtensions.contains(extension)) {
      throw Exception('Tipe file .$extension tidak didukung.');
    }
    if (file.size > AppConstants.maxUploadBytes) {
      throw Exception('Ukuran file maksimal 50 MB.');
    }
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('File tidak dapat dibaca di platform ini.');
    }

    final storedName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = '$userId/$storedName';
    await _client.storage
        .from(AppConstants.storageBucket)
        .uploadBinary(path, bytes);
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
        })
        .select('id')
        .single();
    await _client.from('activity_logs').insert({
      'user_id': userId,
      'file_id': inserted['id'],
      'action': 'upload_file',
      'status': 'success',
      'platform': 'web',
    });
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
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];
