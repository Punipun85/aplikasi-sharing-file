import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  PlatformFile? _avatarFile;
  Uint8List? _avatarBytes;
  String? _avatarUrl;
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
    _avatarUrl = profile['avatar_url'] as String?;
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
                  Center(
                    child: Column(
                      children: [
                        _AvatarPreview(
                          bytes: _avatarBytes,
                          imageUrl: _avatarUrl,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: auth.isLoading ? null : _pickAvatar,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(
                            _avatarFile == null
                                ? 'Pilih Foto Profile'
                                : 'Ganti Foto Profile',
                          ),
                        ),
                        if (_avatarFile != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _avatarFile!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
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

  Future<void> _pickAvatar() async {
    setState(() => _localError = null);
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    final extension = (file.extension ?? '').toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      setState(() => _localError = 'Foto profil harus JPG, PNG, atau WEBP.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setState(() => _localError = 'Ukuran foto profil maksimal 5 MB.');
      return;
    }
    if (file.bytes == null) {
      setState(() => _localError = 'Foto tidak dapat dibaca.');
      return;
    }
    setState(() {
      _avatarFile = file;
      _avatarBytes = file.bytes;
    });
  }

  Future<void> _save() async {
    setState(() => _localError = null);
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Nama wajib diisi dan email harus valid.');
      return;
    }
    String? avatarUrl = _avatarUrl;
    if (_avatarFile != null) {
      avatarUrl = await context.read<AuthProvider>().uploadAvatar(_avatarFile!);
      if (!mounted) {
        return;
      }
      if (avatarUrl == null) {
        return;
      }
    }
    final ok = await context.read<AuthProvider>().updateProfile(
      name: name,
      email: email,
      avatarUrl: avatarUrl,
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

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.bytes, required this.imageUrl});

  final Uint8List? bytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (bytes != null) {
      image = MemoryImage(bytes!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = NetworkImage(imageUrl!);
    }

    return CircleAvatar(
      radius: 44,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Icon(
              Icons.person_outline,
              size: 42,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }
}
