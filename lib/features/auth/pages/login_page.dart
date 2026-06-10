import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hasShownRegisterSuccess = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _showRegisterSuccessDialogIfNeeded(context);
    return AuthCard(
      title: 'Masuk ke SecureShare',
      subtitle: 'Gunakan email yang sama di semua platform.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(
              auth.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final ok = await auth.login(
                      _email.text.trim(),
                      _password.text,
                    );
                    if (ok && context.mounted) {
                      context.go(auth.isAdmin ? '/admin' : '/dashboard');
                    }
                  },
            child: auth.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Login'),
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Belum punya akun? Register'),
          ),
        ],
      ),
    );
  }

  void _showRegisterSuccessDialogIfNeeded(BuildContext context) {
    final registered =
        GoRouterState.of(context).uri.queryParameters['registered'] == '1';
    if (!registered || _hasShownRegisterSuccess) {
      return;
    }
    _hasShownRegisterSuccess = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Register berhasil'),
          content: const Text(
            'Akun kamu sudah dibuat. Silakan login untuk masuk ke SecureShare.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Login sekarang'),
            ),
          ],
        ),
      );
    });
  }
}
