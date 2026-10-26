import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/widgets/journal_character.dart';
import '../data/profile_store.dart';
import '../data/reminder_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: IconButton.filledTonal(
              style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerLowest),
              tooltip: 'Back to Profile',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/profile'),
              icon: const Icon(Icons.chevron_left)),
          title: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800))),
      body: SafeArea(child: PageContent(children: children)));
}

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(remindersProvider);
    final t = Theme.of(context);
    Future<void> update(String key, Object value) async {
      final ok = await ref.read(remindersProvider.notifier).update(key, value);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not save reminder preferences. Please try again.')));
      }
    }

    Widget toggle(String title, String subtitle, String key, bool value) =>
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title,
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            subtitle: Text(subtitle, style: t.textTheme.bodySmall),
            value: value,
            onChanged: (v) => update(key, v));
    return SettingsPage(title: 'Reminders', children: [
      Text('PREVIEW', style: t.textTheme.labelSmall),
      const SizedBox(height: 8),
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: t.colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const JournalCharacter(width: 42, height: 52),
            const SizedBox(width: 8),
            Expanded(
                child: DefaultTextStyle(
                    style: t.textTheme.bodySmall!
                        .copyWith(color: t.colorScheme.onInverseSurface),
                    child: Text(
                        'Daystick                                      20:00\nHey ${ref.watch(profileProvider).name}, how did today go? One tap to write it down.')))
          ])),
      const SizedBox(height: 12),
      Text(
          'Preferences are saved on this device. Device notifications are not connected yet.',
          style: t.textTheme.bodySmall),
      const SizedBox(height: 20),
      Text('DAILY', style: t.textTheme.labelSmall),
      const SizedBox(height: 8),
      ScrapbookPanel(
          child: Column(children: [
        toggle('Morning Top 3', 'Pick today\'s 3 things - 07:00', 'morning',
            p.morning),
        const Divider(height: 1),
        toggle('Evening check-in', 'A little journal time - 20:00', 'evening',
            p.evening),
        const Divider(height: 1),
        toggle('Schedule alerts', 'Use each event\'s reminder time', 'schedule',
            p.schedule)
      ])),
      const SizedBox(height: 20),
      Text('GENTLE NUDGES', style: t.textTheme.labelSmall),
      const SizedBox(height: 8),
      ScrapbookPanel(
          child: Column(children: [
        toggle('Nudge when I\'m stuck', 'A tiny first step', 'nudge', p.nudge),
        const Divider(height: 1),
        toggle(
            'Streak saver', 'A gentle check-in at 21:30', 'streak', p.streak),
        const Divider(height: 1),
        toggle('Sunday weekly review', 'Three quick questions - 19:00',
            'sunday', p.sunday)
      ])),
      const SizedBox(height: 12),
      ScrapbookPanel(
          child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quiet hours'),
              subtitle: Text(MediaQuery.textScalerOf(context).scale(14) > 20
                  ? 'No reminders while you rest\n${_time(p.quietStart)} - ${_time(p.quietEnd)}'
                  : 'No reminders while you rest'),
              trailing: MediaQuery.textScalerOf(context).scale(14) > 20
                  ? null
                  : Text('${_time(p.quietStart)} - ${_time(p.quietEnd)}',
                      style: t.textTheme.labelSmall
                          ?.copyWith(color: t.colorScheme.primary)),
              onTap: () async {
                final start = await showTimePicker(
                    context: context,
                    helpText: 'Quiet hours start',
                    initialTime: TimeOfDay(
                        hour: p.quietStart ~/ 60, minute: p.quietStart % 60));
                if (start == null || !context.mounted) return;
                final end = await showTimePicker(
                    context: context,
                    helpText: 'Quiet hours end',
                    initialTime: TimeOfDay(
                        hour: p.quietEnd ~/ 60, minute: p.quietEnd % 60));
                if (end != null) {
                  await update('quietStart', start.hour * 60 + start.minute);
                  await update('quietEnd', end.hour * 60 + end.minute);
                }
              }))
    ]);
  }

  String _time(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SettingsPage(title: 'Privacy & security', children: [
      Text('APP LOCK', style: t.textTheme.labelSmall),
      const SizedBox(height: 8),
      const ScrapbookPanel(
          child: Column(children: [
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Lock Daystick'),
            subtitle: Text('PIN and biometrics are not connected.'),
            value: false,
            onChanged: null),
        Divider(height: 1),
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Auto-lock'),
            subtitle: Text('Requires device app lock'),
            trailing: Icon(Icons.chevron_right),
            enabled: false)
      ])),
      const SizedBox(height: 24),
      Text('YOUR DATA', style: t.textTheme.labelSmall),
      const SizedBox(height: 8),
      const ScrapbookPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your journal stays with you',
            style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text(
            'Notes, schedules, completed focus sessions and preferences are saved locally on this device. Cloud sync, account backup and encryption are not connected. No journal content is sent to an AI service.')
      ])),
      const SizedBox(height: 24),
      const OutlinedButton(
          onPressed: null, child: Text('Download my data - coming later')),
      const SizedBox(height: 8),
      const Text('There is no connected account to delete.',
          textAlign: TextAlign.center)
    ]);
  }
}

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String query = '';
  static const questions = {
    'How does Top 3 work?':
        'Home shows the first three checklist items saved for the selected date. Check them off there or open the checklist to edit it. Unfinished items stay on their original date.',
    'What does Puti do with my journals?':
        'Puti is your visual companion. Your entries are saved on this device and are not processed by AI.',
    'How do I share to WA Status?':
        'The story preview helps you review a day, week or month. Direct social sharing and exported images are not connected yet.',
    'Can I use Daystick offline?':
        'Local journaling works offline after the app is installed. There is no cloud backup in this build.',
    'How do I change my theme or buddy?':
        'Open Profile, then Themes & Appearance. Sweet Pastel, Calm & Natural and Midnight are available. Puti is the current buddy.'
  };
  @override
  Widget build(BuildContext context) =>
      SettingsPage(title: 'Help & about', children: [
        const Row(children: [
          JournalCharacter(width: 48, height: 64),
          SizedBox(width: 12),
          Expanded(
              child: ScrapbookPanel(
                  child: Text('Hi! What can I help with?',
                      style: TextStyle(fontWeight: FontWeight.w700))))
        ]),
        const SizedBox(height: 16),
        TextField(
            onChanged: (v) => setState(() => query = v.toLowerCase()),
            decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                hintText: 'Search questions',
                prefixIcon: const Icon(Icons.search))),
        const SizedBox(height: 12),
        ScrapbookPanel(
            child: Column(children: [
          for (final q in questions.entries.where(
              (q) => '${q.key} ${q.value}'.toLowerCase().contains(query)))
            ExpansionTile(
                key: ValueKey(q.key),
                tilePadding: EdgeInsets.zero,
                title: Text(q.key,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                children: [
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(q.value))
                ])
        ])),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonal(
              onPressed: () => feedback(context, 'Send feedback'),
              child: const Text('Send feedback')),
          FilledButton.tonal(
              onPressed: () => feedback(context, 'Report a problem'),
              child: const Text('Report a problem'))
        ]),
        const SizedBox(height: 40),
        TextButton(
            onPressed: () => context.push('/welcome'),
            child: const Text('App introduction')),
        TextButton(
            onPressed: () => context.push('/account/login'),
            child: const Text('Account preview')),
        const Text('Daystick - local preview\nMade with care',
            textAlign: TextAlign.center),
        TextButton(
            onPressed: () =>
                showLicensePage(context: context, applicationName: 'Daystick'),
            child: const Text('Open-source licenses'))
      ]);
  void feedback(BuildContext context, String title) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                          hintText: 'Write your message')),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: controller.text));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Message copied. No feedback service is connected.')));
                        }
                      },
                      child: const Text('Copy message'))
                ]))).whenComplete(controller.dispose);
  }
}
