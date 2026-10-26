/// Date-only calendar arithmetic: no UTC conversion or 24-hour DST assumptions.
class CalendarMonth {
  CalendarMonth(int year, int month) : first = DateTime(year, month);
  final DateTime first;
  static DateTime shift(DateTime date, int offset) {
    final target = DateTime(date.year, date.month + offset);
    final last = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
        target.year, target.month, date.day > last ? last : date.day);
  }

  int get days => DateTime(first.year, first.month + 1, 0).day;
  int leadingDays(int firstDayOfWeek) =>
      (first.weekday % 7 - firstDayOfWeek + 7) % 7;
  List<DateTime?> cells(int firstDayOfWeek) {
    final leading = leadingDays(firstDayOfWeek);
    final total = ((leading + days) / 7).ceil() * 7;
    return List.generate(total, (index) {
      final day = index - leading + 1;
      return day < 1 || day > days
          ? null
          : DateTime(first.year, first.month, day);
    });
  }
}
