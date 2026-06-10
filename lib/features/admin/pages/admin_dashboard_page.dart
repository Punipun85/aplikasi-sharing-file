import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/stat_card.dart';
import '../../activity/models/activity_log.dart';
import '../../files/models/secure_file.dart';
import '../../shell/app_shell.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    final columns = Responsive.isMobile(context) ? 1 : 4;
    return AppShell(
      title: 'Admin Dashboard',
      child: StreamBuilder<List<AdminUser>>(
        stream: service.watchUsers(),
        builder: (context, usersSnapshot) {
          return StreamBuilder<List<SecureFile>>(
            stream: service.watchFiles(),
            builder: (context, filesSnapshot) {
              return StreamBuilder<List<ActivityLog>>(
                stream: service.watchLogs(),
                builder: (context, logsSnapshot) {
                  final users = usersSnapshot.data ?? demoUsers;
                  final files = filesSnapshot.data ?? [];
                  final logs = logsSnapshot.data ?? [];
                  final storageUsed = files.fold<int>(
                    0,
                    (sum, file) => sum + file.fileSize,
                  );
                  final downloads = files.fold<int>(
                    0,
                    (sum, file) => sum + file.downloadCount,
                  );
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: Responsive.isMobile(context)
                              ? 3.5
                              : 1.8,
                          children: [
                            StatCard(
                              label: 'Total users',
                              value: '${users.length}',
                              icon: Icons.group_outlined,
                            ),
                            StatCard(
                              label: 'Total files',
                              value: '${files.length}',
                              icon: Icons.folder_outlined,
                            ),
                            StatCard(
                              label: 'Total storage',
                              value: Formatters.bytes(storageUsed),
                              icon: Icons.cloud_outlined,
                            ),
                            StatCard(
                              label: 'Downloads',
                              value: '$downloads',
                              icon: Icons.download_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Recent Activity',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  const Chip(
                                    avatar: Icon(Icons.sync, size: 16),
                                    label: Text('Realtime'),
                                  ),
                                ],
                              ),
                              if (logs.isEmpty)
                                const ListTile(
                                  title: Text('Belum ada activity log.'),
                                ),
                              for (final log in logs.take(8))
                                ListTile(
                                  title: Text(log.action),
                                  subtitle: Text(
                                    '${log.status} - ${Formatters.date(log.createdAt)}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
