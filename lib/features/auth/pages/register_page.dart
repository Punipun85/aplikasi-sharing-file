import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_card.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthCard(
      title: 'Buat Akun',
      subtitle: 'Akun ini dapat dipakai di Android, Web, iOS, dan Desktop.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Konfirmasi password'),
          ),
          if (_localError != null || auth.error != null) ...[
            const SizedBox(height: 12),
            Text(
              _localError ?? auth.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            child: auth.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Register'),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sudah punya akun? Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    if (_name.text.trim().isEmpty ||
        !_email.text.contains('@') ||
        _password.text.length < 8 ||
        _password.text != _confirm.text) {
      setState(
        () => _localError =
            'Pastikan nama, email, password minimal 8 karakter, dan konfirmasi sudah benar.',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
    );
    if (!ok || !mounted) {
      return;
    }

    context.go('/login?registered=1');
  }
}
