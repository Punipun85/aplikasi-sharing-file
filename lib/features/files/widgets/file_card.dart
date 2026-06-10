import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/secure_file.dart';

class FileCard extends StatelessWidget {
  const FileCard({super.key, required this.file, required this.onShare});

  final SecureFile file;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(
          file.originalName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file.fileType.toUpperCase()} • ${Formatters.bytes(file.fileSize)} • ${Formatters.date(file.createdAt)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'detail') context.go('/files/${file.id}');
            if (value == 'share') onShare();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'detail', child: Text('Detail')),
            PopupMenuItem(value: 'share', child: Text('Share')),
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
