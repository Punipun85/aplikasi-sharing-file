import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shell/app_shell.dart';

class SharedLinksPage extends StatefulWidget {
  const SharedLinksPage({super.key});

  @override
  State<SharedLinksPage> createState() => _SharedLinksPageState();
}

class _SharedLinksPageState extends State<SharedLinksPage> {
  final _link = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Open Shared Link',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_outlined, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      'Buka Link yang Dibagikan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan URL lengkap atau token link SecureShare untuk membuka file public, protected, private, atau specific user.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _link,
                      decoration: const InputDecoration(
                        labelText: 'Link atau token',
                        hintText: 'https://app.secureshare/share/abc123',
                        prefixIcon: Icon(Icons.link),
                      ),
                      onSubmitted: (_) => _openLink(),
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
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _openLink,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Buka Link'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _link.text = 'demo-public-link';
                        _openLink();
                      },
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Coba Link Demo'),
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

  void _openLink() {
    final token = _extractToken(_link.text);
    if (token == null) {
      setState(
        () => _error = 'Masukkan link /share/:token atau token yang valid.',
      );
      return;
    }
    setState(() => _error = null);
    context.go('/share/$token');
  }

  String? _extractToken(String value) {
    final input = value.trim();
    if (input.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(input);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final shareIndex = uri.pathSegments.indexOf('share');
      if (shareIndex >= 0 && uri.pathSegments.length > shareIndex + 1) {
        return uri.pathSegments[shareIndex + 1];
      }
    }

    final cleaned = input.replaceFirst(RegExp(r'^/share/'), '');
    if (RegExp(r'^[A-Za-z0-9_-]{6,}$').hasMatch(cleaned)) {
      return cleaned;
    }
    return null;
  }
}
