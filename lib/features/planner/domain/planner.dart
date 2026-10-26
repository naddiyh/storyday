import 'package:flutter/material.dart';

enum RepeatRule { once, daily, weekends, weekly }

class Schedule {
  const Schedule(
      {required this.id,
      required this.title,
      required this.date,
      required this.startMinute,
      required this.endMinute,
      this.location = '',
      this.cost = '',
      this.notes = '',
      this.reminderMinutes = 10,
      this.repeat = RepeatRule.once,
      this.symbol = 'event'});
  final String id, title, location, notes, symbol, cost;
  final DateTime date;
  final int startMinute, endMinute;
  final int? reminderMinutes;
  final RepeatRule repeat;
  bool occursOn(DateTime day) {
    final target = DateUtils.dateOnly(day);
    final first = DateUtils.dateOnly(date);
    if (target.isBefore(first)) return false;
    return switch (repeat) {
      RepeatRule.once => target == first,
      RepeatRule.daily => true,
      RepeatRule.weekends => target.weekday >= 6,
      RepeatRule.weekly => target.weekday == first.weekday,
    };
  }

  static String timeLabel(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  String get timeRange => '${timeLabel(startMinute)} – ${timeLabel(endMinute)}';
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'start': startMinute,
        'end': endMinute,
        'location': location,
        'cost': cost,
        'notes': notes,
        'reminder': reminderMinutes,
        'repeat': repeat.name,
        'symbol': symbol
      };
  factory Schedule.fromMap(Map<String, dynamic> m) => Schedule(
      id: m['id'] as String,
      title: m['title'] as String,
      date: DateTime.parse(m['date'] as String),
      startMinute: m['start'] as int,
      endMinute: m['end'] as int,
      location: m['location'] as String? ?? '',
      cost: m['cost'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      reminderMinutes: m['reminder'] as int?,
      symbol: m['symbol'] as String? ?? 'event',
      repeat: RepeatRule.values.firstWhere((r) => r.name == m['repeat'],
          orElse: () => RepeatRule.once));
}

class FocusRecord {
  const FocusRecord(
      {required this.id,
      required this.task,
      required this.date,
      required this.elapsedSeconds,
      required this.targetMinutes});
  final String id, task;
  final DateTime date;
  final int elapsedSeconds, targetMinutes;
  static String durationLabel(int seconds) => seconds >= 3600
      ? '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m'
      : seconds >= 60
          ? '${seconds ~/ 60}m ${seconds % 60}s'
          : '${seconds}s';
  Map<String, dynamic> toMap() => {
        'id': id,
        'task': task,
        'date': date.toIso8601String(),
        'elapsed': elapsedSeconds,
        'target': targetMinutes
      };
  factory FocusRecord.fromMap(Map<String, dynamic> m) => FocusRecord(
      id: m['id'] as String,
      task: m['task'] as String,
      date: DateTime.parse(m['date'] as String),
      elapsedSeconds: m['elapsed'] as int,
      targetMinutes: m['target'] as int);
}

class PlannerData {
  const PlannerData({this.schedules = const [], this.focusRecords = const []});
  final List<Schedule> schedules;
  final List<FocusRecord> focusRecords;
  Map<String, dynamic> toMap() => {
        'schedules': schedules.map((s) => s.toMap()).toList(),
        'focus': focusRecords.map((s) => s.toMap()).toList()
      };
  factory PlannerData.fromMap(Map<String, dynamic> m) => PlannerData(
      schedules: (m['schedules'] as List<dynamic>? ?? [])
          .map((s) => Schedule.fromMap(s as Map<String, dynamic>))
          .toList(),
      focusRecords: (m['focus'] as List<dynamic>? ?? [])
          .map((s) => FocusRecord.fromMap(s as Map<String, dynamic>))
          .toList());
}
