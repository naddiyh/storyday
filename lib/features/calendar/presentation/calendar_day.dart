import 'package:flutter/material.dart';
import '../../../core/design/calendar_style.dart';
import '../domain/day_activity.dart';
import 'calendar_icons.dart';

class CalendarDay extends StatelessWidget {
  const CalendarDay(
      {super.key,
      required this.date,
      required this.activity,
      required this.selected,
      required this.today,
      required this.onTap,
      this.decoration});
  final DateTime date;
  final DayActivity activity;
  final bool selected;
  final bool today;
  final VoidCallback onTap;
  final CalendarDecoration? decoration;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<CalendarStyle>()!;
    final colors = theme.colorScheme;
    final ink = selected ? colors.onPrimary : colors.onSurface;
    final fill = selected
        ? colors.primary
        : activity.empty
            ? Colors.transparent
            : activity.entries.any((e) => e.checklist)
                ? colors.secondaryContainer
                : activity.entries.any((e) => e.scheduled)
                    ? colors.tertiaryContainer
                    : colors.primaryContainer;
    final icons = <IconData>[
      if (activity.entries.any((e) => e.scheduled)) Icons.event_outlined,
      if (activity.entries.any((e) => !e.checklist && !e.scheduled))
        Icons.notes,
      if (activity.entries.any((e) => e.checklist)) Icons.checklist,
    ];
    final descriptions = [
      if (today) 'Today',
      if (activity.entries.isNotEmpty)
        '${activity.entries.length} ordinary entries',
      if (decoration != null) '${decoration!.label} decoration'
    ];
    return Semantics(
        label:
            '${MaterialLocalizations.of(context).formatFullDate(date)}, ${descriptions.join(', ')}',
        selected: selected,
        button: true,
        onTap: onTap,
        child: ExcludeSemantics(
            child: Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: fill,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(style.radius),
                      side: BorderSide(
                          color: selected || today
                              ? colors.primary
                              : Colors.transparent,
                          width: selected ? 2 : 1)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                      onTap: onTap,
                      child: Stack(children: [
                        if (decoration != null)
                          Positioned(
                              right: 3,
                              top: 3,
                              child: Opacity(
                                  opacity: style.decorationOpacity,
                                  child: CalendarSticker(
                                      decoration: decoration!,
                                      size: 12,
                                      color: selected
                                          ? colors.onPrimary
                                          : colors.primary))),
                        Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${date.day}',
                                      maxLines: 1,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: ink,
                                              fontSize: 12,
                                              height: 1,
                                              fontWeight: selected || today
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              decoration: today
                                                  ? TextDecoration.underline
                                                  : null))),
                              const SizedBox(height: 2),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final icon in icons.take(2))
                                      Icon(icon,
                                          size: CalendarStyle.indicatorSize,
                                          color: ink),
                                    if (icons.length > 2)
                                      const Icon(Icons.more_horiz,
                                          size: CalendarStyle.indicatorSize)
                                  ]),
                            ])),
                      ])),
                ))));
  }
}
