import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../models/shared_item.dart';

class SharedItemTile extends StatelessWidget {
  const SharedItemTile({super.key, required this.item});

  final SharedItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.canDownload ? Icons.download_outlined : Icons.visibility_outlined,
      ),
      title: Text(item.fileName),
      subtitle: Text(
        '${item.accessType} - ${item.fileType.toUpperCase()} - ${Formatters.date(item.createdAt)}',
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          Chip(label: Text(item.canDownload ? 'View + Download' : 'View only')),
          IconButton(
            tooltip: 'Open link',
            onPressed: () => context.go('/share/${item.token}'),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }
}
