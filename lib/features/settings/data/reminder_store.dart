import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderPreferences {
  const ReminderPreferences(
      {this.morning = false,
      this.evening = true,
      this.schedule = true,
      this.nudge = false,
      this.streak = false,
      this.sunday = false,
      this.quietStart = 22 * 60,
      this.quietEnd = 7 * 60});
  final bool morning, evening, schedule, nudge, streak, sunday;
  final int quietStart, quietEnd;
  Map<String, dynamic> toMap() => {
        'morning': morning,
        'evening': evening,
        'schedule': schedule,
        'nudge': nudge,
        'streak': streak,
        'sunday': sunday,
        'quietStart': quietStart,
        'quietEnd': quietEnd
      };
  factory ReminderPreferences.fromMap(Map<String, dynamic> m) =>
      ReminderPreferences(
          morning: m['morning'] == true,
          evening: m['evening'] != false,
          schedule: m['schedule'] != false,
          nudge: m['nudge'] == true,
          streak: m['streak'] == true,
          sunday: m['sunday'] == true,
          quietStart: (m['quietStart'] as int?) ?? 1320,
          quietEnd: (m['quietEnd'] as int?) ?? 420);
  ReminderPreferences withValue(String key, Object value) =>
      ReminderPreferences.fromMap({...toMap(), key: value});
}

abstract interface class ReminderStore {
  Future<void> save(ReminderPreferences p);
}

class PreferencesReminderStore implements ReminderStore {
  PreferencesReminderStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'reminders.v1';
  Future<ReminderPreferences> load() async {
    try {
      final raw = await preferences.getString(key);
      return raw == null
          ? const ReminderPreferences()
          : ReminderPreferences.fromMap(
              jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ReminderPreferences();
    }
  }

  @override
  Future<void> save(ReminderPreferences p) =>
      preferences.setString(key, jsonEncode(p.toMap()));
}

class MemoryReminderStore implements ReminderStore {
  ReminderPreferences value = const ReminderPreferences();
  @override
  Future<void> save(ReminderPreferences p) async {
    value = p;
  }
}

final reminderStoreProvider =
    Provider<ReminderStore>((ref) => MemoryReminderStore());
final initialReminderProvider =
    Provider<ReminderPreferences>((ref) => const ReminderPreferences());
final remindersProvider =
    StateNotifierProvider<ReminderController, ReminderPreferences>((ref) =>
        ReminderController(ref.watch(reminderStoreProvider),
            ref.watch(initialReminderProvider)));

class ReminderController extends StateNotifier<ReminderPreferences> {
  ReminderController(this.store, super.state);
  final ReminderStore store;
  Future<void> pending = Future.value();
  Future<bool> update(String key, Object value) async {
    final next = state.withValue(key, value);
    state = next;
    final write = pending.then((_) => store.save(next));
    pending = write.catchError((Object _) {});
    try {
      await write;
      return true;
    } catch (_) {
      return false;
    }
  }
}
