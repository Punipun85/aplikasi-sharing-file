import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/share_service.dart';

class DownloadSharePage extends StatefulWidget {
  const DownloadSharePage({super.key, required this.token});

  final String token;

  @override
  State<DownloadSharePage> createState() => _DownloadSharePageState();
}

class _DownloadSharePageState extends State<DownloadSharePage> {
  final _password = TextEditingController();
  bool _verified = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final protected = widget.token.contains('protected');
    final item = demoSharedItems
        .where((shared) => shared.token == widget.token)
        .firstOrNull;
    final canDownload =
        item?.canDownload ?? !widget.token.contains('view-only');
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
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
                      'Download Secure File',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (item != null) ...[
                      Text(
                        item.fileName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          canDownload ? 'View + Download' : 'View only',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SelectableText(
                      'Token: ${widget.token}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (protected && !_verified) ...[
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password link',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _verifyDemoPassword,
                        child: const Text('Verify Password'),
                      ),
                    ] else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Lihat File'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: canDownload ? () {} : null,
                            icon: const Icon(Icons.download),
                            label: Text(
                              canDownload
                                  ? 'Download'
                                  : 'Download dinonaktifkan',
                            ),
                          ),
                        ],
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text(
                      'Validasi produksi dilakukan oleh Edge Function generate-download-url sebelum signed URL dibuat.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _verifyDemoPassword() {
    setState(() {
      _verified = _password.text.length >= 6;
      _error = _verified ? null : 'Password salah atau kurang dari 6 karakter.';
    });
  }
}
