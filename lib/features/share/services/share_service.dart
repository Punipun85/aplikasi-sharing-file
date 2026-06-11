import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

import '../../../config/supabase_config.dart';
import '../../../core/security/file_encryption_service.dart';
import '../models/share_link.dart';
import '../models/shared_item.dart';

class ShareService {
  SupabaseClient get _client => Supabase.instance.client;
  final _encryption = FileEncryptionService();

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
    final row = await _insertShareLink(
      fileId: fileId,
      token: token,
      accessType: accessType,
      passwordHash: hash,
      expiredAt: expiredAt,
      createdBy: createdBy,
      canView: canView,
      canDownload: canDownload,
    );
    if (recipientEmails.isNotEmpty) {
      await _insertRecipients(
        shareLinkId: row['id'] as String,
        recipientEmails: recipientEmails,
        canView: canView,
        canDownload: canDownload,
      );
    }
    await _logShareCreated(createdBy: createdBy, fileId: fileId);
    return ShareLink.fromMap(row);
  }

  Future<Map<String, dynamic>> _insertShareLink({
    required String fileId,
    required String token,
    required String accessType,
    required String? passwordHash,
    required DateTime? expiredAt,
    required String createdBy,
    required bool canView,
    required bool canDownload,
  }) async {
    final payload = {
      'file_id': fileId,
      'token': token,
      'access_type': accessType,
      'password_hash': passwordHash,
      'expired_at': expiredAt?.toIso8601String(),
      'can_view': canView,
      'can_download': canDownload,
      'created_by': createdBy,
    };
    try {
      return await _client
          .from('share_links')
          .insert(payload)
          .select()
          .single();
    } on PostgrestException catch (e) {
      if (!_isMissingPermissionColumn(e)) {
        rethrow;
      }
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('can_view')
        ..remove('can_download');
      return _client
          .from('share_links')
          .insert(fallbackPayload)
          .select()
          .single();
    }
  }

  Future<void> _insertRecipients({
    required String shareLinkId,
    required List<String> recipientEmails,
    required bool canView,
    required bool canDownload,
  }) async {
    final rows = recipientEmails
        .map(
          (email) => {
            'share_link_id': shareLinkId,
            'email': email,
            'can_view': canView,
            'can_download': canDownload,
          },
        )
        .toList();
    try {
      await _client.from('share_recipients').insert(rows);
    } on PostgrestException catch (e) {
      if (!_isMissingPermissionColumn(e)) {
        rethrow;
      }
      final fallbackRows = rows
          .map(
            (row) => Map<String, dynamic>.from(row)
              ..remove('can_view')
              ..remove('can_download'),
          )
          .toList();
      await _client.from('share_recipients').insert(fallbackRows);
    }
  }

  Future<void> _logShareCreated({
    required String createdBy,
    required String fileId,
  }) async {
    try {
      await _client.from('activity_logs').insert({
        'user_id': createdBy,
        'file_id': fileId,
        'action': 'create_share_link',
        'status': 'success',
        'platform': 'web',
      });
    } catch (_) {
      // Sharing must still succeed even if optional activity logging is not ready.
    }
  }

  bool _isMissingPermissionColumn(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('can_view') || message.contains('can_download');
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

  Stream<List<SharedItem>> watchMailbox({
    required String userId,
    required String email,
  }) {
    if (!SupabaseConfig.isConfigured) {
      return Stream.value(demoSharedItems);
    }
    return _client
        .from('share_recipients')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((_) => listMailbox(userId: userId, email: email));
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

  Future<ShareAccess> fetchAccess(String token) async {
    if (!SupabaseConfig.isConfigured) {
      final item = demoSharedItems
          .where((shared) => shared.token == token)
          .firstOrNull;
      return ShareAccess(
        token: token,
        fileName: item?.fileName ?? 'Demo secure file',
        fileType: item?.fileType ?? 'pdf',
        accessType: item?.accessType ?? 'public',
        canView: item?.canView ?? true,
        canDownload: item?.canDownload ?? !token.contains('view-only'),
        requiresPassword: token.contains('protected'),
        isActive: true,
      );
    }
    final response = await _client.functions.invoke(
      'generate-download-url',
      body: {'token': token, 'action': 'metadata'},
    );
    return ShareAccess.fromMap(_functionData(response.data));
  }

  Future<String> generateFileUrl({
    required String token,
    required String action,
    String? password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return 'https://example.com/$token';
    }
    final response = await _client.functions.invoke(
      'generate-download-url',
      body: {'token': token, 'action': action, 'password': password},
    );
    final data = _functionData(response.data);
    final signedUrl = data['signed_url'] as String?;
    if (signedUrl == null || signedUrl.isEmpty) {
      throw Exception(data['error'] ?? 'URL file tidak tersedia.');
    }
    if (data['is_encrypted'] != true) {
      return signedUrl;
    }
    return _decryptToObjectUrl(data, signedUrl, action);
  }

  Map<String, dynamic> _functionData(Object? data) {
    if (data is Map<String, dynamic>) {
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      return data;
    }
    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      if (mapped['error'] != null) {
        throw Exception(mapped['error']);
      }
      return mapped;
    }
    throw Exception('Response Edge Function tidak valid.');
  }

  Future<String> _decryptToObjectUrl(
    Map<String, dynamic> data,
    String signedUrl,
    String action,
  ) async {
    final key = data['encryption_key'] as String?;
    final nonce = data['encryption_nonce'] as String?;
    final mac = data['encryption_mac'] as String?;
    if (key == null || nonce == null || mac == null) {
      throw Exception('Metadata enkripsi file tidak lengkap.');
    }
    final response = await http.get(Uri.parse(signedUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('File terenkripsi gagal diambil dari storage.');
    }
    final plainBytes = await _encryption.decrypt(
      cipherBytes: Uint8List.fromList(response.bodyBytes),
      keyBase64: key,
      nonceBase64: nonce,
      macBase64: mac,
    );
    final fileName = data['file_name'] as String? ?? 'secure-file';
    final fileType = data['file_type'] as String? ?? 'octet-stream';
    final blob = html.Blob([plainBytes], _mimeType(fileType));
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    if (action == 'download') {
      final anchor = html.AnchorElement(href: objectUrl)
        ..download = fileName
        ..target = '_blank';
      anchor.click();
    } else {
      html.window.open(objectUrl, '_blank');
    }
    return objectUrl;
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

  String _token() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final randomPart = List.generate(
      40,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}$randomPart';
  }
}

class ShareAccess {
  const ShareAccess({
    required this.token,
    required this.fileName,
    required this.fileType,
    required this.accessType,
    required this.canView,
    required this.canDownload,
    required this.requiresPassword,
    required this.isActive,
    this.fileSize,
    this.ownerEmail,
    this.expiredAt,
  });

  final String token;
  final String fileName;
  final String fileType;
  final String accessType;
  final bool canView;
  final bool canDownload;
  final bool requiresPassword;
  final bool isActive;
  final int? fileSize;
  final String? ownerEmail;
  final DateTime? expiredAt;

  factory ShareAccess.fromMap(Map<String, dynamic> map) {
    return ShareAccess(
      token: map['token'] as String? ?? '',
      fileName: map['file_name'] as String? ?? 'Shared file',
      fileType: map['file_type'] as String? ?? '-',
      accessType: map['access_type'] as String? ?? 'public',
      canView: map['can_view'] as bool? ?? true,
      canDownload: map['can_download'] as bool? ?? true,
      requiresPassword: map['requires_password'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      fileSize: (map['file_size'] as num?)?.toInt(),
      ownerEmail: map['owner_email'] as String?,
      expiredAt: map['expired_at'] == null
          ? null
          : DateTime.tryParse(map['expired_at'] as String),
    );
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
