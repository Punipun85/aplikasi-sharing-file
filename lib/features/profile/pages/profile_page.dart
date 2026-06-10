import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../files/providers/file_provider.dart';
import '../../shell/app_shell.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final files = context.watch<FileProvider>();
    final profile = auth.profile ?? {};
    return AppShell(
      title: 'Profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(height: 18),
                _Row(label: 'Nama', value: '${profile['name'] ?? '-'}'),
                _Row(label: 'Email', value: '${profile['email'] ?? '-'}'),
                _Row(label: 'Role', value: '${profile['role'] ?? 'user'}'),
                _Row(
                  label: 'Storage used',
                  value: Formatters.bytes(files.storageUsed),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profile'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
