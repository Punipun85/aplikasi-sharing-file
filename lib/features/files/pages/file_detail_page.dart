import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../share/providers/share_provider.dart';
import '../../share/widgets/share_file_dialog.dart';
import '../../shell/app_shell.dart';
import '../providers/file_provider.dart';

class FileDetailPage extends StatefulWidget {
  const FileDetailPage({super.key, required this.fileId});

  final String fileId;

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ShareProvider>().loadForFile(widget.fileId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = context.watch<FileProvider>().byId(widget.fileId);
    final links = context.watch<ShareProvider>().links;
    if (file == null) {
      return const AppShell(
        title: 'File Detail',
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'File tidak ditemukan',
          message: 'File mungkin sudah dihapus atau belum dimuat.',
        ),
      );
    }

    return AppShell(
      title: 'File Detail',
      actions: [
        ElevatedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => ShareFileDialog(fileId: file.id),
          ),
          icon: const Icon(Icons.link),
          label: const Text('Share'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  runSpacing: 16,
                  spacing: 40,
                  children: [
                    _Meta(label: 'Nama file', value: file.originalName),
                    _Meta(label: 'Tipe', value: file.fileType.toUpperCase()),
                    _Meta(
                      label: 'Ukuran',
                      value: Formatters.bytes(file.fileSize),
                    ),
                    _Meta(
                      label: 'Tanggal upload',
                      value: Formatters.date(file.createdAt),
                    ),
                    _Meta(label: 'Status', value: file.status),
                    _Meta(
                      label: 'Download count',
                      value: '${file.downloadCount}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Share Links',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (links.isEmpty) const Text('Belum ada link aktif.'),
                    for (final link in links)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link),
                        title: SelectableText('/share/${link.token}'),
                        subtitle: Text(
                          '${link.accessType} • expires ${link.expiredAt == null ? 'never' : Formatters.date(link.expiredAt!)}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
