import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.enhanced_encryption_outlined,
                    color: AppTheme.actionBlue,
                    size: 52,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'SecureShare',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kelola file, link berbagi, password, expiry, dan activity log dari satu akun lintas Android, Web, iOS, dan Desktop.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 28),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
