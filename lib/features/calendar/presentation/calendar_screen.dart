import '../../settings/data/profile_store.dart';
import '../../planner/domain/focus_controller.dart';
import '../../../core/widgets/scrapbook.dart';
import 'package:go_router/go_router.dart';
import '../../../app/create_navigation.dart';
import 'calendar_toolbar.dart';
import 'selected_day_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../memories/demo_memories.dart';
import '../../themes/data/appearance_store.dart';
import '../data/demo_calendar.dart';
import '../domain/calendar_month.dart';
import '../domain/day_activity.dart';
import 'calendar_grid.dart';
import 'calendar_icons.dart';

final calendarFilterProvider = StateProvider<String>((ref) => 'All');

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = DateUtils.dateOnly(ref.watch(selectedDateProvider));
    final today = DateUtils.dateOnly(ref.watch(calendarClockProvider)());
    final activities = ref.watch(calendarActivityProvider);
    final filter = ref.watch(calendarFilterProvider);
    bool matches(CalendarEntry entry) => switch (filter) {
          'Journal' => !entry.checklist && !entry.scheduled,
          'Lists' => entry.checklist,
          'Schedule' => entry.scheduled,
          _ => true,
        };
    final filteredActivities = activities.map((date, activity) => MapEntry(
        date,
        DayActivity(
            decoration: activity.decoration,
            entries: activity.entries.where(matches).toList())));
    final activity = filteredActivities[selected] ?? const DayActivity();
    final focus = ref.watch(focusProvider);
    final overrides = ref.watch(decorationOverridesProvider);
    final appearance = ref.watch(appearanceProvider);
    final theme = Theme.of(context);
    void select(DateTime date) =>
        ref.read(selectedDateProvider.notifier).state = date;
    void create() => openCreatePage(context);
    final decoration = overrides.containsKey(selected)
        ? overrides[selected]
        : activity.decoration;
    return SingleChildScrollView(
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          MediaQuery.sizeOf(context).width < 360 ? 12 : 20,
                      vertical: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScrapbookHeader(
                            title:
                                'Good morning,\n${ref.watch(profileProvider).name}',
                            subtitle:
                                '${activities[today]?.entries.length ?? 0} things today. Pelan-pelan, you got this.'),
                        if (focus != null && !focus.saved) ...[
                          ScrapbookPanel(
                              child: ActivityTile(
                                  icon: Icons.timer_outlined,
                                  title: 'Your focus session',
                                  subtitle:
                                      '${focus.task} - ${focus.clockLabel}',
                                  onTap: () => context.push('/focus'))),
                          const SizedBox(height: 12),
                        ],
                        ScrapbookPanel(
                            child: Column(children: [
                          CalendarToolbar(
                              selected: selected,
                              filter: filter,
                              onToday: () => select(today),
                              onMonth: select,
                              onPrevious: () =>
                                  select(CalendarMonth.shift(selected, -1)),
                              onNext: () =>
                                  select(CalendarMonth.shift(selected, 1)),
                              onFilter: (value) => ref
                                  .read(calendarFilterProvider.notifier)
                                  .state = value),
                          CalendarGrid(
                              selected: selected,
                              today: today,
                              activities: filteredActivities,
                              decorations: overrides,
                              showDecorations: appearance.decorated,
                              onSelect: select),
                        ])),
                        const SizedBox(height: 12),
                        SelectedDayPanel(
                            date: selected, today: today, activity: activity),
                        const SizedBox(height: 16),
                        TextButton.icon(
                            onPressed: create,
                            icon: const Icon(Icons.add),
                            label: const Text('Create for this day')),
                        const SizedBox(height: 20),
                        Text('Decorate this day',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final choice in CalendarDecoration.values)
                            ChoiceChip(
                                avatar: CalendarSticker(decoration: choice),
                                label: Text(choice.label),
                                selected: decoration == choice,
                                onSelected: (_) => ref
                                    .read(decorationOverridesProvider.notifier)
                                    .state = {...overrides, selected: choice}),
                          ActionChip(
                              label: const Text('Clear'),
                              onPressed: () => ref
                                  .read(decorationOverridesProvider.notifier)
                                  .state = {...overrides, selected: null}),
                        ]),
                        if (!appearance.decorated)
                          const Text(
                              'Decorations are hidden. Enable them in Profile > Appearance.'),
                        const SizedBox(height: 32),
                      ]),
                ))));
  }
}
