import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_theme.dart';
import 'auth/admin_session.dart';
import 'auth/auth_pages.dart';
import 'collections/registry.dart';
import 'moderation/moderation_page.dart';
import 'shell/admin_shell.dart';
import 'shell/collection_page.dart';

/// Theme der App, nur dichter: Hairline-Ränder, kompakte Felder.
ThemeData adminTheme() {
  final base = AppTheme.light();
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: c),
  );
  return base.copyWith(
    dividerTheme: const DividerThemeData(color: AppColors.n200, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(AppColors.hairline),
      enabledBorder: border(AppColors.hairline),
      focusedBorder: border(AppColors.brand),
      errorBorder: border(AppColors.error),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

const _authPaths = {'/login', '/denied', '/mfa', '/mfa-setup', '/loading'};

GoRouter buildAdminRouter(AdminSession session) {
  return GoRouter(
    initialLocation: '/trails',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.uri.path;
      final target = switch (session.gate) {
        AdminGate.loading => '/loading',
        AdminGate.signedOut => '/login',
        AdminGate.notAdmin => '/denied',
        AdminGate.needsMfaEnroll => '/mfa-setup',
        AdminGate.needsMfaChallenge => '/mfa',
        AdminGate.ok => null,
      };
      if (target != null) return loc == target ? null : target;
      if (_authPaths.contains(loc) || loc == '/') return '/trails';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => AdminLoginPage(session: session),
      ),
      GoRoute(
        path: '/denied',
        builder: (_, _) => AdminDeniedPage(session: session),
      ),
      GoRoute(
        path: '/mfa-setup',
        builder: (_, _) => AdminMfaPage(session: session, enroll: true),
      ),
      GoRoute(
        path: '/mfa',
        builder: (_, _) => AdminMfaPage(session: session, enroll: false),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(
          session: session,
          location: state.uri.path,
          child: child,
        ),
        routes: [
          for (final spec in adminCollections) ...[
            GoRoute(
              path: spec.path,
              pageBuilder: (_, _) => NoTransitionPage(
                key: ValueKey('page-${spec.id}'),
                child: CollectionPage(spec: spec),
              ),
            ),
            GoRoute(
              path: '${spec.path}/:id',
              pageBuilder: (_, state) => NoTransitionPage(
                key: ValueKey('page-${spec.id}'),
                child: CollectionPage(
                  spec: spec,
                  itemId: state.pathParameters['id'],
                ),
              ),
            ),
          ],
          GoRoute(
            path: '/${moderationSection.id}',
            pageBuilder: (_, _) => const NoTransitionPage(
              key: ValueKey('page-moderation'),
              child: ModerationPage(),
            ),
          ),
        ],
      ),
    ],
  );
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key, required this.session});

  final AdminSession session;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router = buildAdminRouter(widget.session);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kalia Admin',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(),
      routerConfig: _router,
    );
  }
}
