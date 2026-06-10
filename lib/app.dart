import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/activity/pages/activity_log_page.dart';
import 'features/admin/pages/admin_dashboard_page.dart';
import 'features/admin/pages/admin_files_page.dart';
import 'features/admin/pages/admin_logs_page.dart';
import 'features/admin/pages/admin_users_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/pages/user_dashboard_page.dart';
import 'features/files/pages/file_detail_page.dart';
import 'features/files/pages/my_files_page.dart';
import 'features/onboarding/pages/onboarding_page.dart';
import 'features/profile/pages/edit_profile_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'features/share/pages/download_share_page.dart';
import 'features/share/pages/mailbox_page.dart';
import 'features/share/pages/shared_links_page.dart';
import 'features/splash/pages/splash_page.dart';

class SecureShareApp extends StatelessWidget {
  const SecureShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'SecureShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router(auth),
    );
  }

  GoRouter _router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isPublic =
            location == '/splash' ||
            location == '/onboarding' ||
            location == '/login' ||
            location == '/register' ||
            location.startsWith('/share/');

        if (auth.isBootstrapping) {
          return location == '/splash' ? null : '/splash';
        }
        if (!auth.isAuthenticated && !isPublic) {
          return '/login';
        }
        if (auth.isAuthenticated &&
            (location == '/login' ||
                location == '/register' ||
                location == '/onboarding')) {
          return auth.isAdmin ? '/admin' : '/dashboard';
        }
        if (location.startsWith('/admin') && !auth.isAdmin) {
          return '/dashboard';
        }
        if (location == '/splash') {
          return auth.isAuthenticated
              ? (auth.isAdmin ? '/admin' : '/dashboard')
              : '/onboarding';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const UserDashboardPage(),
        ),
        GoRoute(path: '/files', builder: (_, _) => const MyFilesPage()),
        GoRoute(path: '/mailbox', builder: (_, _) => const MailboxPage()),
        GoRoute(path: '/shares', builder: (_, _) => const SharedLinksPage()),
        GoRoute(
          path: '/files/:id',
          builder: (_, state) =>
              FileDetailPage(fileId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/share/:token',
          builder: (_, state) =>
              DownloadSharePage(token: state.pathParameters['token']!),
        ),
        GoRoute(path: '/activity', builder: (_, _) => const ActivityLogPage()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const EditProfilePage(),
        ),
        GoRoute(path: '/admin', builder: (_, _) => const AdminDashboardPage()),
        GoRoute(
          path: '/admin/users',
          builder: (_, _) => const AdminUsersPage(),
        ),
        GoRoute(
          path: '/admin/files',
          builder: (_, _) => const AdminFilesPage(),
        ),
        GoRoute(path: '/admin/logs', builder: (_, _) => const AdminLogsPage()),
      ],
    );
  }
}
