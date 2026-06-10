import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../share/providers/share_provider.dart';

class ShareFileDialog extends StatefulWidget {
  const ShareFileDialog({super.key, required this.fileId});

  final String fileId;

  @override
  State<ShareFileDialog> createState() => _ShareFileDialogState();
}

class _ShareFileDialogState extends State<ShareFileDialog> {
  String _accessType = 'public';
  String _expiry = '7';
  String _permission = 'download';
  final _password = TextEditingController();
  final _recipients = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _recipients.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final share = context.watch<ShareProvider>();
    return AlertDialog(
      title: const Text('Share File'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _accessType,
              decoration: const InputDecoration(labelText: 'Access type'),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'protected', child: Text('Protected')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(
                  value: 'specific_user',
                  child: Text('Specific user'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _accessType = value ?? 'public'),
            ),
            const SizedBox(height: 12),
            if (_accessType == 'protected')
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password link'),
                obscureText: true,
              ),
            if (_accessType == 'protected') const SizedBox(height: 12),
            if (_accessType == 'specific_user') ...[
              TextField(
                controller: _recipients,
                decoration: const InputDecoration(
                  labelText: 'Email penerima',
                  hintText: 'user1@email.com, user2@email.com',
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _permission,
              decoration: const InputDecoration(labelText: 'Izin penerima'),
              items: const [
                DropdownMenuItem(
                  value: 'view',
                  child: Text('Hanya bisa dilihat'),
                ),
                DropdownMenuItem(
                  value: 'download',
                  child: Text('Bisa dilihat dan download'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _permission = value ?? 'download'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _expiry,
              decoration: const InputDecoration(labelText: 'Expired link'),
              items: const [
                DropdownMenuItem(value: '1h', child: Text('1 hour')),
                DropdownMenuItem(value: '1', child: Text('24 hours')),
                DropdownMenuItem(value: '7', child: Text('7 days')),
                DropdownMenuItem(value: '30', child: Text('30 days')),
              ],
              onChanged: (value) => setState(() => _expiry = value ?? '7'),
            ),
            if (share.latest != null) ...[
              const SizedBox(height: 16),
              SelectableText('/share/${share.latest!.token}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: share.isLoading ? null : _create,
          icon: const Icon(Icons.link),
          label: const Text('Generate Link'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      return;
    }
    final expiredAt = switch (_expiry) {
      '1h' => DateTime.now().add(const Duration(hours: 1)),
      '1' => DateTime.now().add(const Duration(days: 1)),
      '30' => DateTime.now().add(const Duration(days: 30)),
      _ => DateTime.now().add(const Duration(days: 7)),
    };
    final ok = await context.read<ShareProvider>().create(
      fileId: widget.fileId,
      createdBy: userId,
      accessType: _accessType,
      password: _accessType == 'protected' ? _password.text : null,
      expiredAt: expiredAt,
      canView: true,
      canDownload: _permission == 'download',
      recipientEmails: _recipients.text
          .split(',')
          .map((email) => email.trim())
          .where((email) => email.isNotEmpty)
          .toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Share link berhasil dibuat.' : 'Gagal membuat share link.',
          ),
        ),
      );
    }
  }
}
