import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../shell/app_shell.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _localError;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final profile = context.read<AuthProvider>().profile ?? {};
    _name.text = '${profile['name'] ?? ''}';
    _email.text = '${profile['email'] ?? ''}';
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppShell(
      title: 'Edit Profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (_localError != null || auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _localError ?? auth.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: auth.isLoading ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Simpan'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(Icons.close),
                        label: const Text('Batal'),
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

  Future<void> _save() async {
    setState(() => _localError = null);
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Nama wajib diisi dan email harus valid.');
      return;
    }
    final ok = await context.read<AuthProvider>().updateProfile(
      name: name,
      email: email,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile berhasil diperbarui.')),
      );
      context.go('/profile');
    }
  }
}
