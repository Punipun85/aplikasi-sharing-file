import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';
import '../models/activity_log.dart';

class ActivityService {
  SupabaseClient get _client => Supabase.instance.client;

  Stream<List<ActivityLog>> watchForUser(String userId) {
    if (!SupabaseConfig.isConfigured) {
      return Stream.value(demoLogs);
    }
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map<ActivityLog>(ActivityLog.fromMap).toList());
  }

  Future<List<ActivityLog>> listForUser(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      return demoLogs;
    }
    final rows = await _client
        .from('activity_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map<ActivityLog>((row) => ActivityLog.fromMap(row)).toList();
  }

  Future<List<ActivityLog>> listAll() async {
    if (!SupabaseConfig.isConfigured) {
      return demoLogs;
    }
    final rows = await _client
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false);
    return rows.map<ActivityLog>((row) => ActivityLog.fromMap(row)).toList();
  }
}

final demoLogs = [
  ActivityLog(
    id: '1',
    fileId: 'f1',
    action: 'upload_file',
    status: 'success',
    platform: 'web',
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
  ),
  ActivityLog(
    id: '2',
    fileId: 'f2',
    action: 'create_share_link',
    status: 'success',
    platform: 'android',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ActivityLog(
    id: '3',
    fileId: 'f3',
    action: 'wrong_password',
    status: 'failed',
    platform: 'web',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
