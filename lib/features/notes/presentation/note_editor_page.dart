import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../sharing/presentation/story_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';
import 'package:uuid/uuid.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({
    super.key,
    required this.date,
    required this.kind,
    this.initial,
  });

  final DateTime date;
  final NoteKind kind;
  final OrdinaryNote? initial;

  @override
  ConsumerState<NoteEditorPage> createState() => NoteEditorPageState();
}

class NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late NoteKind _kind;
  bool _saving = false;
  late final String _noteId;
  bool bold = false, italic = false, underline = false;
  double fontSize = 15;
  String category = 'To-do';
  final List<String> stickers = [];
  final List<bool> _done = [];
  final List<TextEditingController> _checklistControllers = [
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _noteId = widget.initial?.id ?? const Uuid().v4();
    _kind = widget.kind;
    bold = widget.initial?.bold ?? false;
    italic = widget.initial?.italic ?? false;
    underline = widget.initial?.underline ?? false;
    fontSize = widget.initial?.fontSize ?? 15;
    category = widget.initial?.category ?? 'To-do';
    stickers.addAll(widget.initial?.stickers ?? []);
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _bodyController = TextEditingController(text: widget.initial?.body ?? '');
    final items = widget.initial?.checklist ?? const <ChecklistItem>[];
    if (items.isNotEmpty) {
      for (final controller in _checklistControllers) {
        controller.dispose();
      }
      _checklistControllers
        ..clear()
        ..addAll(items.map((item) => TextEditingController(text: item.text)));
    }
    _done.addAll(items.isEmpty ? [false] : items.map((item) => item.done));
    if (_checklistControllers.isEmpty) {
      _checklistControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    for (final controller in _checklistControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final checklist = <ChecklistItem>[
        for (var i = 0; i < _checklistControllers.length; i++)
          if (_checklistControllers[i].text.trim().isNotEmpty)
            ChecklistItem(
                text: _checklistControllers[i].text.trim(), done: _done[i]),
      ];

      final kind = _kind == NoteKind.mixed ||
              (_kind == NoteKind.journal &&
                  body.isNotEmpty &&
                  checklist.isNotEmpty)
          ? NoteKind.mixed
          : _kind;

      final note = OrdinaryNote(
        bold: bold,
        italic: italic,
        underline: underline,
        fontSize: fontSize,
        stickers: List.of(stickers),
        category: category,
        id: _noteId,
        date: widget.date,
        kind: kind,
        title: title.isEmpty
            ? (kind == NoteKind.checklist ? 'Checklist' : 'Journal note')
            : title,
        body: body,
        checklist: checklist,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(ordinaryNotesProvider.notifier).save(note);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not save. Your draft is still here. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addChecklistItem() {
    setState(() {
      _checklistControllers.add(TextEditingController());
      _done.add(false);
    });
  }

  void _removeChecklistItem(int index) {
    if (_checklistControllers.length <= 1) {
      _checklistControllers.first.text = '';
      _done[0] = false;
      return;
    }
    setState(() {
      _done.removeAt(index);
      final controller = _checklistControllers.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> textStyle() async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, refresh) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('Text style',
                                    style: Theme.of(ctx).textTheme.titleLarge)),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Done'))
                          ]),
                          Wrap(spacing: 8, children: [
                            FilterChip(
                                label: const Text('B',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800)),
                                selected: bold,
                                onSelected: (v) {
                                  setState(() => bold = v);
                                  refresh(() {});
                                }),
                            FilterChip(
                                label: const Text('I',
                                    style:
                                        TextStyle(fontStyle: FontStyle.italic)),
                                selected: italic,
                                onSelected: (v) {
                                  setState(() => italic = v);
                                  refresh(() {});
                                }),
                            FilterChip(
                                label: const Text('U',
                                    style: TextStyle(
                                        decoration: TextDecoration.underline)),
                                selected: underline,
                                onSelected: (v) {
                                  setState(() => underline = v);
                                  refresh(() {});
                                }),
                            ActionChip(
                                label: Text(_kind == NoteKind.mixed
                                    ? 'Mixed content'
                                    : 'Add checklist'),
                                onPressed: () {
                                  setState(() => _kind = _kind == NoteKind.mixed
                                      ? NoteKind.journal
                                      : NoteKind.mixed);
                                  refresh(() {});
                                })
                          ]),
                          Row(children: [
                            const Text('Text size'),
                            Expanded(
                                child: Slider(
                                    value: fontSize,
                                    min: 12,
                                    max: 24,
                                    divisions: 12,
                                    label: '${fontSize.round()}',
                                    onChanged: (v) {
                                      setState(() => fontSize = v);
                                      refresh(() {});
                                    })),
                            Text('${fontSize.round()}')
                          ])
                        ])))));
  }

  Future<void> stickerPicker() async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Stickers',
                                style: Theme.of(ctx).textTheme.titleLarge)),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Done'))
                      ]),
                      const Text(
                          'Tap a sticker to add it. Up to 12 per journal.'),
                      const SizedBox(height: 12),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        for (final item in stickerIcons.entries)
                          IconButton.filledTonal(
                              tooltip: item.key,
                              onPressed: stickers.length >= 12
                                  ? null
                                  : () {
                                      setState(() => stickers.add(item.key));
                                      Navigator.pop(ctx);
                                    },
                              icon: Icon(item.value)),
                        IconButton.filledTonal(
                            tooltip: 'Jasmine',
                            onPressed: stickers.length >= 12
                                ? null
                                : () {
                                    setState(() => stickers.add('Jasmine'));
                                    Navigator.pop(ctx);
                                  },
                            icon: Image.asset('assets/stickers/jasmine.png',
                                width: 24, height: 24))
                      ])
                    ]))));
  }

  static const stickerIcons = {
    'Star': Icons.star_outline,
    'Heart': Icons.favorite_outline,
    'Sun': Icons.wb_sunny_outlined,
    'Cloud': Icons.cloud_outlined,
    'Coffee': Icons.coffee_outlined,
    'Book': Icons.menu_book_outlined,
    'Leaf': Icons.eco_outlined,
    'Moon': Icons.dark_mode_outlined
  };
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final showChecklist = _kind != NoteKind.journal;
    final showBody = _kind != NoteKind.checklist;
    final done = _done.where((v) => v).length;
    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 72 * MediaQuery.textScalerOf(context).scale(14) / 14,
            leading: IconButton.filledTonal(
                style: IconButton.styleFrom(
                    backgroundColor: t.colorScheme.surfaceContainerLowest),
                tooltip: 'Cancel',
                onPressed: _saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20)),
            centerTitle: true,
            title: Column(children: [
              Text(
                  _kind == NoteKind.checklist
                      ? 'New checklist'
                      : _kind == NoteKind.mixed
                          ? 'Mixed note'
                          : 'New journal',
                  style: t.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(DateFormat.yMMMEd().format(widget.date),
                  style: t.textTheme.labelSmall)
            ]),
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: const Text(
                          bool.fromEnvironment('UI_REFERENCE_REVIEW')
                              ? 'Save'
                              : 'Save note')))
            ]),
        bottomNavigationBar: showBody
            ? SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(children: [
                      for (final item in {
                        'Format': Icons.text_fields,
                        'Photo': Icons.photo_outlined,
                        'Sticker': Icons.emoji_emotions_outlined,
                        'Voice': Icons.mic_none,
                        'Story': Icons.ios_share
                      }.entries)
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Tooltip(
                                    message: item.key == 'Photo' ||
                                            item.key == 'Voice'
                                        ? '${item.key} capture is not connected'
                                        : item.key,
                                    child: TextButton(
                                        style: TextButton.styleFrom(
                                            backgroundColor: t.colorScheme
                                                .surfaceContainerLowest,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 2)),
                                        onPressed: switch (item.key) {
                                          'Format' => textStyle,
                                          'Sticker' => stickerPicker,
                                          'Story' => () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                  builder: (_) => StoryPage(
                                                      note: OrdinaryNote(
                                                          id: 'draft',
                                                          date: widget.date,
                                                          kind: _kind,
                                                          title: _titleController
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty
                                                              ? 'A little moment'
                                                              : _titleController
                                                                  .text,
                                                          body: _bodyController
                                                              .text,
                                                          checklist: const [],
                                                          createdAt:
                                                              DateTime.now(),
                                                          updatedAt: DateTime
                                                              .now())))),
                                          _ => null
                                        },
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(item.value, size: 20),
                                              Text(item.key,
                                                  style: t.textTheme.labelSmall)
                                            ])))))
                    ])))
            : null,
        body: SafeArea(
            child: PageContent(children: [
          if (_kind == NoteKind.checklist) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final name in ['To-do', 'Shopping', 'Packing', 'Habit'])
                ChoiceChip(
                    label: Text(name),
                    selected: category == name,
                    onSelected: (_) => setState(() => category = name))
            ]),
            const SizedBox(height: 12)
          ],
          ScrapbookPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                TextField(
                    controller: _titleController,
                    style: t.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8))),
                if (showBody) ...[
                  TextField(
                      controller: _bodyController,
                      minLines: 12,
                      maxLines: null,
                      style: t.textTheme.bodyLarge?.copyWith(
                          fontSize: fontSize,
                          height: 1.6,
                          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                          fontStyle:
                              italic ? FontStyle.italic : FontStyle.normal,
                          decoration:
                              underline ? TextDecoration.underline : null),
                      decoration: const InputDecoration(
                          hintText: 'Write a little about your day...',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8))),
                  if (stickers.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (var i = 0; i < stickers.length; i++)
                        InputChip(
                            avatar: stickers[i] == 'Jasmine'
                                ? Image.asset('assets/stickers/jasmine.png')
                                : Icon(
                                    stickerIcons[stickers[i]] ??
                                        Icons.star_outline,
                                    size: 18),
                            label: Text(stickers[i]),
                            onDeleted: () =>
                                setState(() => stickers.removeAt(i)))
                    ])
                ],
                if (showChecklist) ...[
                  Text('$done of ${_done.length} done',
                      style: t.textTheme.labelSmall?.copyWith(
                          color: t.colorScheme.primary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                      value: _done.isEmpty ? 0 : done / _done.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3)),
                  const SizedBox(height: 8),
                  for (var index = 0;
                      index < _checklistControllers.length;
                      index++)
                    Column(children: [
                      Row(children: [
                        Checkbox(
                            value: _done[index],
                            onChanged: (v) =>
                                setState(() => _done[index] = v ?? false)),
                        Expanded(
                            child: TextField(
                                controller: _checklistControllers[index],
                                decoration: InputDecoration(
                                    hintText: 'Task ${index + 1}',
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none))),
                        IconButton(
                            tooltip: 'Remove item',
                            onPressed: () => _removeChecklistItem(index),
                            icon: const Icon(Icons.close, size: 18))
                      ]),
                      const Divider(height: 1)
                    ]),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: _addChecklistItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add item')))
                ]
              ])),
          if (_kind == NoteKind.checklist) ...[
            const SizedBox(height: 16),
            const ScrapbookPanel(
                child: Column(children: [
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Today?s Top 3'),
                  subtitle: Text(
                      'The first three items appear on Home for this date'),
                  leading: Icon(Icons.checklist)),
              Divider(height: 1),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Remind me'),
                  subtitle: Text('Device reminders are not connected'),
                  leading: Icon(Icons.notifications_none),
                  enabled: false)
            ]))
          ]
        ])));
  }
}
