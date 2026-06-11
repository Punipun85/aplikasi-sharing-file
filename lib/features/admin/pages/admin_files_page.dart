import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../shell/app_shell.dart';
import '../services/admin_service.dart';

class AdminFilesPage extends StatelessWidget {
  const AdminFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    return AppShell(
      title: 'Admin Files',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder(
          stream: service.watchFiles(),
          builder: (context, snapshot) {
            final files = snapshot.data ?? [];
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('File ID')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Size')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Risk')),
                    DataColumn(label: Text('Downloads')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: [
                    for (final file in files)
                      DataRow(
                        cells: [
                          DataCell(Text(file.id.substring(0, 8))),
                          DataCell(Text(file.fileType)),
                          DataCell(Text(Formatters.bytes(file.fileSize))),
                          DataCell(Text(file.status)),
                          DataCell(
                            Chip(
                              label: Text(file.riskStatus ?? 'unknown'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          DataCell(Text('${file.downloadCount}')),
                          DataCell(
                            IconButton(
                              tooltip: 'Mark as deleted',
                              onPressed: file.status == 'deleted'
                                  ? null
                                  : () async {
                                      await service.deleteFile(file.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'File ${file.id.substring(0, 8)} ditandai deleted.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline),
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
