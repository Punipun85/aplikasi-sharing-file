import 'package:flutter/foundation.dart';

import '../models/share_link.dart';
import '../models/shared_item.dart';
import '../services/share_service.dart';

class ShareProvider extends ChangeNotifier {
  final ShareService _service = ShareService();

  bool isLoading = false;
  String? error;
  List<ShareLink> links = [];
  List<SharedItem> createdLinks = [];
  List<SharedItem> mailbox = [];
  ShareLink? latest;

  Future<void> loadForFile(String fileId) async {
    links = await _service.listForFile(fileId);
    notifyListeners();
  }

  Future<bool> create({
    required String fileId,
    required String createdBy,
    required String accessType,
    String? password,
    DateTime? expiredAt,
    bool canView = true,
    bool canDownload = true,
    List<String> recipientEmails = const [],
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      latest = await _service.create(
        fileId: fileId,
        createdBy: createdBy,
        accessType: accessType,
        password: password,
        expiredAt: expiredAt,
        canView: canView,
        canDownload: canDownload,
        recipientEmails: recipientEmails,
      );
      await loadForFile(fileId);
      return true;
    } catch (e) {
      error = _friendlyShareError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCreatedBy(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      createdLinks = await _service.listCreatedBy(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMailbox({
    required String userId,
    required String email,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      mailbox = await _service.listMailbox(userId: userId, email: email);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyShareError(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('violates foreign key') ||
        lower.contains('foreign key constraint')) {
      return 'File belum tersimpan valid di Supabase. Upload ulang file dari akun ini, lalu buat share link lagi.';
    }
    if (lower.contains('row-level security') || lower.contains('rls')) {
      return 'Akses database ditolak oleh RLS. Pastikan file ini milik akun login dan policy share_links/share_recipients sudah dijalankan.';
    }
    if (lower.contains('infinite recursion') || lower.contains('42p17')) {
      return 'Policy share link di Supabase masih versi lama dan menyebabkan recursion. Jalankan ulang supabase_schema.sql terbaru di SQL Editor Supabase, lalu coba generate link lagi.';
    }
    if (lower.contains('can_view') || lower.contains('can_download')) {
      return 'Kolom izin share belum ada di Supabase. Jalankan ulang schema SQL terbaru, lalu coba lagi.';
    }
    return message;
  }
}
