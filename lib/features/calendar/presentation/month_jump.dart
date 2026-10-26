import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showMonthJump(
        BuildContext context, DateTime selected, VoidCallback onToday) =>
    showModalBottomSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MonthJump(selected: selected, onToday: onToday));

class _MonthJump extends StatefulWidget {
  const _MonthJump({required this.selected, required this.onToday});
  final VoidCallback onToday;
  final DateTime selected;
  @override
  State<_MonthJump> createState() => _MonthJumpState();
}

class _MonthJumpState extends State<_MonthJump> {
  late int year = widget.selected.year;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
        child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(
                        child: Text('Jump to a month',
                            style: t.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800))),
                    IconButton(
                        tooltip: 'Previous year',
                        onPressed:
                            year > 2000 ? () => setState(() => year--) : null,
                        icon: const Icon(Icons.chevron_left)),
                    Text('$year'),
                    IconButton(
                        tooltip: 'Next year',
                        onPressed:
                            year < 2100 ? () => setState(() => year++) : null,
                        icon: const Icon(Icons.chevron_right))
                  ]),
                  GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.25,
                      children: [
                        for (var m = 1; m <= 12; m++)
                          FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor:
                                      year == widget.selected.year &&
                                              m == widget.selected.month
                                          ? t.colorScheme.primary
                                          : t.colorScheme.surfaceContainerLow,
                                  foregroundColor:
                                      year == widget.selected.year &&
                                              m == widget.selected.month
                                          ? t.colorScheme.onPrimary
                                          : t.colorScheme.onSurface),
                              onPressed: () =>
                                  Navigator.pop(context, DateTime(year, m)),
                              child: Text(
                                  DateFormat.MMM().format(DateTime(year, m))))
                      ]),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onToday();
                          },
                          child: const Text('Go to today')))
                ]))));
  }
}
