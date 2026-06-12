import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../share/models/shared_item.dart';
import '../../share/services/share_service.dart';

class MailboxPreview extends StatelessWidget {
  const MailboxPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;
    final email = auth.profileEmail;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mailbox',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Chip(
                  avatar: Icon(Icons.sync, size: 16),
                  label: Text('Realtime'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: userId == null || email == null
                  ? Stream.value(<SharedItem>[])
                  : ShareService().watchMailbox(userId: userId, email: email),
              builder: (context, snapshot) {
                final items = (snapshot.data ?? <SharedItem>[])
                    .take(4)
                    .toList();
                if (items.isEmpty) {
                  return const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.inbox_outlined),
                    title: Text('Mailbox kosong'),
                    subtitle: Text('File specific user akan muncul di sini.'),
                  );
                }
                return Column(
                  children: [
                    for (final item in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          item.canDownload
                              ? Icons.download_outlined
                              : Icons.visibility_outlined,
                        ),
                        title: Text(item.fileName),
                        subtitle: Text(
                          '${item.ownerEmail} - ${item.canDownload ? 'View + Download' : 'View only'}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Open link',
                          onPressed: () => context.go('/share/${item.token}'),
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
