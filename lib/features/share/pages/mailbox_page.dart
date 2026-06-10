import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shell/app_shell.dart';
import '../providers/share_provider.dart';
import '../widgets/shared_item_tile.dart';

class MailboxPage extends StatefulWidget {
  const MailboxPage({super.key});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.userId;
      final email = auth.profileEmail;
      if (userId != null && email != null) {
        context.read<ShareProvider>().loadMailbox(userId: userId, email: email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final share = context.watch<ShareProvider>();
    return AppShell(
      title: 'Mailbox',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: share.mailbox.isEmpty
            ? const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Mailbox kosong',
                message:
                    'File yang dibagikan secara spesifik ke email kamu akan muncul di sini.',
              )
            : Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: share.mailbox.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) =>
                      SharedItemTile(item: share.mailbox[index]),
                ),
              ),
      ),
    );
  }
}
