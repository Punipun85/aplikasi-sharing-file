import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../shell/app_shell.dart';
import '../services/admin_service.dart';

class AdminLogsPage extends StatelessWidget {
  const AdminLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    return AppShell(
      title: 'Admin Logs',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder(
          stream: service.watchLogs(),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            return Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(log.action),
                    subtitle: Text(
                      '${log.status} - ${log.platform} - ${Formatters.date(log.createdAt)}',
                    ),
                    trailing: Text(log.fileId ?? '-'),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
