import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool isBootstrapping = true;
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? profile;

  bool get isAuthenticated =>
      _service.isConfigured ? _service.currentUser != null : profile != null;
  bool get isAdmin => profile?['role'] == 'admin';
  String? get profileEmail => profile?['email'] as String?;
  String? get userId => _service.currentUser?.id ?? profile?['id'] as String?;

  Future<void> bootstrap() async {
    isBootstrapping = true;
    notifyListeners();
    try {
      if (_service.isConfigured && _service.currentSession != null) {
        profile = await _service.fetchProfile() ?? _fallbackProfile();
      }
    } catch (_) {
      profile = _fallbackProfile();
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      if (_service.isConfigured) {
        await _service.login(email, password);
        profile = await _service.fetchProfile() ?? _fallbackProfile();
        final fallback = profile;
        if (fallback != null) {
          await _service.upsertProfile(
            userId: fallback['id'] as String,
            name: fallback['name'] as String? ?? email.split('@').first,
            email: fallback['email'] as String? ?? email,
          );
          profile = await _service.fetchProfile() ?? fallback;
        }
      } else {
        profile = {
          'id': 'demo-user',
          'name': email.contains('admin') ? 'Admin SecureShare' : 'Demo User',
          'email': email,
          'role': email.contains('admin') ? 'admin' : 'user',
          'status': 'active',
        };
      }
    });
  }

  Future<bool> register(String name, String email, String password) async {
    return _run(() async {
      if (_service.isConfigured) {
        await _service.register(name, email, password);
        await _service.logout();
        profile = null;
      } else {
        profile = null;
      }
    });
  }

  Future<void> logout() async {
    await _service.logout();
    profile = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    return _run(() async {
      final id = userId;
      if (id == null) {
        throw Exception('User belum login.');
      }
      if (_service.isConfigured) {
        final updated = await _service.updateProfile(
          userId: id,
          name: name,
          email: email,
        );
        profile =
            updated ??
            {
              ...?profile,
              'id': id,
              'name': name,
              'email': email,
              'role': profile?['role'] ?? 'user',
              'status': profile?['status'] ?? 'active',
            };
      } else {
        profile = {
          ...?profile,
          'id': id,
          'name': name,
          'email': email,
          'role': profile?['role'] ?? 'user',
          'status': profile?['status'] ?? 'active',
        };
      }
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      error = _friendlyAuthError(e.message);
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau password salah. Jika baru register, cek email konfirmasi Supabase dulu, lalu coba login lagi.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Buka email dari Supabase, klik link konfirmasi, lalu login kembali.';
    }
    if (lower.contains('email rate exceeded') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('rate limit')) {
      return 'Supabase membatasi pengiriman email karena terlalu sering register. Tunggu beberapa menit, pakai email baru, atau matikan sementara Confirm email di Supabase Auth.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already registered')) {
      return 'Email ini sudah terdaftar. Silakan langsung login.';
    }
    return message;
  }

  Map<String, dynamic>? _fallbackProfile() {
    final user = _service.currentUser;
    if (user == null) {
      return null;
    }
    final email = user.email ?? '';
    return {
      'id': user.id,
      'name': user.userMetadata?['name'] ?? email.split('@').first,
      'email': email,
      'role': 'user',
      'status': 'active',
    };
  }
}
