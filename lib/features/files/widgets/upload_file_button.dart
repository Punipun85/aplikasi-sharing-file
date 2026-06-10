import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/file_provider.dart';

class UploadFileButton extends StatelessWidget {
  const UploadFileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          final userId = context.read<AuthProvider>().userId;
          if (userId == null) {
            return;
          }
          final ok = await context.read<FileProvider>().pickAndUpload(userId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'File berhasil diproses.'
                      : context.read<FileProvider>().error ??
                            'Upload dibatalkan.',
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload'),
      ),
    );
  }
}
