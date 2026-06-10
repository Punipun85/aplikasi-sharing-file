import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../activity/services/activity_service.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final log in demoLogs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  log.status == 'success'
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                ),
                title: Text(log.action),
                subtitle: Text(
                  '${log.platform} • ${Formatters.date(log.createdAt)}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
