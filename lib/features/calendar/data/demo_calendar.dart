import '../../planner/data/planner_store.dart';
import '../../notes/data/note_repository.dart';
import '../../memories/demo_memories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/day_activity.dart';

final calendarClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);
final calendarActivityProvider = Provider<Map<DateTime, DayActivity>>((ref) {
  final now = ref.watch(calendarClockProvider)();
  DateTime date(int day) => DateTime(now.year, now.month, day);
  final activities = <DateTime, DayActivity>{
    date(5): const DayActivity(decoration: CalendarDecoration.leaf, entries: [
      CalendarEntry(
          'A slow morning', 'Coffee, sunlight, and a little time to myself.')
    ]),
    date(8): const DayActivity(decoration: CalendarDecoration.flower),
    date(12): const DayActivity(entries: [
      CalendarEntry('Small things to do', '2 of 4 tasks complete',
          checklist: true)
    ]),
    date(22): const DayActivity(decoration: CalendarDecoration.star, entries: [
      CalendarEntry('An evening walk', 'Taking the longer way home.'),
      CalendarEntry('Tomorrow', '1 of 3 tasks complete', checklist: true)
    ]),
  };
  for (final note in ref.watch(ordinaryNotesProvider)) {
    final day = DateTime(note.date.year, note.date.month, note.date.day);
    final old = activities[day] ?? const DayActivity();
    activities[day] = DayActivity(decoration: old.decoration, entries: [
      ...old.entries,
      CalendarEntry(
          note.title,
          note.hasChecklist
              ? '${note.checklist.where((t) => t.done).length} of ${note.checklist.length} tasks complete'
              : note.body,
          checklist: note.hasChecklist)
    ]);
  }
  final selected = ref.watch(selectedDateProvider);
  final schedules = ref.watch(plannerProvider).schedules;
  for (var number = 1;
      number <= DateTime(selected.year, selected.month + 1, 0).day;
      number++) {
    final day = DateTime(selected.year, selected.month, number);
    final scheduled = schedules.where((s) => s.occursOn(day));
    if (scheduled.isEmpty) continue;
    final old = activities[day] ?? const DayActivity();
    activities[day] = DayActivity(decoration: old.decoration, entries: [
      ...old.entries,
      for (final s in scheduled)
        CalendarEntry(s.title,
            '${s.timeRange}${s.location.isEmpty ? '' : ' - ${s.location}'}',
            scheduleId: s.id)
    ]);
  }
  return activities;
});
// Session-only edits. This is UI state, not journal persistence.
final decorationOverridesProvider =
    StateProvider<Map<DateTime, CalendarDecoration?>>((ref) => {});
