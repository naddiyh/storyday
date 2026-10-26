import '../features/onboarding/presentation/introduction_pages.dart';
import '../features/calendar/presentation/day_detail_page.dart';
import '../features/sharing/presentation/story_page.dart';
import '../features/settings/presentation/preference_pages.dart';
import '../features/settings/presentation/profile_edit_screen.dart';
import '../features/planner/presentation/focus_pages.dart';
import '../features/planner/presentation/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/notes/presentation/create_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/recap/presentation/recap_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/themes/presentation/themes_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/calendar',
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/calendar'),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/calendar', builder: (_, __) => const CalendarScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (_, __) => const SearchScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/recap', builder: (_, __) => const RecapScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(
                      path: 'edit',
                      builder: (_, __) => const ProfileEditScreen())
                ])
          ]),
        ],
      ),
      GoRoute(
          path: '/create',
          builder: (_, __) =>
              const Scaffold(body: SafeArea(child: CreateScreen()))),
      GoRoute(
          path: '/themes',
          builder: (context, __) => Scaffold(
              appBar: AppBar(
                  leading: IconButton(
                      tooltip: 'Back to Profile',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/profile')),
                  title: const Text('Themes & Appearance',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 20))),
              body: const SafeArea(child: ThemesScreen()))),
      GoRoute(
          path: '/schedule',
          builder: (_, state) =>
              SchedulePage(id: state.uri.queryParameters['id'])),
      GoRoute(path: '/focus/setup', builder: (_, __) => const FocusSetupPage()),
      GoRoute(path: '/focus', builder: (_, __) => const FocusPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(
          path: '/account/:mode',
          builder: (_, s) => AccountPage(mode: s.pathParameters['mode']!)),
      GoRoute(path: '/day', builder: (_, __) => const DayDetailPage()),
      GoRoute(path: '/story', builder: (_, __) => const StoryPage()),
      GoRoute(path: '/reminders', builder: (_, __) => const RemindersPage()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPage()),
      GoRoute(path: '/help', builder: (_, __) => const HelpPage()),
      GoRoute(path: '/settings', redirect: (_, __) => '/profile'),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
          child: FilledButton(
        onPressed: () => context.go('/calendar'),
        child: const Text('Go to calendar'),
      )),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
