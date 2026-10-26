import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/page_content.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';
import 'note_editor_page.dart';
import '../../sharing/presentation/story_page.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.note});
  final OrdinaryNote note;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches =
        ref.watch(ordinaryNotesProvider).where((n) => n.id == note.id);
    final current = matches.isEmpty ? note : matches.first;
    final t = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                tooltip: 'Back to memories',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left)),
            actions: [
              IconButton(
                  tooltip: 'Edit memory',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => NoteEditorPage(
                              date: current.date,
                              kind: current.kind,
                              initial: current))),
                  icon: const Icon(Icons.edit_outlined))
            ]),
        body: SafeArea(
            child: PageContent(children: [
          Container(
              height: 160,
              decoration: BoxDecoration(
                  color: t.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(26)),
              child: Icon(
                  current.hasChecklist
                      ? Icons.checklist
                      : Icons.menu_book_outlined,
                  size: 48,
                  color: t.colorScheme.onSecondaryContainer)),
          const SizedBox(height: 20),
          Text(DateFormat('EEEE, d MMM yyyy - HH:mm').format(current.createdAt),
              style: t.textTheme.labelSmall),
          const SizedBox(height: 12),
          Text(current.title,
              style: t.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (current.body.isNotEmpty)
            SelectableText(current.body,
                style: t.textTheme.bodyLarge?.copyWith(
                    fontSize: current.fontSize,
                    height: 1.6,
                    fontWeight:
                        current.bold ? FontWeight.w700 : FontWeight.w400,
                    fontStyle:
                        current.italic ? FontStyle.italic : FontStyle.normal,
                    decoration:
                        current.underline ? TextDecoration.underline : null)),
          for (var i = 0; i < current.checklist.length; i++)
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(current.checklist[i].text),
                value: current.checklist[i].done,
                onChanged: (v) async {
                  final list = [...current.checklist];
                  list[i] = ChecklistItem(text: list[i].text, done: v ?? false);
                  try {
                    await ref
                        .read(ordinaryNotesProvider.notifier)
                        .save(current.withChecklist(list));
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Could not update this task.')));
                    }
                  }
                }),
          if (current.stickers.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final sticker in current.stickers)
                Chip(
                    avatar: sticker == 'Jasmine'
                        ? Image.asset('assets/stickers/jasmine.png')
                        : Icon(
                            NoteEditorPageState.stickerIcons[sticker] ??
                                Icons.star_outline,
                            size: 18),
                    label: Text(sticker))
            ])
        ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => NoteEditorPage(
                                      date: current.date,
                                      kind: current.kind,
                                      initial: current))),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit')),
                      FilledButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => StoryPage(note: current))),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Share')),
                      IconButton.filledTonal(
                          tooltip: 'Delete memory',
                          onPressed: () async {
                            final remove = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                        title:
                                            const Text('Delete this memory?'),
                                        content: const Text(
                                            'This removes it from this device.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Keep')),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Delete'))
                                        ]));
                            if (remove == true) {
                              try {
                                await ref
                                    .read(ordinaryNotesProvider.notifier)
                                    .delete(current.id);
                                if (context.mounted) Navigator.pop(context);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Could not delete. Your memory is still here.')));
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline))
                    ]))));
  }
}
