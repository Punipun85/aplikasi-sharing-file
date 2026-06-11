import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/services/activity_service.dart';
import '../../files/models/secure_file.dart';
import '../../files/services/file_service.dart';
import '../models/admin_user.dart';

class AdminService {
  SupabaseClient get _client => Supabase.instance.client;

  Stream<List<AdminUser>> watchUsers() {
    if (!SupabaseConfig.isConfigured) {
      return Stream.value(demoUsers);
    }
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map<AdminUser>(AdminUser.fromMap).toList());
  }

  Stream<List<SecureFile>> watchFiles() async* {
    if (!SupabaseConfig.isConfigured) {
      yield demoFiles;
      return;
    }
    yield await _listFileAudits();
    await for (final _ in Stream.periodic(const Duration(seconds: 8))) {
      yield await _listFileAudits();
    }
  }

  Stream<List<ActivityLog>> watchLogs() {
    if (!SupabaseConfig.isConfigured) {
      return Stream.value(demoLogs);
    }
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map<ActivityLog>(ActivityLog.fromMap).toList());
  }

  Future<void> updateUserStatus(String userId, String status) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    await _client.from('profiles').update({'status': status}).eq('id', userId);
  }

  Future<void> deleteFile(String fileId) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    await _client.rpc(
      'admin_mark_file_deleted',
      params: {'target_file_id': fileId},
    );
  }

  Future<List<SecureFile>> _listFileAudits() async {
    final rows = await _client.rpc('admin_list_file_audits');
    return (rows as List)
        .map<SecureFile>(
          (row) => SecureFile.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}

final demoUsers = [
  AdminUser(
    id: 'demo-user',
    name: 'Demo User',
    email: 'demo@secureshare.dev',
    role: 'user',
    status: 'active',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  AdminUser(
    id: 'demo-admin',
    name: 'Admin SecureShare',
    email: 'admin@secureshare.dev',
    role: 'admin',
    status: 'active',
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
];
