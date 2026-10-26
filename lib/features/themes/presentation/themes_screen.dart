import '../../../core/widgets/journal_character.dart';
import '../../../core/widgets/scrapbook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/widgets/page_content.dart';
import '../data/appearance_store.dart';
import '../domain/appearance.dart';

class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});
  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  bool _previewing = false;
  Future<void> save(
      BuildContext context, WidgetRef ref, Appearance next) async {
    final saved = await ref.read(appearanceProvider.notifier).update(next);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Your look changed, but could not be saved. Please try again.')));
    }
  }

  Future<void> preview(
      BuildContext context, WidgetRef ref, JournalTheme option) async {
    if (_previewing) return;
    _previewing = true;
    try {
      final current = ref.read(appearanceProvider);
      final brightness = Theme.of(context).brightness;
      final apply = await showDialog<bool>(
          context: context,
          builder: (context) => Theme(
              data: option.build(brightness: brightness),
              child: AlertDialog(
                title: Text(option.label),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(option.description),
                      const SizedBox(height: 16),
                      ThemeMiniature(option: option),
                      const SizedBox(height: 16),
                      const Text(
                          'Preview only. Apply to use this look throughout your journal.'),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Apply theme'))
                ],
              )));
      if (apply == true && context.mounted) {
        await save(context, ref, current.copyWith(theme: option));
      }
    } finally {
      _previewing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    final brightness = Theme.of(context).brightness;
    return PageContent(children: [
      Wrap(spacing: 8, children: [
        for (final mode in ThemeMode.values)
          ChoiceChip(
              label: Text(mode.name),
              selected: appearance.mode == mode,
              onSelected: (_) =>
                  save(context, ref, appearance.copyWith(mode: mode)))
      ]),
      const SizedBox(height: 20),
      Text('THEME', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      for (final option in JournalTheme.values) ...[
        Semantics(
            key: ValueKey('preview-${option.id}'),
            container: true,
            excludeSemantics: true,
            button: true,
            label: 'Preview ${option.label}. ${option.description}',
            onTap: () => preview(context, ref, option),
            selected: appearance.theme == option,
            child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: appearance.theme == option
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2)),
                child: InkWell(
                    key: ValueKey('theme-${option.id}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => preview(context, ref, option),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(
                              width: 56,
                              height: 70,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                  color: option
                                      .build(brightness: brightness)
                                      .colorScheme
                                      .surface,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: 28,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: option.seed,
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                    const SizedBox(height: 8),
                                    Container(
                                        height: 22,
                                        decoration: BoxDecoration(
                                            color: option.palette[1],
                                            borderRadius:
                                                BorderRadius.circular(5))),
                                    const SizedBox(height: 5),
                                    Row(children: [
                                      for (final color
                                          in option.palette.take(3))
                                        Expanded(
                                            child: Container(
                                                height: 7,
                                                margin: const EdgeInsets.only(
                                                    right: 2),
                                                color: color))
                                    ])
                                  ])),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(option.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(option.description,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)
                              ])),
                          const SizedBox(width: 8),
                          Icon(
                              appearance.theme == option
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: Theme.of(context).colorScheme.primary),
                        ]))))),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      Text('YOUR BUDDY', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 8),
      const ScrapbookPanel(
          child: Row(children: [
        JournalCharacter(width: 64, height: 76),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Puti', style: TextStyle(fontWeight: FontWeight.w800)),
          Text('Gentle, calm, always cheering you on.',
              style: TextStyle(fontSize: 11))
        ]))
      ])),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final name in ['Lumi', 'Miso', 'Pip', 'Bumi', 'Nori'])
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(children: [
                    Container(
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(.35)),
                            borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.lock_outline,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(name, style: Theme.of(context).textTheme.labelSmall),
                  ]))),
      ]),
      const SizedBox(height: 16),
      Card(
          child: SwitchListTile.adaptive(
              title: const Text('Calendar decorations'),
              subtitle: const Text('Show your chosen stickers.'),
              value: appearance.decorated,
              onChanged: (value) =>
                  save(context, ref, appearance.copyWith(decorated: value)))),
    ]);
  }
}

/// A real, themed widget preview, not an image or a second application screen.
class ThemeMiniature extends StatelessWidget {
  const ThemeMiniature({super.key, required this.option});
  final JournalTheme option;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
                option == JournalTheme.lavender
                    ? Icons.local_florist_outlined
                    : option == JournalTheme.sage
                        ? Icons.eco_outlined
                        : Icons.nightlight_round,
                color: colors.primary,
                size: 20),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text('A moment for you', style: theme.textTheme.titleSmall))
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (final day in [12, 13, 14, 15, 16])
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                          color: day == 14
                              ? colors.primaryContainer
                              : colors.surface,
                          borderRadius: BorderRadius.circular(
                              option == JournalTheme.lavender ? 12 : 4)),
                      child: Center(
                          child: Text('$day',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: day == 14
                                      ? colors.onPrimaryContainer
                                      : colors.onSurface)))))
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.checklist, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Little things to remember',
                    style: theme.textTheme.bodySmall))
          ]),
        ]));
  }
}
