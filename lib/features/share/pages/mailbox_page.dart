import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shell/app_shell.dart';
import '../models/shared_item.dart';
import '../services/share_service.dart';
import '../widgets/shared_item_tile.dart';

class MailboxPage extends StatelessWidget {
  const MailboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;
    final email = auth.profileEmail;
    return AppShell(
      title: 'Mailbox',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<List<SharedItem>>(
          stream: userId == null || email == null
              ? Stream.value(const [])
              : ShareService().watchMailbox(userId: userId, email: email),
          builder: (context, snapshot) {
            final mailbox = snapshot.data ?? [];
            if (mailbox.isEmpty) {
              return const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Mailbox kosong',
                message:
                    'File yang dikirim khusus ke email kamu akan muncul di sini secara realtime.',
              );
            }
            return Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.mark_email_unread_outlined),
                    title: Text('File diterima'),
                    subtitle: Text(
                      'Item di sini berasal dari daftar penerima share, bukan activity log.',
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: mailbox.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) =>
                          SharedItemTile(item: mailbox[index]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
