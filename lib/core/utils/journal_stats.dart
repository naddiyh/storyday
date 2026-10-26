/// Consecutive local calendar dates, independent of daylight-saving offsets.
int bestStreak(Iterable<DateTime> dates) {
  final days = dates
      .map((d) => DateTime.utc(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort();
  var best = 0, current = 0;
  DateTime? previous;
  for (final day in days) {
    current = previous != null && day.difference(previous).inDays == 1
        ? current + 1
        : 1;
    if (current > best) best = current;
    previous = day;
  }
  return best;
}
