import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ArchiveRange {
  const ArchiveRange(this.start, this.end);
  final DateTime? start, end;
  bool contains(DateTime day) =>
      (start == null ||
          !DateUtils.dateOnly(day).isBefore(DateUtils.dateOnly(start!))) &&
      (end == null ||
          !DateUtils.dateOnly(day).isAfter(DateUtils.dateOnly(end!)));
}

Future<ArchiveRange?> showArchiveRange(
        BuildContext context, ArchiveRange initial, List<DateTime> dates) =>
    showModalBottomSheet<ArchiveRange>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _RangeSheet(initial: initial, dates: dates));

class _RangeSheet extends StatefulWidget {
  const _RangeSheet({required this.initial, required this.dates});
  final ArchiveRange initial;
  final List<DateTime> dates;
  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late ArchiveRange range = widget.initial;
  String? selected;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final now = DateUtils.dateOnly(DateTime.now());
    final count = widget.dates.where(range.contains).length;
    return SafeArea(
        child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Show memories from',
                          style: t.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final label in [
                          'Last 7 days',
                          'This month',
                          'Last month',
                          'This year',
                          'All time'
                        ])
                          ChoiceChip(
                              label: Text(label),
                              selected: selected == label,
                              onSelected: (_) => setState(() {
                                    selected = label;
                                    range = switch (label) {
                                      'Last 7 days' => ArchiveRange(
                                          now.subtract(const Duration(days: 6)),
                                          now),
                                      'This month' => ArchiveRange(
                                          DateTime(now.year, now.month), now),
                                      'Last month' => ArchiveRange(
                                          DateTime(now.year, now.month - 1),
                                          DateTime(now.year, now.month, 0)),
                                      'This year' =>
                                        ArchiveRange(DateTime(now.year), now),
                                      _ => const ArchiveRange(null, null)
                                    };
                                  }))
                      ]),
                      const SizedBox(height: 24),
                      Text('OR PICK DATES', style: t.textTheme.labelSmall),
                      const SizedBox(height: 8),
                      Row(children: [
                        for (final isStart in [true, false])
                          Expanded(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.all(12)),
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                            context: context,
                                            initialDate: (isStart
                                                    ? range.start
                                                    : range.end) ??
                                                now,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100));
                                        if (date != null && mounted) {
                                          setState(() {
                                            selected = null;
                                            range = isStart
                                                ? ArchiveRange(
                                                    date,
                                                    range.end != null &&
                                                            date.isAfter(
                                                                range.end!)
                                                        ? date
                                                        : range.end)
                                                : ArchiveRange(
                                                    range.start != null &&
                                                            date.isBefore(
                                                                range.start!)
                                                        ? date
                                                        : range.start,
                                                    date);
                                          });
                                        }
                                      },
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(isStart ? 'From' : 'To',
                                                style: t.textTheme.labelSmall),
                                            Text((isStart
                                                        ? range.start
                                                        : range.end) ==
                                                    null
                                                ? 'Any date'
                                                : DateFormat.yMMMd().format(
                                                    (isStart
                                                        ? range.start
                                                        : range.end)!))
                                          ]))))
                      ]),
                      const SizedBox(height: 16),
                      Text('$count memories in this range',
                          style: t.textTheme.bodySmall),
                      const SizedBox(height: 16),
                      Row(children: [
                        TextButton(
                            onPressed: () => Navigator.pop(
                                context, const ArchiveRange(null, null)),
                            child: const Text('Clear')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: FilledButton(
                                onPressed: () => Navigator.pop(context, range),
                                child: Text('Show $count memories')))
                      ])
                    ]))));
  }
}
