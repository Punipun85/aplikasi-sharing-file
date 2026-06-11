import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../share/providers/share_provider.dart';
import '../../share/widgets/share_file_dialog.dart';
import '../../shell/app_shell.dart';
import '../providers/file_provider.dart';
import '../services/file_service.dart';

class FileDetailPage extends StatefulWidget {
  const FileDetailPage({super.key, required this.fileId});

  final String fileId;

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  Future<FilePreviewData>? _previewFuture;

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
            _PreviewCard(
              fileType: file.fileType,
              previewFuture: _previewFuture,
              onLoadPreview: () {
                setState(() {
                  _previewFuture = context.read<FileProvider>().preview(file);
                });
              },
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.fileType,
    required this.previewFuture,
    required this.onLoadPreview,
  });

  final String fileType;
  final Future<FilePreviewData>? previewFuture;
  final VoidCallback onLoadPreview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Preview File',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onLoadPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    previewFuture == null ? 'Load Preview' : 'Reload',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (previewFuture == null)
              const Text(
                'Klik Load Preview untuk membuka file milikmu. File terenkripsi akan didekripsi di aplikasi sebelum ditampilkan.',
              )
            else
              FutureBuilder<FilePreviewData>(
                future: previewFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      _friendlyPreviewError(snapshot.error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                  final preview = snapshot.data;
                  if (preview == null) {
                    return const Text('Preview tidak tersedia.');
                  }
                  return _PreviewContent(preview: preview, fileType: fileType);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _friendlyPreviewError(Object? error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('row-level security') ||
        lower.contains('unauthorized')) {
      return 'Preview ditolak oleh policy Storage. Pastikan policy read owner untuk bucket secure-files sudah dijalankan.';
    }
    if (lower.contains('metadata enkripsi')) {
      return 'Metadata enkripsi file belum lengkap. Upload ulang file agar bisa dipreview.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.preview, required this.fileType});

  final FilePreviewData preview;
  final String fileType;

  @override
  Widget build(BuildContext context) {
    final lower = fileType.toLowerCase();
    if ({'jpg', 'jpeg', 'png'}.contains(lower)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          preview.bytes,
          height: 360,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      );
    }
    if (lower == 'txt') {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 360),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            utf8.decode(preview.bytes, allowMalformed: true),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lower == 'pdf'
              ? 'PDF sudah didekripsi. Buka preview di tab baru.'
              : 'File sudah didekripsi. Tipe ini belum punya preview inline, tetapi bisa dibuka di tab baru.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: preview.objectUrl == null
              ? null
              : () => html.window.open(preview.objectUrl!, '_blank'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Buka Preview'),
        ),
      ],
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
