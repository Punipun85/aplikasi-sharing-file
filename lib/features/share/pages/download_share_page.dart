import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../services/share_service.dart';

class DownloadSharePage extends StatefulWidget {
  const DownloadSharePage({super.key, required this.token});

  final String token;

  @override
  State<DownloadSharePage> createState() => _DownloadSharePageState();
}

class _DownloadSharePageState extends State<DownloadSharePage> {
  final _service = ShareService();
  final _password = TextEditingController();
  Future<ShareAccess>? _accessFuture;
  bool _isOpening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accessFuture = _service.fetchAccess(widget.token);
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: FutureBuilder<ShareAccess>(
              future: _accessFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(message: _friendlyError(snapshot.error));
                }
                final access = snapshot.data;
                if (access == null) {
                  return const _ErrorCard(message: 'Link tidak ditemukan.');
                }
                return _AccessCard(
                  access: access,
                  password: _password,
                  isOpening: _isOpening,
                  error: _error,
                  onView: () => _open(access, 'view'),
                  onDownload: access.canDownload
                      ? () => _open(access, 'download')
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(ShareAccess access, String action) async {
    setState(() {
      _isOpening = true;
      _error = null;
    });
    try {
      if (access.requiresPassword && _password.text.trim().isEmpty) {
        throw Exception('Masukkan password link terlebih dahulu.');
      }
      final url = await _service.generateFileUrl(
        token: widget.token,
        action: action,
        password: access.requiresPassword ? _password.text.trim() : null,
      );
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw Exception('File tidak bisa dibuka di perangkat ini.');
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  String _friendlyError(Object? error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('link expired')) {
      return 'Link sudah kadaluarsa.';
    }
    if (lower.contains('link inactive')) {
      return 'Link sudah tidak aktif.';
    }
    if (lower.contains('file deleted')) {
      return 'File sudah dihapus.';
    }
    if (lower.contains('wrong password') || lower.contains('password')) {
      return 'Password salah atau belum diisi.';
    }
    if (lower.contains('download disabled')) {
      return 'Izin download dinonaktifkan. File hanya bisa dilihat.';
    }
    if (lower.contains('view disabled')) {
      return 'Izin melihat file dinonaktifkan.';
    }
    if (lower.contains('access denied')) {
      return 'Akses ditolak untuk akun ini.';
    }
    if (lower.contains('function not found')) {
      return 'Edge Function generate-download-url belum dideploy di Supabase.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.access,
    required this.password,
    required this.isOpening,
    required this.error,
    required this.onView,
    required this.onDownload,
  });

  final ShareAccess access;
  final TextEditingController password;
  final bool isOpening;
  final String? error;
  final VoidCallback onView;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final canDownload = onDownload != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.file_download_outlined,
              color: AppTheme.actionBlue,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              'Secure Shared File',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              access.fileName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(access.fileType.toUpperCase())),
                Chip(
                  label: Text(canDownload ? 'View + Download' : 'View only'),
                ),
                if (access.fileSize != null)
                  Chip(label: Text(Formatters.bytes(access.fileSize!))),
              ],
            ),
            if (access.ownerEmail != null) ...[
              const SizedBox(height: 10),
              Text(
                'Dibagikan oleh ${access.ownerEmail}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (access.requiresPassword) ...[
              const SizedBox(height: 18),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password link'),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: isOpening || !access.canView ? null : onView,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Lihat File'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isOpening ? null : onDownload,
              icon: isOpening
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(canDownload ? 'Download' : 'Download dinonaktifkan'),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              canDownload
                  ? 'File ini bisa dilihat dan diunduh sesuai izin pemilik.'
                  : 'Pemilik file hanya memberi izin lihat. Tombol download dimatikan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_outlined,
              color: Theme.of(context).colorScheme.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Link tidak bisa dibuka',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
