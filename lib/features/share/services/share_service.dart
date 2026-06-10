import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';
import '../models/share_link.dart';
import '../models/shared_item.dart';

class ShareService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<ShareLink> create({
    required String fileId,
    required String createdBy,
    required String accessType,
    String? password,
    DateTime? expiredAt,
    bool canView = true,
    bool canDownload = true,
    List<String> recipientEmails = const [],
  }) async {
    final token = _token();
    final hash = password == null || password.isEmpty
        ? null
        : sha256.convert(utf8.encode(password)).toString();
    if (!SupabaseConfig.isConfigured) {
      return ShareLink(
        id: 'demo-link',
        fileId: fileId,
        token: token,
        accessType: accessType,
        expiredAt: expiredAt,
        isActive: true,
        canView: canView,
        canDownload: canDownload,
        createdAt: DateTime.now(),
      );
    }
    final row = await _client
        .from('share_links')
        .insert({
          'file_id': fileId,
          'token': token,
          'access_type': accessType,
          'password_hash': hash,
          'expired_at': expiredAt?.toIso8601String(),
          'can_view': canView,
          'can_download': canDownload,
          'created_by': createdBy,
        })
        .select()
        .single();
    if (recipientEmails.isNotEmpty) {
      await _client
          .from('share_recipients')
          .insert(
            recipientEmails
                .map(
                  (email) => {
                    'share_link_id': row['id'],
                    'email': email,
                    'can_view': canView,
                    'can_download': canDownload,
                  },
                )
                .toList(),
          );
    }
    await _client.from('activity_logs').insert({
      'user_id': createdBy,
      'file_id': fileId,
      'action': 'create_share_link',
      'status': 'success',
      'platform': 'web',
    });
    return ShareLink.fromMap(row);
  }

  Future<List<SharedItem>> listCreatedBy(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      return demoSharedItems;
    }
    final rows = await _client
        .from('share_links')
        .select('*, files(original_name,file_type,profiles(email))')
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return rows.map<SharedItem>(SharedItem.fromLinkMap).toList();
  }

  Future<List<SharedItem>> listMailbox({
    required String userId,
    required String email,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return demoSharedItems;
    }
    final rows = await _client
        .from('share_recipients')
        .select(
          '*, share_links(*, files(original_name,file_type,profiles(email)))',
        )
        .or('user_id.eq.$userId,email.eq.$email')
        .order('created_at', ascending: false);
    return rows.map<SharedItem>(SharedItem.fromRecipientMap).toList();
  }

  Future<List<ShareLink>> listForFile(String fileId) async {
    if (!SupabaseConfig.isConfigured) {
      return demoLinks.where((link) => link.fileId == fileId).toList();
    }
    final rows = await _client
        .from('share_links')
        .select()
        .eq('file_id', fileId)
        .order('created_at', ascending: false);
    return rows.map<ShareLink>((row) => ShareLink.fromMap(row)).toList();
  }

  String _token() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(36, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

final demoLinks = [
  ShareLink(
    id: 's1',
    fileId: 'f1',
    token: 'demo-public-link',
    accessType: 'public',
    expiredAt: DateTime.now().add(const Duration(days: 7)),
    isActive: true,
    canView: true,
    canDownload: true,
    createdAt: DateTime.now(),
  ),
];

final demoSharedItems = [
  SharedItem(
    shareLinkId: 's1',
    token: 'demo-public-link',
    accessType: 'public',
    fileName: 'Proposal Kegiatan.pdf',
    fileType: 'pdf',
    ownerEmail: 'demo@secureshare.dev',
    canView: true,
    canDownload: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    expiredAt: DateTime.now().add(const Duration(days: 7)),
  ),
  SharedItem(
    shareLinkId: 's2',
    token: 'demo-view-only',
    accessType: 'specific_user',
    fileName: 'Materi Presentasi.pptx',
    fileType: 'pptx',
    ownerEmail: 'dosen@kampus.ac.id',
    canView: true,
    canDownload: false,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    expiredAt: DateTime.now().add(const Duration(days: 30)),
  ),
];
