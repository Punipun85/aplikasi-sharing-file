import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../activity/services/activity_service.dart';
import '../../shell/app_shell.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    return AppShell(
      title: 'Activity Log',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All status')),
                    DropdownMenuItem(value: 'success', child: Text('Success')),
                    DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'all'),
                ),
                const Chip(
                  avatar: Icon(Icons.sync, size: 16),
                  label: Text('Realtime'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder(
                stream: userId == null
                    ? Stream.value(demoLogs)
                    : ActivityService().watchForUser(userId),
                builder: (context, snapshot) {
                  final logs = (snapshot.data ?? demoLogs)
                      .where((log) => _status == 'all' || log.status == _status)
                      .toList();
                  return Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final log = logs[index];
                        return ListTile(
                          leading: Icon(
                            log.status == 'success'
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                          ),
                          title: Text(log.action),
                          subtitle: Text(
                            '${log.platform} - ${Formatters.date(log.createdAt)}',
                          ),
                          trailing: Chip(label: Text(log.status)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
