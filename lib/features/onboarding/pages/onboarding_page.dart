import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _link = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.enhanced_encryption_outlined,
                    color: AppTheme.actionBlue,
                    size: 54,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Guest Dashboard',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Buka link file yang dibagikan tanpa login, atau masuk untuk mengunggah dan mengelola file terenkripsi milikmu.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Login'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/register'),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Register'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Buka Link Share',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _link,
                            decoration: const InputDecoration(
                              labelText: 'Tempel link atau token',
                              hintText:
                                  'https://domain.com/share/token atau token',
                            ),
                            onSubmitted: (_) => _openShareLink(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: _openShareLink,
                              icon: const Icon(Icons.link_outlined),
                              label: const Text('Buka Link'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: const [
                      _GuestFeature(
                        icon: Icons.public,
                        title: 'Public Link',
                        description: 'Guest bisa membuka link public valid.',
                      ),
                      _GuestFeature(
                        icon: Icons.password,
                        title: 'Protected Link',
                        description:
                            'Guest bisa memasukkan password jika link protected.',
                      ),
                      _GuestFeature(
                        icon: Icons.lock_outline,
                        title: 'Private Data',
                        description:
                            'Upload, dashboard, profile, dan activity wajib login.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openShareLink() {
    final token = _extractToken(_link.text.trim());
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Masukkan link share atau token yang valid.');
      return;
    }
    setState(() => _error = null);
    context.go('/share/$token');
  }

  String? _extractToken(String input) {
    if (input.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(input);
    if (uri != null) {
      if (uri.scheme == 'secureshare' && uri.host == 'share') {
        return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
      }
      final shareIndex = uri.pathSegments.indexOf('share');
      if (shareIndex >= 0 && uri.pathSegments.length > shareIndex + 1) {
        return uri.pathSegments[shareIndex + 1];
      }
    }
    return input.replaceFirst(RegExp(r'^/share/'), '');
  }
}

class _GuestFeature extends StatelessWidget {
  const _GuestFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.actionBlue),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}
