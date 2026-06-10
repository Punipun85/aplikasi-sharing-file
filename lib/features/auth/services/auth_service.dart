import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';

class AuthService {
  bool get isConfigured => SupabaseConfig.isConfigured;
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession =>
      isConfigured ? _client?.auth.currentSession : null;
  User? get currentUser => isConfigured ? _client?.auth.currentUser : null;

  Future<Map<String, dynamic>?> fetchProfile() async {
    final client = _client;
    if (!isConfigured || client == null || currentUser == null) {
      return null;
    }
    try {
      return client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final client = _client;
    if (!isConfigured || client == null) {
      return;
    }
    await client.auth.signInWithPassword(email: email, password: password);
    try {
      await client.from('activity_logs').insert({
        'user_id': currentUser?.id,
        'action': 'login',
        'status': 'success',
        'platform': 'web',
      });
    } catch (_) {
      // Auth should not fail just because optional logging tables are not ready.
    }
  }

  Future<void> register(String name, String email, String password) async {
    final client = _client;
    if (!isConfigured || client == null) {
      return;
    }
    final response = await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _emailRedirectTo,
      data: {'name': name},
    );
    final user = response.user;
    final session = response.session;
    if (session != null && user != null) {
      await upsertProfile(
        userId: user.id,
        name: name,
        email: user.email ?? email,
      );
    }
  }

  String? get _emailRedirectTo {
    if (!kIsWeb || Uri.base.scheme != 'http' && Uri.base.scheme != 'https') {
      return null;
    }
    final port = Uri.base.hasPort ? ':${Uri.base.port}' : '';
    return '${Uri.base.scheme}://${Uri.base.host}$port/login';
  }

  Future<void> upsertProfile({
    required String userId,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final client = _client;
    if (!isConfigured || client == null) {
      return;
    }
    final payload = {
      'id': userId,
      'name': name,
      'email': email,
      'role': 'user',
      'status': 'active',
    };
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }
    await client.from('profiles').upsert(payload);
  }

  Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final client = _client;
    if (!isConfigured || client == null) {
      return null;
    }
    final payload = {
      'name': name,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }
    return client
        .from('profiles')
        .update(payload)
        .eq('id', userId)
        .select()
        .maybeSingle();
  }

  Future<String> uploadAvatar({
    required String userId,
    required PlatformFile file,
  }) async {
    final client = _client;
    if (!isConfigured || client == null) {
      throw Exception('Supabase belum dikonfigurasi.');
    }
    final extension = (file.extension ?? '').toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(extension)) {
      throw Exception('Foto profil harus JPG, PNG, atau WEBP.');
    }
    if (file.size > 5 * 1024 * 1024) {
      throw Exception('Ukuran foto profil maksimal 5 MB.');
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Foto tidak dapat dibaca di platform ini.');
    }

    final safeName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$userId/$safeName';
    await client.storage.from('profile-avatars').uploadBinary(path, bytes);
    return client.storage.from('profile-avatars').getPublicUrl(path);
  }

  Future<void> logout() async {
    final client = _client;
    if (!isConfigured || client == null) {
      return;
    }
    await client.auth.signOut();
  }
}
