import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../activity/services/activity_service.dart';
import '../../auth/providers/auth_provider.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Chip(
                  avatar: Icon(Icons.sync, size: 16),
                  label: Text('Realtime'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: userId == null
                  ? Stream.value(demoLogs)
                  : ActivityService().watchForUser(userId),
              builder: (context, snapshot) {
                final logs = (snapshot.data ?? demoLogs).take(5).toList();
                if (logs.isEmpty) {
                  return const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Belum ada aktivitas.'),
                  );
                }
                return Column(
                  children: [
                    for (final log in logs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          log.status == 'success'
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                        ),
                        title: Text(log.action),
                        subtitle: Text(
                          '${log.platform} - ${Formatters.date(log.createdAt)}',
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
