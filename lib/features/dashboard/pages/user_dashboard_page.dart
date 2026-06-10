import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../files/providers/file_provider.dart';
import '../../files/widgets/upload_file_button.dart';
import '../../shell/app_shell.dart';
import '../widgets/mailbox_preview.dart';
import '../widgets/recent_activity_list.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
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
    final files = context.watch<FileProvider>();
    final columns = Responsive.isMobile(context) ? 1 : 4;

    return AppShell(
      title: 'User Dashboard',
      actions: const [UploadFileButton()],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: Responsive.isMobile(context) ? 3.5 : 1.8,
              children: [
                StatCard(
                  label: 'Total file',
                  value: '${files.files.length}',
                  icon: Icons.folder_outlined,
                ),
                StatCard(
                  label: 'Active links',
                  value: '${files.activeLinks}',
                  icon: Icons.link_outlined,
                ),
                StatCard(
                  label: 'Downloads',
                  value: '${files.totalDownloads}',
                  icon: Icons.download_outlined,
                ),
                StatCard(
                  label: 'Storage used',
                  value: Formatters.bytes(files.storageUsed),
                  icon: Icons.cloud_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const MailboxPreview(),
            const SizedBox(height: 18),
            const RecentActivityList(),
          ],
        ),
      ),
    );
  }
}
