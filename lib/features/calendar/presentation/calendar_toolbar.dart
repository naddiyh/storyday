import 'month_jump.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Month controls followed by the PDF's left-aligned filter row.
/// Wrap rather than clip when text or the viewport needs more space.
class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar(
      {super.key,
      required this.selected,
      required this.filter,
      required this.onToday,
      required this.onPrevious,
      required this.onNext,
      required this.onFilter,
      required this.onMonth});
  final DateTime selected;
  final String filter;
  final VoidCallback onToday, onPrevious, onNext;
  final ValueChanged<String> onFilter;
  final ValueChanged<DateTime> onMonth;

  Future<void> jump(BuildContext context) async {
    final date = await showMonthJump(context, selected, onToday);
    if (date != null) {
      onMonth(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
                key: const Key('month-jump-button'),
                container: true,
                label: 'Jump to a month',
                button: true,
                excludeSemantics: true,
                onTap: () => jump(context),
                child: InkWell(
                    onTap: () => jump(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        constraints: BoxConstraints(
                            maxWidth: (MediaQuery.sizeOf(context).width - 80)
                                .clamp(120, 500)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(
                              child: Text(DateFormat.yMMMM().format(selected),
                                  key: const Key('calendar-month'),
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800))),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 18)
                        ])))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  tooltip: 'Previous month',
                  onPressed: onPrevious,
                  style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.chevron_left, size: 20)),
              IconButton(
                  tooltip: 'Next month',
                  onPressed: onNext,
                  style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.chevron_right, size: 20)),
            ]),
          ]),
      const SizedBox(height: 6),
      Wrap(
          key: const Key('calendar-filters'),
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final value in ['All', 'Journal', 'Lists', 'Schedule'])
              Semantics(
                selected: filter == value,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    foregroundColor: filter == value
                        ? theme.colorScheme.surface
                        : theme.colorScheme.onSurface,
                    textStyle: theme.textTheme.labelSmall
                        ?.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => onFilter(value),
                  child: Ink(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    decoration: BoxDecoration(
                      color: filter == value
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(value),
                  ),
                ),
              ),
          ]),
      const SizedBox(height: 4),
    ]);
  }
}
