import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../share/widgets/share_file_dialog.dart';
import '../../shell/app_shell.dart';
import '../models/secure_file.dart';
import '../providers/file_provider.dart';
import '../widgets/file_card.dart';
import '../widgets/upload_file_button.dart';

class MyFilesPage extends StatefulWidget {
  const MyFilesPage({super.key});

  @override
  State<MyFilesPage> createState() => _MyFilesPageState();
}

class _MyFilesPageState extends State<MyFilesPage> {
  String _query = '';
  String _type = 'all';
  String _sort = 'date';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<FileProvider>().watch(userId);
        context.read<FileProvider>().load(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileProvider>();
    final files = _filtered(provider.files);
    return AppShell(
      title: 'My Files',
      actions: const [UploadFileButton()],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search file',
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                DropdownButton<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All types')),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'zip', child: Text('ZIP')),
                    DropdownMenuItem(value: 'pptx', child: Text('PPTX')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? 'all'),
                ),
                DropdownButton<String>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                      value: 'date',
                      child: Text('Sort by date'),
                    ),
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Sort by name'),
                    ),
                    DropdownMenuItem(
                      value: 'size',
                      child: Text('Sort by size'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _sort = value ?? 'date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: files.isEmpty
                  ? const EmptyState(
                      icon: Icons.folder_open,
                      title: 'Belum ada file',
                      message:
                          'Upload file pertama untuk mulai membuat share link aman.',
                    )
                  : Responsive.isMobile(context)
                  ? ListView.separated(
                      itemCount: files.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => FileCard(
                        file: files[index],
                        onShare: () => _openShare(files[index].id),
                      ),
                    )
                  : Card(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Size')),
                            DataColumn(label: Text('Uploaded')),
                            DataColumn(label: Text('Downloads')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (final file in files)
                              DataRow(
                                cells: [
                                  DataCell(Text(file.originalName)),
                                  DataCell(Text(file.fileType.toUpperCase())),
                                  DataCell(
                                    Text(Formatters.bytes(file.fileSize)),
                                  ),
                                  DataCell(
                                    Text(Formatters.date(file.createdAt)),
                                  ),
                                  DataCell(Text('${file.downloadCount}')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Detail',
                                          onPressed: () =>
                                              context.go('/files/${file.id}'),
                                          icon: const Icon(Icons.info_outline),
                                        ),
                                        IconButton(
                                          tooltip: 'Share',
                                          onPressed: () => _openShare(file.id),
                                          icon: const Icon(Icons.link),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<SecureFile> _filtered(List<SecureFile> input) {
    final files = input.where((file) {
      final matchQuery = file.originalName.toLowerCase().contains(
        _query.toLowerCase(),
      );
      final matchType = _type == 'all' || file.fileType == _type;
      return matchQuery && matchType;
    }).toList();
    files.sort((a, b) {
      if (_sort == 'name') {
        return a.originalName.compareTo(b.originalName);
      }
      if (_sort == 'size') {
        return b.fileSize.compareTo(a.fileSize);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return files;
  }

  void _openShare(String fileId) {
    showDialog(
      context: context,
      builder: (_) => ShareFileDialog(fileId: fileId),
    );
  }
}
