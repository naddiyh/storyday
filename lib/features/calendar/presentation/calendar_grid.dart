import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../core/design/calendar_style.dart';
import '../domain/calendar_month.dart';
import '../domain/day_activity.dart';
import 'calendar_day.dart';

class CalendarGrid extends StatelessWidget {
  const CalendarGrid(
      {super.key,
      required this.selected,
      required this.today,
      required this.activities,
      required this.decorations,
      required this.showDecorations,
      required this.onSelect});
  final DateTime selected, today;
  final Map<DateTime, DayActivity> activities;
  final Map<DateTime, CalendarDecoration?> decorations;
  final bool showDecorations;
  final ValueChanged<DateTime> onSelect;
  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    final first = locale.firstDayOfWeekIndex;
    final cells = CalendarMonth(selected.year, selected.month).cells(first);
    return Column(children: [
      Row(
          children: List.generate(
              7,
              (i) => Expanded(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                              DateFormat.E().format(
                                  DateTime(2023, 1, 1 + (i + first) % 7)),
                              style:
                                  Theme.of(context).textTheme.labelMedium)))))),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: CalendarStyle.rowHeight +
                  (MediaQuery.textScalerOf(context).scale(14) - 14) * 2),
          itemBuilder: (context, i) {
            final date = cells[i];
            if (date == null) return const SizedBox.shrink();
            final activity = activities[date] ?? const DayActivity();
            return CalendarDay(
                key: ValueKey('day-${date.toIso8601String()}'),
                date: date,
                activity: activity,
                selected: DateUtils.isSameDay(date, selected),
                today: DateUtils.isSameDay(date, today),
                onTap: () => onSelect(date),
                decoration: showDecorations
                    ? (decorations.containsKey(date)
                        ? decorations[date]
                        : activity.decoration)
                    : null);
          }),
    ]);
  }
}
