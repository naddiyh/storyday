import '../../planner/domain/planner.dart';
import '../../../core/widgets/journal_navigation_bar.dart';
import '../../../app/create_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/widgets/journal_character.dart';
import '../../notes/data/note_repository.dart';
import '../data/planner_store.dart';
import '../domain/focus_controller.dart';

class FocusSetupPage extends ConsumerStatefulWidget {
  const FocusSetupPage({super.key});
  @override
  ConsumerState<FocusSetupPage> createState() => _FocusSetupPageState();
}

class _FocusSetupPageState extends ConsumerState<FocusSetupPage> {
  int _selected = 0, _minutes = 25;
  final _custom = TextEditingController();
  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> customDuration() async {
    var entered = '$_minutes';
    final form = GlobalKey<FormState>();
    final value = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Focus duration'),
                content: Form(
                    key: form,
                    child: TextFormField(
                        initialValue: entered,
                        onChanged: (value) => entered = value,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Minutes (1–180)'),
                        validator: (text) {
                          final value = int.tryParse(text ?? '');
                          return value == null || value < 1 || value > 180
                              ? 'Enter 1–180 minutes'
                              : null;
                        })),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(context, int.parse(entered));
                        }
                      },
                      child: const Text('Set duration'))
                ]));
    if (value != null && mounted) setState(() => _minutes = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = ref
        .watch(ordinaryNotesProvider)
        .expand((n) => n.checklist)
        .where((t) => !t.done)
        .map((t) => t.text)
        .where((s) => s.trim().isNotEmpty)
        .take(2)
        .toList();
    final tasks = [
      for (var i = 0; i < 2; i++)
        i < pending.length
            ? pending[i]
            : i == 0
                ? 'Open the doc, write 3 sentences'
                : 'Read 10 pages'
    ];
    final task = _selected == 2 ? _custom.text.trim() : tasks[_selected];
    final active = ref.watch(focusProvider);
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Close focus setup',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/calendar'),
              icon: const Icon(Icons.chevron_left)),
          centerTitle: true,
          title: Text('STEP 1 OF 2', style: theme.textTheme.labelSmall)),
      body: SafeArea(
          child: PageContent(children: [
        const ScrapbookHeader(
            title: 'Start a focus\nsession',
            subtitle: 'Pick one thing. Just one.'),
        if (active != null && !active.saved) ...[
          ScrapbookPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('A session is already in progress',
                    style: theme.textTheme.titleSmall),
                Text(active.task),
                const SizedBox(height: 8),
                FilledButton(
                    onPressed: () => context.replace('/focus'),
                    child: const Text('Return to session'))
              ])),
          const SizedBox(height: 16),
        ],
        ScrapbookPanel(
            child: Column(children: [
          for (var i = 0; i < 3; i++) ...[
            RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                value: i,
                groupValue: _selected,
                onChanged: (value) => setState(() => _selected = value!),
                title: Text(i == 2 ? 'Something else…' : tasks[i],
                    style: theme.textTheme.titleSmall),
                subtitle: Text(
                    i == 2
                        ? 'Type a new task'
                        : pending.contains(tasks[i])
                            ? 'From your checklist'
                            : 'A small place to start',
                    style: theme.textTheme.bodySmall)),
            if (i < 2) const Divider(height: 1),
          ],
          if (_selected == 2)
            TextField(
                controller: _custom,
                onChanged: (_) => setState(() {}),
                maxLength: 120,
                decoration:
                    const InputDecoration(labelText: 'Your focus task')),
        ])),
        const SizedBox(height: 20),
        Text('How long?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final value in [15, 25, 45])
            ChoiceChip(
                label: Text('${value}m'),
                selected: value == _minutes,
                onSelected: (_) => setState(() => _minutes = value)),
          ActionChip(
              label: Text([15, 25, 45].contains(_minutes)
                  ? 'Custom'
                  : '${_minutes}m · Custom'),
              onPressed: customDuration),
        ]),
        const SizedBox(height: 20),
        Text('Background sound', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final label in ['Off', 'Rain', 'Café', 'Lo-fi'])
            ChoiceChip(
                label: Text(label),
                selected: label == 'Off',
                onSelected: label == 'Off' ? (_) {} : null)
        ]),
        const SizedBox(height: 6),
        Text('Ambient audio is not available in this build.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        const ScrapbookPanel(
            child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: false,
                onChanged: null,
                title: Text('Do not disturb'),
                subtitle: Text(
                    'System notification controls need native device integration.'))),
        const SizedBox(height: 28),
        FilledButton(
            onPressed: task.isEmpty || active != null && !active.saved
                ? null
                : () {
                    ref.read(focusProvider.notifier).start(task, _minutes);
                    context.replace('/focus');
                  },
            child: Text('Start $_minutes min with your buddy')),
      ])),
    );
  }
}

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(focusProvider);
    if (session == null) return const FocusSetupPage();
    if (session.completed && session.saved) {
      return _FocusComplete(session: session);
    }
    final theme = Theme.of(context);
    final total = ref
        .watch(plannerProvider)
        .focusRecords
        .where((r) => DateUtils.isSameDay(r.date, DateTime.now()))
        .fold<int>(0, (sum, r) => sum + r.elapsedSeconds);
    final progress = session.completed
        ? 1.0
        : (session.elapsed.inMilliseconds /
                Duration(minutes: session.minutes).inMilliseconds)
            .clamp(0.0, 1.0);
    return Scaffold(
      bottomNavigationBar: JournalNavigationBar(onSelect: (index) {
        if (index == 2) {
          openCreatePage(context);
        } else {
          context.go(
              ['/calendar', '/search', '/create', '/recap', '/profile'][index]);
        }
      }),
      body: SafeArea(
          child: PageContent(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Focus',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -1)),
                Text(
                    'Session ${ref.watch(plannerProvider).focusRecords.where((r) => DateUtils.isSameDay(r.date, session.startedAt)).length + (session.saved ? 0 : 1)} - ${session.minutes} min',
                    style: theme.textTheme.bodySmall),
              ])),
          Chip(
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              label: Text('${total ~/ 60}m today',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 20),
        Center(
            child: Chip(
                backgroundColor: theme.colorScheme.surfaceContainerLowest,
                label: Text(session.completed
                    ? 'One small step, well done.'
                    : 'Ready when you are. Just 5 minutes?'))),
        const SizedBox(height: 24),
        Center(
            child: SizedBox(
                width: 252,
                height: 252,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        shape: BoxShape.circle),
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(
                          child: CircularProgressIndicator(
                              value: progress,
                              color: theme.colorScheme.primary,
                              strokeWidth: 12,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              strokeCap: StrokeCap.round)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        const JournalCharacter(width: 130, height: 150),
                        Text(
                            session.completed
                                ? 'Completed'
                                : session.running
                                    ? 'Focusing'
                                    : 'Paused',
                            style: theme.textTheme.labelMedium)
                      ]),
                    ])))),
        const SizedBox(height: 28),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(session.clockLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.1))),
        const SizedBox(height: 20),
        ScrapbookPanel(
            child: ActivityTile(
                icon: Icons.check_circle_outline,
                title: 'Now working on',
                subtitle: session.task)),
        const SizedBox(height: 16),
        if (session.error != null) ...[
          Text(session.error!,
              style: TextStyle(color: theme.colorScheme.error)),
          FilledButton(
              onPressed: () => ref.read(focusProvider.notifier).finish(),
              child: const Text('Retry save'))
        ] else if (session.completed)
          FilledButton(
              onPressed:
                  session.saved ? () => context.replace('/focus/setup') : null,
              child: Text(
                  session.saved ? 'Start another session' : 'Saving session…'))
        else
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: () => session.running
                    ? ref.read(focusProvider.notifier).pause()
                    : ref.read(focusProvider.notifier).resume(),
                icon: Icon(session.running ? Icons.pause : Icons.play_arrow),
                label: Text(session.running ? 'Pause focus' : 'Resume focus')),
            OutlinedButton(
                onPressed: () => ref.read(focusProvider.notifier).finish(),
                child: const Text('Step done')),
          ]),
      ])),
    );
  }
}

class _FocusComplete extends ConsumerWidget {
  const _FocusComplete({required this.session});
  final FocusSnapshot session;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final records = ref
        .watch(plannerProvider)
        .focusRecords
        .where((r) => DateUtils.isSameDay(r.date, session.startedAt));
    final seconds = records.fold<int>(0, (sum, r) => sum + r.elapsedSeconds);
    return Scaffold(
        body: SafeArea(
            child: PageContent(children: [
          const SizedBox(height: 28),
          Center(
              child: CircleAvatar(
                  radius: 100,
                  backgroundColor: t.colorScheme.surfaceContainerLowest,
                  child: const JournalCharacter(width: 170, height: 190))),
          const SizedBox(height: 24),
          Text(
              '${FocusRecord.durationLabel(session.elapsed.inSeconds)} focused!',
              textAlign: TextAlign.center,
              style: t.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'You showed up. That?s the hardest part.\nPuti is proud of you.',
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ScrapbookPanel(
              child: ActivityTile(
                  icon: Icons.check_circle,
                  title: 'One small step complete',
                  subtitle: session.task)),
          const SizedBox(height: 16),
          ScrapbookPanel(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                Column(children: [
                  Text(FocusRecord.durationLabel(seconds),
                      style: t.textTheme.titleLarge),
                  const Text('focus today')
                ]),
                Column(children: [
                  Text('${records.length}', style: t.textTheme.titleLarge),
                  const Text('sessions')
                ])
              ]))
        ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                          onPressed: () => context.replace('/focus/setup'),
                          child: const Text('Choose the next small step')),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: () => context.go('/calendar'),
                          child: const Text('Done for now'))
                    ]))));
  }
}
