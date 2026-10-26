import '../../../core/design/scrapbook_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/journal_character.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/domain/note.dart';
import '../../memories/demo_memories.dart';

class StoryPage extends ConsumerStatefulWidget {
  const StoryPage({super.key, this.note});
  final OrdinaryNote? note;
  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage> {
  String period = 'Today';
  bool watermark = true;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final DateTime date =
        widget.note?.date ?? ref.watch<DateTime>(selectedDateProvider);
    final notes = widget.note == null
        ? ref.watch(ordinaryNotesProvider).where((n) => period == 'Today'
            ? DateUtils.isSameDay(n.date, date)
            : period == 'Month'
                ? n.date.year == date.year && n.date.month == date.month
                : !n.date.isBefore(DateUtils.dateOnly(date)
                        .subtract(Duration(days: date.weekday - 1))) &&
                    !n.date.isAfter(DateUtils.dateOnly(date)
                        .add(Duration(days: 7 - date.weekday))))
        : [widget.note!];
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                tooltip: 'Close story',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/recap'),
                icon: const Icon(Icons.close)),
            centerTitle: true,
            title: Text('Share to status',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800))),
        body: SafeArea(
            child: PageContent(children: [
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 216),
                  child: AspectRatio(
                      aspectRatio: 9 /
                          (16 *
                              (MediaQuery.textScalerOf(context).scale(14) / 14)
                                  .clamp(1, 3)),
                      child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: t.extension<ScrapbookPalette>()!.colors[5],
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                    color: t.shadowColor.withOpacity(.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8))
                              ]),
                          child: DefaultTextStyle(
                              style: t.textTheme.bodyMedium!
                                  .copyWith(color: t.colorScheme.onSurface),
                              child: Column(children: [
                                Text(
                                    DateFormat('EEE - d MMM yyyy')
                                        .format(date)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 20),
                                Expanded(
                                    child: Transform.rotate(
                                        angle: -.04,
                                        child: Container(
                                            padding: const EdgeInsets.all(12),
                                            color: t.colorScheme
                                                .surfaceContainerLowest,
                                            child: Column(children: [
                                              const Expanded(
                                                  child: Center(
                                                      child: JournalCharacter(
                                                          width: 130,
                                                          height: 160))),
                                              const SizedBox(height: 8),
                                              Text(
                                                  notes.isEmpty
                                                      ? 'A little moment to remember'
                                                      : notes.first.title,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: t.textTheme.titleMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800))
                                            ])))),
                                const SizedBox(height: 20),
                                Text(
                                    '${notes.length} ${notes.length == 1 ? 'memory' : 'memories'} - ${period.toLowerCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 24),
                                if (watermark)
                                  const Text('made with Daystick',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700))
                              ])))))),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            for (final p in ['Today', 'This week', 'Month'])
              ChoiceChip(
                  label: Text(p),
                  selected: period == p,
                  onSelected: (_) => setState(() => period = p))
          ]),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            for (final e in {
              'WA Status': Icons.chat_bubble_outline,
              'IG Story': Icons.camera_alt_outlined,
              'Save': Icons.download_outlined,
              'More': Icons.more_horiz
            }.entries)
              Tooltip(
                  message:
                      'Image export and external sharing are not connected',
                  child: SizedBox(
                      width: (MediaQuery.sizeOf(context).width.clamp(280, 720) -
                              80) /
                          4,
                      child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 12),
                              minimumSize: const Size(0, 60)),
                          onPressed: null,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(e.value, size: 20),
                                Text(e.key, style: t.textTheme.labelSmall)
                              ]))))
          ]),
          const SizedBox(height: 12),
          ScrapbookPanel(
              child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show “made with Daystick”'),
                  value: watermark,
                  onChanged: (v) => setState(() => watermark = v))),
          const SizedBox(height: 12),
          Text(
              'Local story preview. Image export and direct sharing are not connected yet.',
              style: t.textTheme.bodySmall,
              textAlign: TextAlign.center)
        ])));
  }
}
