import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final auth = context.watch<AuthProvider>();
    final items = auth.isAdmin ? _adminItems : _userItems;
    final profileName = auth.profile?['name'] as String? ?? 'User';
    final profileEmail = auth.profileEmail ?? 'Belum login';
    final avatarUrl = auth.profile?['avatar_url'] as String?;

    if (mobile) {
      return Scaffold(
        appBar: AppBar(
          leading: _showBackButton(context, items)
              ? IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _goBack(context, auth),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              Text(profileEmail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: actions,
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex(context, items),
          onDestinationSelected: (index) => context.go(items[index].path),
          destinations: [
            for (final item in items.take(5))
              NavigationDestination(icon: Icon(item.icon), label: item.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            color: AppTheme.navy,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'SecureShare',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final item in items)
                    _SidebarItem(
                      item: item,
                      selected: GoRouterState.of(context).uri.path == item.path,
                      onTap: () => context.go(item.path),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.go('/profile'),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? const Icon(Icons.person_outline)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    profileEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ...actions,
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context, List<_NavItem> items) {
    final path = GoRouterState.of(context).uri.path;
    final index = items
        .take(5)
        .toList()
        .indexWhere((item) => item.path == path);
    return index < 0 ? 0 : index;
  }

  bool _showBackButton(BuildContext context, List<_NavItem> items) {
    final path = GoRouterState.of(context).uri.path;
    return !items.any((item) => item.path == path);
  }

  void _goBack(BuildContext context, AuthProvider auth) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/files/')) {
      context.go('/files');
      return;
    }
    if (path.startsWith('/profile/')) {
      context.go('/profile');
      return;
    }
    if (path.startsWith('/admin/')) {
      context.go('/admin');
      return;
    }
    context.go(auth.isAdmin ? '/admin' : '/dashboard');
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.white.withValues(alpha: 0.10),
        iconColor: Colors.white,
        textColor: Colors.white,
        selectedColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(item.icon),
        title: Text(item.label),
        onTap: onTap,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}

const _userItems = [
  _NavItem('Dashboard', '/dashboard', Icons.dashboard_outlined),
  _NavItem('Files', '/files', Icons.folder_outlined),
  _NavItem('Open Link', '/shares', Icons.link_outlined),
  _NavItem('Activity', '/activity', Icons.history_outlined),
  _NavItem('Profile', '/profile', Icons.person_outline),
];

const _adminItems = [
  _NavItem('Dashboard', '/admin', Icons.admin_panel_settings_outlined),
  _NavItem('Users', '/admin/users', Icons.group_outlined),
  _NavItem('Files', '/admin/files', Icons.folder_copy_outlined),
  _NavItem('Logs', '/admin/logs', Icons.receipt_long_outlined),
  _NavItem('Profile', '/profile', Icons.person_outline),
];
