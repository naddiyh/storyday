import '../../../core/utils/journal_stats.dart';
import '../../../core/design/scrapbook_palette.dart';
import '../../planner/data/planner_store.dart';
import '../../planner/domain/planner.dart';
import '../data/profile_store.dart';
import 'profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../themes/data/appearance_store.dart';
import '../../notes/data/note_repository.dart';
import '../../account/presentation/cloud_account_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(ordinaryNotesProvider);
    final appearance = ref.watch(appearanceProvider);
    final profile = ref.watch(profileProvider);
    final focusSeconds = ref
        .watch(plannerProvider)
        .focusRecords
        .fold<int>(0, (sum, record) => sum + record.elapsedSeconds);
    return PageContent(children: [
      const ScrapbookHeader(title: 'Profile', subtitle: ''),
      ScrapbookPanel(
          child: Row(children: [
        ProfileAvatar(profile: profile),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(profile.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(profile.bio, style: Theme.of(context).textTheme.bodySmall),
        ])),
        IconButton.filledTonal(
            tooltip: 'Edit profile',
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined)),
      ])),
      const SizedBox(height: 12),
      Row(children: [
        for (final item in {
          'Streak': '${bestStreak(notes.map((n) => n.date))} days',
          'Entries': '${notes.length}',
          'Focus': FocusRecord.durationLabel(focusSeconds),
        }.entries)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                                  .extension<ScrapbookPalette>()!
                                  .colors[
                              {
                                    'Streak': 2,
                                    'Entries': 0,
                                    'Focus': 3
                                  }[item.key] ??
                                  0],
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.value,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(item.key,
                                style: Theme.of(context).textTheme.bodySmall)
                          ]))))
      ]),
      const SizedBox(height: 12),
      const CloudAccountPanel(),
      const SizedBox(height: 12),
      ScrapbookPanel(
          child: Column(children: [
        _Setting(
            icon: Icons.palette_outlined,
            title: 'Themes & Appearance',
            subtitle: appearance.theme.label,
            onTap: () => context.push('/themes')),
        const Divider(height: 1),
        _Setting(
            icon: Icons.notifications_outlined,
            title: 'Reminders',
            subtitle: 'Evening check-in preferences',
            onTap: () => context.push('/reminders')),
        const Divider(height: 1),
        _Setting(
            icon: Icons.lock_outline,
            title: 'Privacy & security',
            subtitle: 'Local data and privacy',
            onTap: () => context.push('/privacy')),
        const Divider(height: 1),
        _Setting(
            icon: Icons.help_outline,
            title: 'Help & about',
            subtitle: 'Version 0.1 - local preview',
            onTap: () => context.push('/help')),
      ])),
    ]);
  }

  void details(BuildContext context, String title, String message) =>
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(title),
                  content: Text(message),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'))
                  ]));
}

class _Setting extends StatelessWidget {
  const _Setting(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20)),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap);
}
