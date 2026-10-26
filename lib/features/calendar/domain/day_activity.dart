enum CalendarDecoration { flower, star, leaf }

class CalendarEntry {
  const CalendarEntry(this.title, this.preview,
      {this.checklist = false, this.scheduleId});
  final String title, preview;
  final bool checklist;
  final String? scheduleId;
  bool get scheduled => scheduleId != null;
}

class DayActivity {
  const DayActivity({this.entries = const [], this.decoration});
  final List<CalendarEntry> entries;
  final CalendarDecoration? decoration;
  bool get empty => entries.isEmpty;
}
