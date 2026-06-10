import 'package:flutter/material.dart';

import '../../shell/app_shell.dart';
import '../services/admin_service.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    return AppShell(
      title: 'Admin Users',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder(
          stream: service.watchUsers(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? demoUsers;
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: [
                    for (final user in users)
                      DataRow(
                        cells: [
                          DataCell(Text(user.name)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.role)),
                          DataCell(Chip(label: Text(user.status))),
                          DataCell(
                            IconButton(
                              tooltip: user.status == 'active'
                                  ? 'Deactivate user'
                                  : 'Activate user',
                              onPressed: () async {
                                final next = user.status == 'active'
                                    ? 'inactive'
                                    : 'active';
                                await service.updateUserStatus(user.id, next);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'User ${user.email} $next.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                user.status == 'active'
                                    ? Icons.block_outlined
                                    : Icons.check_circle_outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
