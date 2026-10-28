import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/journal_character.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../settings/data/profile_store.dart';
import '../../themes/data/appearance_store.dart';
import '../../../core/design/app_theme.dart';

/// Optional introduction. Local journaling remains available without an account.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, bounds) => SingleChildScrollView(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: bounds.maxHeight),
                      child: IntrinsicHeight(
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(children: [
                                        const Spacer(),
                                        CircleAvatar(
                                            radius: 100,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            child: const JournalCharacter(
                                                width: 180, height: 200)),
                                        const SizedBox(height: 28),
                                        Text('Daystick',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800)),
                                        const SizedBox(height: 12),
                                        const Text(
                                            'Plan a little, write a little, and do one small thing every day. Pelan-pelan, tapi pasti.',
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 20),
                                        const Text('? ? ?',
                                            style: TextStyle(letterSpacing: 4)),
                                        const Spacer(),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                                onPressed: () =>
                                                    context.push('/onboarding'),
                                                child:
                                                    const Text('Get started'))),
                                        TextButton(
                                            onPressed: () =>
                                                context.push('/account/login'),
                                            child: const Text(
                                                'I already have an account')),
                                        TextButton(
                                            onPressed: () =>
                                                context.go('/calendar'),
                                            child: const Text(
                                                'Continue with local journal'))
                                      ]))))))))));
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int step = 1;
  late final name = TextEditingController(text: ref.read(profileProvider).name);
  final selected = <String>{};
  String checkIn = 'Evening';
  bool saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    setState(() => saving = true);
    final profile = ref.read(profileProvider);
    try {
      await ref.read(profileProvider.notifier).save(LocalProfile(
          name: name.text.trim().isEmpty ? 'Journal keeper' : name.text.trim(),
          bio: profile.bio,
          email: profile.email,
          buddyAvatar: profile.buddyAvatar));
      if (mounted) context.go('/calendar');
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Could not save. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                tooltip: 'Back',
                onPressed: () =>
                    step == 2 ? setState(() => step = 1) : context.pop(),
                icon: const Icon(Icons.chevron_left)),
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STEP $step OF 2', style: t.textTheme.labelSmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: step / 2, color: t.colorScheme.primary)
            ]),
            actions: [
              TextButton(
                  onPressed: () => context.go('/calendar'),
                  child: const Text('Skip'))
            ]),
        body: SafeArea(
            child: PageContent(children: [
          if (step == 1) ...[
            Text('What should Puti call you?',
                style: t.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(
                    hintText: 'Your name', counterText: '')),
            const SizedBox(height: 24),
            Text('What do you want to improve?',
                style: t.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Text('Pick any. Keep your own small goals in mind.'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final goal in [
                'Study',
                'Work',
                'Habits',
                'Health',
                'Less phone'
              ])
                FilterChip(
                    label: Text(goal),
                    selected: selected.contains(goal),
                    onSelected: (v) => setState(
                        () => v ? selected.add(goal) : selected.remove(goal)))
            ]),
            const SizedBox(height: 24),
            Text('When should Puti check in?',
                style: t.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final period in ['Morning', 'Evening', 'Both'])
                ChoiceChip(
                    label: Text(period),
                    selected: checkIn == period,
                    onSelected: (_) => setState(() => checkIn = period))
            ]),
            const SizedBox(height: 12),
            const Text(
                'Goal and check-in choices are a preview. Device reminders are not connected.')
          ],
          if (step == 2) ...[
            ScrapbookPanel(
                child: Text(
                    'Hi ${name.text.trim().isEmpty ? 'there' : name.text.trim()}! I’m Puti. I’ll help you take one small step every day, and cheer when you do.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleSmall)),
            const Center(child: JournalCharacter(width: 160, height: 200)),
            const SizedBox(height: 16),
            Text('Pick a look',
                style: t.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final option in JournalTheme.values)
                ChoiceChip(
                    label: Text(option.label),
                    selected: appearance.theme == option,
                    onSelected: (_) async {
                      final ok = await ref
                          .read(appearanceProvider.notifier)
                          .update(appearance.copyWith(theme: option));
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Could not save your theme. Please try again.')));
                      }
                    })
            ]),
            const SizedBox(height: 20),
            const ScrapbookPanel(
                child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Allow gentle reminders'),
                    subtitle:
                        Text('Device notifications are not connected yet.'),
                    value: false,
                    onChanged: null))
          ],
          if (error != null)
            Text(error!, style: TextStyle(color: t.colorScheme.error))
        ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                    onPressed: saving
                        ? null
                        : step == 1
                            ? () => setState(() => step = 2)
                            : finish,
                    child: Text(saving
                        ? 'Saving…'
                        : step == 1
                            ? 'Continue'
                            : 'Let’s start')))));
  }
}
